import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// ─────────────────────────────────────────────────────────────
// startGame — assigns words to each player and transitions room
// ─────────────────────────────────────────────────────────────
export const startGame = functions.https.onCall(async (data, context) => {
  const { roomId, hostId } = data as { roomId: string; hostId: string };
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Login required");

  const roomRef = db.collection("rooms").document(roomId);
  const roomSnap = await roomRef.get();
  if (!roomSnap.exists) throw new functions.https.HttpsError("not-found", "Room not found");

  const room = roomSnap.data()!;
  if (room.hostId !== hostId) {
    throw new functions.https.HttpsError("permission-denied", "Only the host can start the game");
  }
  if (room.players.length < 2) {
    throw new functions.https.HttpsError("failed-precondition", "Need at least 2 players");
  }

  // Fetch words for the category
  const wordsSnap = await db.collection("words")
    .where("category", "==", room.category === "all" ? null : room.category)
    .limit(room.players.length * 3)
    .get();

  const allWords = wordsSnap.docs.map(d => d.data().text as string);
  const shuffled = allWords.sort(() => Math.random() - 0.5);

  // Assign one word per player
  const players = room.players.map((p: any, i: number) => ({
    ...p,
    word: shuffled[i % shuffled.length] ?? "Desconhecido",
    hasGuessed: false,
    guessOrder: null,
    roundScore: 0,
  }));

  // Create initial game state
  const gameState = {
    roomId,
    currentRound: 1,
    currentPlayerIndex: 0,
    currentQuestion: null,
    roundStatus: "asking",
    guessCount: 0,
    totalPlayers: players.length,
    voteYes: 0,
    voteNo: 0,
    votes: {},
    finishedPlayerIds: [],
  };

  const batch = db.batch();
  batch.update(roomRef, { status: "playing", players });
  batch.set(db.collection("rooms").document(roomId).collection("game").document("state"), gameState);
  await batch.commit();

  // Send push notifications
  const tokens = players
    .map((p: any) => p.fcmToken)
    .filter(Boolean);
  if (tokens.length) {
    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "Quem Sou Eu? — Jogo Iniciado! 🎮",
        body: "A partida começou. Descubra quem você é!",
      },
    });
  }

  return { success: true };
});

// ─────────────────────────────────────────────────────────────
// submitQuestion — stores the question and advances to voting
// ─────────────────────────────────────────────────────────────
export const submitQuestion = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Login required");
  const { roomId, playerId, question } = data as {
    roomId: string; playerId: string; question: string;
  };

  const stateRef = db.collection("rooms").document(roomId).collection("game").document("state");
  const stateSnap = await stateRef.get();
  const state = stateSnap.data()!;

  const roomSnap = await db.collection("rooms").document(roomId).get();
  const room = roomSnap.data()!;
  const askingIdx = state.currentPlayerIndex % room.players.length;
  const askingPlayer = room.players[askingIdx];

  if (askingPlayer.id !== playerId) {
    throw new functions.https.HttpsError("permission-denied", "Not your turn");
  }

  const roundRef = db.collection("rooms").document(roomId).collection("rounds").doc();
  const batch = db.batch();

  batch.set(roundRef, {
    id: roundRef.id,
    roundNumber: state.currentRound,
    askingPlayerId: playerId,
    question,
    votes: {},
    result: null,
    type: "question",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  batch.update(stateRef, {
    currentQuestion: question,
    roundStatus: "voting",
    voteYes: 0,
    voteNo: 0,
    votes: {},
  });

  await batch.commit();

  // Notify other players
  const otherTokens = room.players
    .filter((p: any) => p.id !== playerId && p.fcmToken)
    .map((p: any) => p.fcmToken);
  if (otherTokens.length) {
    await admin.messaging().sendEachForMulticast({
      tokens: otherTokens,
      notification: {
        title: `${askingPlayer.displayName} perguntou:`,
        body: `"${question}"`,
      },
    });
  }

  return { success: true };
});

// ─────────────────────────────────────────────────────────────
// submitVote — records vote and advances if majority reached
// ─────────────────────────────────────────────────────────────
export const submitVote = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Login required");
  const { roomId, playerId, vote } = data as {
    roomId: string; playerId: string; vote: "Sim" | "Não";
  };

  const stateRef = db.collection("rooms").document(roomId).collection("game").document("state");

  await db.runTransaction(async (tx) => {
    const stateSnap = await tx.get(stateRef);
    const state = stateSnap.data()!;

    if (state.roundStatus !== "voting") {
      throw new functions.https.HttpsError("failed-precondition", "Not in voting phase");
    }
    if (state.votes[playerId]) return; // already voted

    const votes = { ...state.votes, [playerId]: vote };
    const yesCount = Object.values(votes).filter(v => v === "Sim").length;
    const noCount  = Object.values(votes).filter(v => v === "Não").length;
    const total = yesCount + noCount;
    const majority = Math.floor(state.totalPlayers / 2) + 1;

    const update: Record<string, any> = {
      votes,
      voteYes: yesCount,
      voteNo: noCount,
    };

    if (total >= majority) {
      update.roundStatus = "showingResult";
      // Auto-advance after 3 seconds (handled by client or another trigger)
    }

    tx.update(stateRef, update);
  });

  return { success: true };
});

