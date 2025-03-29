import SwiftUI

struct CustomSeparator: View {
  var body: some View {
    VStack(spacing: 0) {
      Rectangle()
        .fill(Color("devider-top"))
        .frame(height: 1)
        .frame(maxWidth: .infinity)
      Rectangle()
        .fill(Color("devider-bottom"))
        .frame(height: 1)
        .frame(maxWidth: .infinity)
    }
  }
}
