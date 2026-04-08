import Foundation

final class WordService {
    static let shared = WordService()
    private init() {}

    // Lista curada de palavras portuguesas com 5 letras (sem acentos)
    let allWords: [String] = [
        "ABRIR", "ACIMA", "ACASO", "ADIAR", "ADORO", "AGORA", "AGUDO", "AJUDA",
        "ALGUM", "ALUNO", "AMIGO", "ANDAR", "ANTES", "AREIA", "BANCO", "BEBER",
        "BLOCO", "BRAVO", "BURRO", "CACHO", "CAMPO", "CANTO", "CARGA", "CARRO",
        "CARTA", "CAUSA", "CERTO", "CHAVE", "CINCO", "CLARO", "COBRA", "COISA",
        "CONTO", "CORPO", "CURVA", "DISCO", "DOIDO", "ENTRE", "ERRAR", "EXTRA",
        "FALAR", "FALSO", "FAVOR", "FEBRE", "FEITO", "FERRO", "FESTA", "FICAR",
        "FILHO", "FILME", "FINAL", "FIRME", "FORCA", "FORMA", "FORTE", "FRACO",
        "FUNDO", "GARFO", "GARRA", "GREVE", "GRUPO", "IDEIA", "JOGAR", "JOVEM",
        "JUNTA", "LARGO", "LAVAR", "LEITE", "LENDA", "LENTO", "LIGAR", "LIMAO",
        "LINDO", "LIVRE", "LOCAL", "LONGO", "LUCRO", "MAIOR", "MARCO", "MASSA",
        "MATAR", "MENOS", "MENTE", "MISTO", "MOLDE", "MOLHO", "MUNDO", "NERVO",
        "NOBRE", "NOITE", "NORMA", "NORTE", "NOVOS", "NUVEM", "OBRAS", "OBTER",
        "OUTRO", "PAGAR", "PAPEL", "PASTA", "PEDRA", "PERTO", "PLANO", "PODER",
        "PONTO", "PORTA", "PRAIA", "PRATO", "PRECO", "PRETO", "PROVA", "PULSO",
        "QUEDA", "RAZAO", "REINO", "RISCO", "RIVAL", "ROSTO", "SAUDE", "SENSO",
        "SORTE", "TANTO", "TARDE", "TEMPO", "TENDA", "TENDO", "TENSO", "TERNO",
        "TERRA", "TODOS", "TOMAR", "TORTO", "TOURO", "TURNO", "VALOR", "VASTO",
        "VELOZ", "VERDE", "VERSO", "VIDRO", "VIGOR", "VISTA", "VIVER", "VOCAL",
        "ALADO", "BRACO", "CALMO", "DENSO", "ENZIMA", "FIRMO", "GAROA", "HURTO",
        "IMPAR", "JACTO", "KERAS", "LAPSO", "MAGRO", "NERDS", "OSSOS", "PINGO",
        "QUERO", "RUIVO", "SALTO", "TORVA", "UMBRA", "VENTO", "XIQUE", "ZONAL",
        "ABALO", "BRISA", "CEDER", "DENSA", "ERGUE", "FUZIL", "GRATO", "HEROI",
        "IMOLE", "JUIZO", "LACRE", "MACIO", "NAIVE", "OMITE", "PRISM", "QUASE",
        "RONCO", "SULCO", "TRICE", "URGIR", "VERBO", "XADRE", "ZEROS", "APELO",
        "BUZIO", "CRIVO", "DARDO", "ESTRO", "FRETE", "GUIZO", "HIATO", "INDIO",
        "JUNTO", "LEVAR", "MAPAS", "NEXUS", "ORBES", "PEDIR", "QUILO", "RODAR",
        "SOLTO", "TRATO", "URGEM", "VELAR", "XENON", "YUCCA", "ZINCO", "ABUSO"
    ].filter { $0.count == 5 }

    func isValidWord(_ word: String) -> Bool {
        allWords.contains(word.uppercased())
    }

    /// Palavra determinística do dia (mesma para todos no mesmo dia)
    func getWordOfDay() -> String {
        let cal = Calendar.current
        let d = cal.dateComponents([.year, .month, .day], from: Date())
        let seed = ((d.year ?? 2024) - 2024) * 366 + (d.month ?? 1) * 31 + (d.day ?? 1)
        return allWords[abs(seed) % allWords.count]
    }

    func randomWord() -> String {
        allWords.randomElement() ?? "CARRO"
    }
}
