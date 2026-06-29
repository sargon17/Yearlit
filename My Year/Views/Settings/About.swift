import Combine
import SwiftUI
import SwiftfulRouting

struct AboutThisProject: View {
  @Environment(\.router) var router
  @State private var phase: AboutPhases = .presentation
  @State private var elapsedTime = 0.0
  @State private var isPaused = false

  let timeToNext = 15.0  // seconds
  let timer = Timer.publish(every: 0.1, on: .main, in: .common)
  @State private var timerConnection: Cancellable?

  var body: some View {
    GeometryReader { proxy in
      let midX = proxy.size.width / 2

      ZStack {
        HStack {
          ForEach(AboutPhases.allCases) { p in
            let elapsed = p == phase ? elapsedTime : p > phase ? 0 : timeToNext

            ElapsedIndicator(timeToNext, elapsed)
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
      .onDisappear {
        timerConnection?.cancel()
        timerConnection = nil
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
      .onLongPressGesture(minimumDuration: 1) {
      } onPressingChanged: { isPressing in
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
      timerConnection?.cancel()  // stop timer
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
