import SwiftUI
import SharedModels

struct DayValuationPopup: View {
    @Environment(\.dismiss) private var dismiss
    let store = ValuationStore.shared
    let date: Date
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text("How was your day?")
                .font(.title)
                .fontWeight(.bold)
            
            Text(formattedDate)
                .font(.title2)
                .foregroundStyle(Color("text-primary"))
            
            HStack(spacing: 12) {
                ForEach([DayMood.terrible, .bad, .neutral, .good, .excellent], id: \.self) { mood in
                    Button(action: {
                        store.setValuation(mood, for: date)
                        dismiss()
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
                }
            }
            .padding(.top, 20)
            
            Button("Skip", role: .cancel) {
                dismiss()
            }
            .padding(.top)
        }
        .padding(24)
        .presentationDetents([.height(320)])
        .presentationBackground(Color("surface-muted"))
    }
}

#Preview {
    DayValuationPopup(date: Date())
} 
