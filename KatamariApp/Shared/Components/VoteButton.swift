import SwiftUI

struct VoteButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            guard !isDisabled else { return }
            HapticService.shared.impact(.medium)
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(isSelected || isDisabled ? color.opacity(0.4) : color)
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .background(
                isSelected || isDisabled
                    ? color.opacity(0.06)
                    : color.opacity(0.12)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected || isDisabled ? color.opacity(0.2) : color.opacity(0.4),
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected || isDisabled ? 0.95 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}
