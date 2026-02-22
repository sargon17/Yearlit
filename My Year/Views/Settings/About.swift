import Combine
import SwiftfulRouting
import SwiftUI

struct About: View {
    @Environment(\.router) var router
    @EnvironmentObject private var whatsNewManager: WhatsNewManager

    var body: some View {
        Section(header: Text("About")) {
            Button("My Note to You") {
                router.showScreen(.fullScreenCover) { _ in
                    AboutThisProject()
                }
            }

            let latestVersion = whatsNewManager.latestRelease()?.version
            let whatsNewLabel = latestVersion == nil ? "What's New" : "What's New (\(latestVersion!))"
            Button(whatsNewLabel) {
                guard let release = whatsNewManager.latestRelease() else { return }
                router.showScreen(.sheet) { _ in
                    WhatsNewSheetView(release: release) {
                        whatsNewManager.markSeen(release)
                        router.dismissScreen()
                    }
                    .presentationDetents([.fraction(0.92)])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }
}

enum AboutPhases: CaseIterable, Identifiable, Comparable {
    case presentation
    case yearlit
    case feedback

    var id: Self {
        self
    }
}

struct AboutThisProject: View {
    @Environment(\.router) var router
    @State private var phase: AboutPhases = .presentation
    @State private var elapsedTime = 0.0
    @State private var isPaused = false

    let timeToNext = 15.0 // seconds
    let timer = Timer.publish(every: 0.1, on: .main, in: .common)
    @State private var timerConnection: Cancellable?

    var body: some View {
        GeometryReader { proxy in
            let midX = proxy.size.width / 2

            ZStack {
                HStack {
                    ForEach(AboutPhases.allCases) { p in
                        let elapsed = p == phase ? elapsedTime : p > phase ? 0 : timeToNext

                        elapsedIndicator(timeToNext, elapsed)
                    }
                }
                switch phase {
                case .presentation:
                    Presentation()
                case .yearlit:
                    Yearlit()
                case .feedback:
                    Feedback()
                }
            }
            .padding()
            .background(.surfaceMuted)
            .onAppear {
                if timerConnection == nil {
                    timerConnection = timer.connect()
                }
            }
            .onReceive(timer) { _ in
                if isPaused { return }
                withAnimation(.bouncy()) {
                    elapsedTime += 0.1
                    if elapsedTime >= timeToNext {
                        moveToNextPhase()
                    }
                }
            }
            .onLongPressGesture(minimumDuration: 1) {} onPressingChanged: { isPressing in
                if isPressing {
                    isPaused = true
                } else {
                    isPaused = false
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let x = value.location.x
                        if x > midX {
                            moveToNextPhase()
                        } else if canGoToPreviousPhase() {
                            moveToPreviousPhase()
                        }
                    }
            )
        }
    }

    func moveToNextPhase() {
        elapsedTime = 0
        switch phase {
        case .presentation:
            phase = .yearlit
        case .yearlit:
            phase = .feedback
        case .feedback:
            timerConnection?.cancel() // stop timer
            router.dismissScreen()
        }
    }

    func canGoToPreviousPhase() -> Bool {
        return phase != .presentation
    }

    func moveToPreviousPhase() {
        elapsedTime = 0
        switch phase {
        case .feedback:
            phase = .yearlit
        case .yearlit:
            phase = .presentation
        case .presentation:
            break
        }
    }
}

struct elapsedIndicator: View {
    let totalTime: Double
    let elapsedTime: Double

    init(_ totalTime: Double, _ elapsedTime: Double) {
        self.totalTime = totalTime
        self.elapsedTime = elapsedTime
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let elapsedWidth = CGFloat((Double(width) / totalTime) * elapsedTime)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: 4)
                    .foregroundStyle(.textTertiary.opacity(0.2))

                RoundedRectangle(cornerRadius: 4)
                    .frame(maxWidth: elapsedWidth, maxHeight: 4)
                    .foregroundStyle(.surfacePrimary)
            }
            .frame(maxHeight: 4)
        }
    }
}

extension AboutThisProject {
    struct Presentation: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 32) {
                Text("Hi, I’m Mykhaylo.")
                    .foregroundStyle(.textPrimary)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                Text(
                    "I’m the person behind Yearlit — designer, builder, and fellow struggler when it comes to staying consistent."
                )
                .italic()
                Text("I didn’t create this app because I mastered the problem.")
                    .fontWeight(.semibold)
                Text("I created it because I ")
                    + Text("needed")
                    .italic().foregroundStyle(.orange).fontWeight(.bold)
                    + Text(" it")
            }
            .multilineTextAlignment(.leading)
            .font(.system(size: 14, design: .monospaced))
            .foregroundStyle(.textSecondary)
            .lineSpacing(4)
        }
    }

    struct Yearlit: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 18) {
                Text("Why I’m Building Yearlit")
                    .foregroundStyle(.textPrimary)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                Text("I’ve always believed consistency is a kind of superpower.")
                    .fontWeight(.semibold)
                Text("It’s the quiet force that turns small, ordinary actions into extraordinary results over time.")
                    .italic()
                Text("The truth? I’ve never been naturally consistent.")
                    .fontWeight(.semibold)
                Text("I’d start things with energy and optimism… only to fade when the spark wore off.")
                Text("And every time, I’d wonder, “Why can’t I stick with this?”")
                Text(
                    "Yearlit began as my own solution — a way to "
                )
                    + Text("help myself")
                    .italic().foregroundStyle(.orange).fontWeight(.bold)
                    + Text(" show up every day, even when motivation wasn’t there.")
                Text("And along the way, I realized I wasn’t the only one who needed this.")
                Text("It’s for anyone who’s ever wanted to follow through, but found it hard to keep going.")
            }
            .multilineTextAlignment(.leading)
            .font(.system(size: 14, design: .monospaced))
            .foregroundStyle(.textSecondary)
            .lineSpacing(4)
        }
    }

    struct Feedback: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 18) {
                Text("A Work in Progress")
                    .foregroundStyle(.textPrimary)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                Text("Yearlit is still growing — just like the people who use it.")
                    .italic()
                Text("It’s not perfect, and I’m okay with that.")
                    .fontWeight(.bold)
                Text("Because every update, every improvement, comes from ")
                    + Text("real feedback")
                    .italic().foregroundStyle(.orange).fontWeight(.bold)
                    + Text(" from people actually using it.")
                Text(
                    "My goal is to make Yearlit the most useful tool out there for building consistency — but I can’t do that alone."
                )
                Text("Your suggestions and ideas are what shape it.")
                Text("So if something’s missing, or something could work better, let me know.")
                Text("We’ll make this better together — one step, one habit, one consistent day at a time.")
                    .italic()
            }
            .multilineTextAlignment(.leading)
            .font(.system(size: 14, design: .monospaced))
            .foregroundStyle(.textSecondary)
            .lineSpacing(4)
        }
    }
}
