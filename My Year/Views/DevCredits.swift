import SwiftUI

struct DevCredits: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("Independently engineered. Lovingly crafted.")
            Text("Thank you for your support!")

            Spacer().frame(height: 10) // Add some space before the name
            HStack(spacing: 4) {
                Text("Mykhaylo Tymofyeyev")
                Text("•")
                Text("[tymofyeyev.com](https://tymofyeyev.com)").foregroundColor(.blue)
            }
            .foregroundColor(Color("text-tertiary"))
        }
        .font(.system(size: 9, design: .monospaced))
        .foregroundColor(Color("text-tertiary").opacity(0.5))
        .multilineTextAlignment(.center)
    }
}
