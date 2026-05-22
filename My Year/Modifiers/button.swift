import SwiftUI

struct ButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack {
            content
                .sameLevelBorder(color: .buttonBackground)
                .foregroundStyle(Color.buttonForeground)
        }
        .padding(2)
    }
}

extension View {
    func button() -> some View {
        modifier(ButtonModifier())
    }
}

struct ButtonLabelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .center)
            .fontWeight(.bold)
            .padding()
    }
}

extension View {
    func buttonLabel() -> some View {
        modifier(ButtonLabelModifier())
    }
}

// VStack(spacing: 2) {
//   Button(action: {
//     showingDeleteConfirmation = true
//   }) {
//     Text("Delete Calendar")
//   }
// }
