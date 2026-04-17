import SwiftUI

struct KatamariButton: View {
    let title: String
    let icon: String?
    let style: Style
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    enum Style {
        case primary, secondary, accent, destructive

        var backgroundColor: Color {
            switch self {
            case .primary:     return KatamariTheme.Colors.primary
            case .secondary:   return KatamariTheme.Colors.cardBackground
            case .accent:      return KatamariTheme.Colors.accent
            case .destructive: return .red
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary:     return .white
            case .secondary:   return KatamariTheme.Colors.label
            case .accent:      return .white
            case .destructive: return .white
            }
        }

        var hasBorder: Bool { self == .secondary }
    }

    init(title: String, icon: String? = nil, style: Style = .primary,
         isLoading: Bool = false, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button {
            guard !isDisabled && !isLoading else { return }
            action()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(style.foregroundColor)
                        .scaleEffect(0.85)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(style.foregroundColor.opacity(isDisabled ? 0.5 : 1))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(style.backgroundColor.opacity(isDisabled ? 0.4 : 1))
            .cornerRadius(KatamariTheme.CornerRadius.md)
            .overlay {
                if style.hasBorder {
                    RoundedRectangle(cornerRadius: KatamariTheme.CornerRadius.md)
                        .stroke(KatamariTheme.Colors.separator, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
    }
}
