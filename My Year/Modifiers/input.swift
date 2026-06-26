import SwiftUI

enum InputSize {
    case small
    ///   case medium
    case large
}

struct InputModifier: ViewModifier {
    let size: InputSize
    let radius: CGFloat
    let color: Color

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .foregroundColor(color)
            .font(AppFont.mono(fontSize, weight: .regular))
            .lcdScreenEffect(
                clipShape: RoundedRectangle(cornerRadius: radius),
                diffusion: 0.1,
                dotOpacity: 0.28
            )
            .sameLevelBorder(radius: radius, color: .black)
            .outerSameLevelShadow(radius: radius)
    }

    var padding: CGFloat {
        switch size {
        case .small:
            return 8
        case .large:
            return 12
        }
    }

    var fontSize: CGFloat {
        switch size {
        case .small:
            return 12
        case .large:
            return 16
        }
    }
}

extension View {
    func inputStyle(size: InputSize = .large, radius: CGFloat = 6, color: Color = .orange) -> some View {
        modifier(InputModifier(size: size, radius: radius, color: color))
    }
}
