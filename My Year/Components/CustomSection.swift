import SwiftUI

struct CustomSection<Content: View>: View {
    let content: () -> Content
    let label: LocalizedStringKey

    init(label: LocalizedStringKey = "", @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .labelStyle(type: .tertiary)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
