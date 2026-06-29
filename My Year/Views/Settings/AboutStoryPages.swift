import SwiftUI

extension AboutThisProject {
  struct Presentation: View {
    var body: some View {
      VStack(alignment: .leading, spacing: 32) {
        Text("Hi, I’m Mykhaylo.")
          .foregroundStyle(.textPrimary)
          .font(AppFont.pixelCircle(24))
        Text(
          """
          I’m the person behind Yearlit — designer, builder, and fellow struggler when it comes to \
          staying consistent.
          """
        )
        .italic()
        Text("I didn’t create this app because I mastered the problem.")
          .fontWeight(.semibold)
        Text("I created it because I ")
          + Text("needed")
          .italic().foregroundStyle(.orange).fontWeight(.bold)
          + Text(" it")
      }
      .aboutStoryTextStyle()
    }
  }

  struct Yearlit: View {
    var body: some View {
      VStack(alignment: .leading, spacing: 18) {
        Text("Why I’m Building Yearlit")
          .foregroundStyle(.textPrimary)
          .font(AppFont.pixelCircle(24))
        Text("I’ve always believed consistency is a kind of superpower.")
          .fontWeight(.semibold)
        Text("It’s the quiet force that turns small, ordinary actions into extraordinary results over time.")
          .italic()
        Text("The truth? I’ve never been naturally consistent.")
          .fontWeight(.semibold)
        Text("I’d start things with energy and optimism… only to fade when the spark wore off.")
        Text("And every time, I’d wonder, “Why can’t I stick with this?”")
        Text("Yearlit began as my own solution — a way to ")
          + Text("help myself")
          .italic().foregroundStyle(.orange).fontWeight(.bold)
          + Text(" show up every day, even when motivation wasn’t there.")
        Text("And along the way, I realized I wasn’t the only one who needed this.")
        Text("It’s for anyone who’s ever wanted to follow through, but found it hard to keep going.")
      }
      .aboutStoryTextStyle()
    }
  }

  struct Feedback: View {
    var body: some View {
      VStack(alignment: .leading, spacing: 18) {
        Text("A Work in Progress")
          .foregroundStyle(.textPrimary)
          .font(AppFont.pixelCircle(24))
        Text("Yearlit is still growing — just like the people who use it.")
          .italic()
        Text("It’s not perfect, and I’m okay with that.")
          .fontWeight(.bold)
        Text("Because every update, every improvement, comes from ")
          + Text("real feedback")
          .italic().foregroundStyle(.orange).fontWeight(.bold)
          + Text(" from people actually using it.")
        Text(
          """
          My goal is to make Yearlit the most useful tool out there for building consistency — but \
          I can’t do that alone.
          """
        )
        Text("Your suggestions and ideas are what shape it.")
        Text("So if something’s missing, or something could work better, let me know.")
        Text("We’ll make this better together — one step, one habit, one consistent day at a time.")
          .italic()
      }
      .aboutStoryTextStyle()
    }
  }
}

private struct AboutStoryTextStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .multilineTextAlignment(.leading)
      .font(AppFont.mono(14))
      .foregroundStyle(.textSecondary)
      .lineSpacing(4)
  }
}

private extension View {
  func aboutStoryTextStyle() -> some View {
    modifier(AboutStoryTextStyle())
  }
}