// ─────────────────────────────────────────────────────────────
// submitGuess — validates the player's guess
// ─────────────────────────────────────────────────────────────
export const submitGuess = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Login required");
  const { roomId, playerId, guess } = data as {
    roomId: string; playerId: string; guess: string;
  };

  const roomRef = db.collection("rooms").document(roomId);
  const roomSnap = await roomRef.get();
  const room = roomSnap.data()!;

  const player = room.players.find((p: any) => p.id === playerId);
  if (!player) throw new functions.https.HttpsError("not-found", "Player not found");

  const correct = player.word.trim().toLowerCase() === guess.trim().toLowerCase();

  if (correct) {
    const alreadyGuessed = room.players.filter((p: any) => p.hasGuessed).length;
    const guessOrder = alreadyGuessed + 1;

    const updatedPlayers = room.players.map((p: any) => {
      if (p.id !== playerId) return p;
      return { ...p, hasGuessed: true, guessOrder };
    });

    const allGuessed = updatedPlayers.every((p: any) => p.hasGuessed);

    const batch = db.batch();
    batch.update(roomRef, { players: updatedPlayers });

    if (allGuessed) {
      batch.update(roomRef, { status: "finished" });
      const stateRef = db.collection("rooms").document(roomId).collection("game").document("state");
      batch.update(stateRef, { roundStatus: "finished" });
      await awardPoints(roomId, updatedPlayers);
    }

    await batch.commit();
  }

  return { correct };
});

// ─────────────────────────────────────────────────────────────
// advanceRound — moves to the next player's turn
// ─────────────────────────────────────────────────────────────
export const advanceRound = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Login required");
  const { roomId } = data as { roomId: string };

  const stateRef = db.collection("rooms").document(roomId).collection("game").document("state");
  const stateSnap = await stateRef.get();
  const state = stateSnap.data()!;

  const roomSnap = await db.collection("rooms").document(roomId).get();
  const room = roomSnap.data()!;
  const activePlayers = room.players.filter((p: any) => !p.hasGuessed);

  let nextIdx = (state.currentPlayerIndex + 1) % room.players.length;
  // Skip players who already guessed
  let attempts = 0;
  while (room.players[nextIdx]?.hasGuessed && attempts < room.players.length) {
    nextIdx = (nextIdx + 1) % room.players.length;
    attempts++;
  }

  await stateRef.update({
    currentPlayerIndex: nextIdx,
    currentRound: state.currentRound + 1,
    roundStatus: activePlayers.length > 0 ? "asking" : "finished",
    currentQuestion: null,
    voteYes: 0,
    voteNo: 0,
    votes: {},
  });

  return { success: true };
});

// ─────────────────────────────────────────────────────────────
// finishGame — ends the game and awards points
// ─────────────────────────────────────────────────────────────
export const finishGame = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Login required");
  const { roomId } = data as { roomId: string };

  const roomSnap = await db.collection("rooms").document(roomId).get();
  const room = roomSnap.data()!;

  const batch = db.batch();
  batch.update(db.collection("rooms").document(roomId), { status: "finished" });
  const stateRef = db.collection("rooms").document(roomId).collection("game").document("state");
  batch.update(stateRef, { roundStatus: "finished" });
  await batch.commit();

  await awardPoints(roomId, room.players);
  return { success: true };
});

// ─────────────────────────────────────────────────────────────
// Helper — award points based on guess order
// ─────────────────────────────────────────────────────────────
async function awardPoints(roomId: string, players: any[]) {
  const pointsMap: Record<number, number> = { 1: 100, 2: 70, 3: 50 };
  const defaultPoints = 30;

  const updatePromises = players.map((player: any) => {
    if (!player.hasGuessed) return Promise.resolve();
    const pts = pointsMap[player.guessOrder] ?? defaultPoints;
    const isWinner = player.guessOrder === 1;

    return db.collection("users").document(player.id).update({
      totalPoints: admin.firestore.FieldValue.increment(pts),
      gamesPlayed: admin.firestore.FieldValue.increment(1),
      wins: isWinner
        ? admin.firestore.FieldValue.increment(1)
        : admin.firestore.FieldValue.increment(0),
    });
  });

  const nonGuessers = players.filter((p: any) => !p.hasGuessed);
  nonGuessers.forEach((player: any) => {
    updatePromises.push(
      db.collection("users").document(player.id).update({
        gamesPlayed: admin.firestore.FieldValue.increment(1),
      })
    );
  });

  await Promise.all(updatePromises);
}
