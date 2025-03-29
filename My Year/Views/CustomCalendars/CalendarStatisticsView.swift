import SwiftUI

struct CalendarStats {
  public let activeDays: Int
  public let totalCount: Int
  public let maxCount: Int
  public let longestStreak: Int
  public let currentStreak: Int
}

struct CalendarStatisticsView: View {
  let stats: CalendarStats
  let accentColor: Color

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 16) {
        CustomSeparator()
        HStack {
          Text("Statistics")
            .font(.system(size: 36, design: .monospaced))
            .foregroundColor(Color("text-primary"))
            .fontWeight(.black)
            .padding(.horizontal)

          Spacer()
        }
        CustomSeparator()
      }
      StatisticItem(title: "Active Days", value: "\(stats.activeDays)", accentColor: accentColor)
      StatisticItem(title: "Total Times Logged", value: "\(stats.totalCount)", accentColor: accentColor)
      StatisticItem(title: "Max Times Logged in a Day", value: "\(stats.maxCount)", accentColor: accentColor)
      StatisticItem(title: "Longest Days in a Row", value: "\(stats.longestStreak)", accentColor: accentColor)
      StatisticItem(title: "Current Days in a Row", value: "\(stats.currentStreak)", accentColor: accentColor)
    }.padding(.bottom)
  }
}

struct StatisticItem: View {
  let title: String
  let value: String
  let accentColor: Color

  var body: some View {
    VStack(spacing: 0) {
        HStack(alignment: .center) {
          Text(title)
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(Color("text-tertiary"))

          Spacer()
          Text(value)
            .font(.system(size: 64, design: .monospaced))
            .foregroundColor(Color(accentColor))
            .fontWeight(.black)
            .padding(.bottom, -20)
        }
        .clipped()
        .padding(0)
        .padding(.horizontal)
        .overlay(
          VStack {
            Spacer()
            CustomSeparator()
          }
        ).frame(maxWidth: .infinity)
      }
  }
}

// HStack {
//           VStack {
//             VStack(alignment: .center, spacing: 4) {
//               Text("Days")
//                 .font(.system(size: 10))
//                 .foregroundColor(Color("text-tertiary"))

//               VStack(alignment: .center) {
//                 Text("\(stats.activeDays)")
//                   .font(.system(size: 18))
//                   .foregroundColor(Color("text-secondary"))
//                   .fontWeight(.black)

//                 Text("Active")
//                   .font(.system(size: 10))
//                   .foregroundColor(Color("text-tertiary").opacity(0.5))

//               }
//             }.padding(10)
//           }
//           .frame(maxWidth: .infinity)
//           .background(Color("surface-secondary").opacity(0.5))
//           .cornerRadius(10)

//           Spacer()

//           if calendar.trackingType != .binary {

//             VStack {
//               VStack(alignment: .center, spacing: 4) {
//                 Text("Count")
//                   .font(.system(size: 10))
//                   .foregroundColor(Color("text-tertiary"))

//                 HStack {
//                   VStack(alignment: .center) {
//                     Text("\(stats.totalCount)")
//                       .font(.system(size: 18))
//                       .foregroundColor(Color("text-secondary"))
//                       .fontWeight(.black)

//                     Text("Total")
//                       .font(.system(size: 10))
//                       .foregroundColor(Color("text-tertiary").opacity(0.5))
//                   }.frame(maxWidth: .infinity)

//                   VStack(alignment: .center) {
//                     Text("\(stats.maxCount)")
//                       .font(.system(size: 18))
//                       .foregroundColor(Color("text-secondary"))
//                       .fontWeight(.black)

//                     Text("Max")
//                       .font(.system(size: 10))
//                       .foregroundColor(Color("text-tertiary").opacity(0.5))
//                   }.frame(maxWidth: .infinity)

//                 }
//               }
//               .padding(10)
//             }
//             .frame(maxWidth: .infinity)
//             .background(Color("surface-secondary").opacity(0.5))
//             .cornerRadius(10)
//           }

//           VStack {
//             VStack(alignment: .center, spacing: 4) {
//               Text("Streaks")
//                 .font(.system(size: 10))
//                 .foregroundColor(Color("text-tertiary"))

//               HStack {
//                 VStack(alignment: .center) {
//                   Text("\(stats.currentStreak)")
//                     .font(.system(size: 18))
//                     .foregroundColor(Color("text-primary"))
//                     .fontWeight(.black)

//                   Text("Current")
//                     .font(.system(size: 10))
//                     .foregroundColor(Color("text-tertiary").opacity(0.5))
//                 }.frame(maxWidth: .infinity)

//                 VStack(alignment: .center) {
//                   Text("\(stats.longestStreak)")
//                     .font(.system(size: 18))
//                     .foregroundColor(Color("text-secondary"))
//                     .fontWeight(.black)

//                   Text("Longest")
//                     .font(.system(size: 10))
//                     .foregroundColor(Color("text-tertiary").opacity(0.5))
//                 }.frame(maxWidth: .infinity)

//               }
//             }
//             .padding(10)
//           }
//           .frame(maxWidth: .infinity)
//           .background(Color("surface-secondary").opacity(0.5))
//           .cornerRadius(10)
//         }
//         .padding(.horizontal)