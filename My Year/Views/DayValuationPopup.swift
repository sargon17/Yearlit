import SharedModels
import SwiftUI

struct DayValuationPopup: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme
  let store = ValuationStore.shared
  let date: Date

  @State private var selectedMood: DayMood?
  @State private var noteText: String = ""
  @State private var showNoteEditor = false
  @FocusState private var isNoteFocused: Bool

  private var bounceAnimation: Animation {
    .spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.2)
  }

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter
  }()

  var formattedDate: String {
    Self.dateFormatter.string(from: date)
  }

  var body: some View {
    VStack(spacing: 0) {

      Spacer(minLength: 12)

      VStack(spacing: 30) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("How was your day?")
              .font(.system(size: 32, weight: .black, design: .monospaced))
              .foregroundStyle(.textPrimary)

            Text(formattedDate)
              .font(.system(size: 16, weight: .regular, design: .monospaced))
              .foregroundStyle(.textSecondary)
          }

          Spacer(minLength: 0)
        }
        CustomSeparator()
          .padding(.horizontal, -24)

        VStack(spacing: 20) {
          Spacer(minLength: 0)
          HStack(spacing: 12) {
            ForEach([DayMood.terrible, .bad, .neutral, .good, .excellent], id: \.self) { mood in
              let isSelected = selectedMood == mood
              Button(action: {
                selectedMood = mood
                noteText = store.getValuation(for: date)?.note ?? ""
                withAnimation(bounceAnimation) {
                  showNoteEditor = true
                }
              }) {
                Text(mood.rawValue)
                  .font(.system(size: 40))
                  .frame(width: 60, height: 60)
                  .background(
                    Circle()
                      .fill(Color(mood.color))
                      .opacity(0.2)
                  )
              }
              .opacity(showNoteEditor && !isSelected ? 0.35 : 1)
              .blur(radius: showNoteEditor && !isSelected ? 8 : 0)
            }
          }
          .offset(y: showNoteEditor ? -24 : 0)

          if showNoteEditor {
            VStack(spacing: 16) {
              HStack(spacing: 8) {
                Text("Add a note")
                  .font(.system(size: 14, design: .monospaced))
                  .foregroundStyle(Color("text-secondary"))
                Spacer()
              }

            TextEditor(text: $noteText)
              .focused($isNoteFocused)
              .layoutPriority(1)
              .frame(maxHeight: .infinity)
              .scrollContentBackground(.hidden)
              .background(Color.clear)
              .foregroundColor(.white)
              .inputStyle(radius: 6, color: .textPrimary)
            }
            .frame(maxHeight: .infinity)
            .transition(.move(edge: .bottom).combined(with: .opacity))
          }

          Spacer(minLength: 0)
          VStack(spacing: 2) {
            Button(action: {
              if showNoteEditor {
                guard let selectedMood else { return }
                store.setValuation(selectedMood, for: date, note: noteText)
                dismiss()
              } else {
                dismiss()
              }
            }) {
              HStack(spacing: 8) {
                if showNoteEditor {
                  Image(systemName: "checkmark")
                  Text("Save")
                } else {
                  Text("Skip")
                }
              }
              .frame(maxWidth: .infinity, alignment: .center)
              .fontWeight(.bold)
              .padding()
            }
            .sameLevelBorder()
            .foregroundStyle(.textSecondary)
          }
          .padding(.all, 2)
          .background(getVoidColor(colorScheme: colorScheme))
        }
        .padding(.top, 8)
        .frame(maxHeight: .infinity)
      }

      Spacer(minLength: 12)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .surfaceBackground(Color("surface-muted"))
    .presentationDetents([.height(420)])
    .presentationBackground(Color("surface-muted"))
    .animation(bounceAnimation, value: showNoteEditor)
    .onChange(of: showNoteEditor) { _, isVisible in
      if isVisible {
        isNoteFocused = true
      }
    }
  }
}

#Preview {
  DayValuationPopup(date: Date())
}
