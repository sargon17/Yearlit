import Garnish
import SharedModels
import SwiftUI

@MainActor
final class OnboardingCoordinator: ObservableObject {
  @Published private(set) var currentStep: OnboardingStep
  @Published var session: OnboardingSession
  @Published private(set) var isRequestingNotifications = false

  private let onFinish: () -> Void
  private let analytics: OnboardingAnalyticsTracking
  private var firstDotCalendar: CustomCalendar?
  private var trackedOnboardingActions: Set<OnboardingAction> = []

  init(onFinish: @escaping () -> Void, analytics: OnboardingAnalyticsTracking = Analytics.shared) {
    self.onFinish = onFinish
    self.analytics = analytics
    currentStep = .emotionalHook
    session = OnboardingSession()
    trackStepView(.emotionalHook)
  }

  func continueTapped() {
    route(from: currentStep)
  }

  func identityCommitmentChanged(_ commitment: IdentityCommitment) {
    session.toggleIdentityCommitment(commitment)
    session.selectedTinyHabitName = nil
  }

  func habitSelectionChanged(_ name: String) {
    session.selectedTinyHabitName = name
  }

  func tinyHabitContinueTapped() {
    guard session.selectedTinyHabitName != nil else { return }
    createTinyHabitCalendarIfNeeded()
    trackOnboardingAction(.tinyHabitCreated)
    transition(to: .firstDot)
  }

  func firstDotMarkDayOneTapped() {
    let store = CustomCalendarStore.shared
    guard let calendar = resolvedFirstCalendar(in: store.snapshot) else { return }
    let today = Date()
    let existingEntry = store.getEntry(calendarId: calendar.id, date: today)
    guard existingEntry?.completed != true else {
      session.didCompleteFirstDot = true
      trackOnboardingAction(.firstDotMarked)
      return
    }

    let entry = CalendarEntry(date: today, count: 1, completed: true)
    store.addEntry(calendarId: calendar.id, entry: entry)
    session.didCompleteFirstDot = true
    trackOnboardingAction(.firstDotMarked)
    Task {
      await hapticFeedback(.success)
    }
  }

  func firstDotContinueTapped() {
    transition(to: .preReviewGate)
  }

  func preReviewGateAnswered(_ answer: PreReviewGateAnswer?) {
    session.preReviewGateWasPositive = answer?.isPositive == true
    transition(to: session.preReviewGateWasPositive ? .reviewRequest : .notificationPermission)
  }

  func reviewRequestAnswered() {
    session.didRequestReview = true
    trackOnboardingAction(.reviewRequested)
    addPositiveEvent(.completedOnboarding)
    transition(to: .notificationPermission)
  }

  func notificationPermissionRequested() {
    guard !isRequestingNotifications else { return }
    isRequestingNotifications = true
    requestNotificationPermissions { [weak self] _ in
      Task { @MainActor in
        guard let self else { return }
        self.session.didRequestNotifications = true
        self.isRequestingNotifications = false
        self.trackOnboardingAction(.notificationsRequested)
        self.transition(to: .readyWidgets)
      }
    }
  }

  func notificationPermissionSkipped() {
    guard !isRequestingNotifications else { return }
    session.didRequestNotifications = false
    trackOnboardingAction(.notificationsSkipped)
    transition(to: .readyWidgets)
  }

  func reviewRequestSkipped() {
    session.didRequestReview = false
    trackOnboardingAction(.reviewSkipped)
    transition(to: .notificationPermission)
  }

  func readyWidgetsCompleted() {
    trackOnboardingAction(.readyContinued)
    trackOnboardingAction(.paywallBoundaryReached)
    transition(to: .paywall)
  }

  func paywallClosed() {
    trackOnboardingAction(.paywallClosed)
    onFinish()
  }

    private func createTinyHabitCalendarIfNeeded() {
        guard session.tinyHabitCalendarId == nil else { return }
        guard let selectedHabit = session.selectedTinyHabitName else { return }

        let store = CustomCalendarStore.shared
        let activeCalendars = store.snapshot.activeCalendars
        if let existingCalendar = activeCalendars.first {
            session.tinyHabitCalendarId = existingCalendar.id
            firstDotCalendar = existingCalendar
            return
        }

        let calendar = OnboardingFirstCalendarFactory.makeCalendar(title: selectedHabit, today: Date())

        session.tinyHabitCalendarId = calendar.id
        firstDotCalendar = calendar
        store.addCalendar(calendar)
        CalendarAnalyticsTracker.shared.trackCalendarCreated(
            calendar: calendar,
            isFirstCalendar: true
        )
    }

    private func resolvedFirstCalendar(in snapshot: CustomCalendarStoreSnapshot) -> CustomCalendar? {
        if let cachedCalendar = firstDotCalendar {
            if let calendarId = session.tinyHabitCalendarId, cachedCalendar.id == calendarId {
                return cachedCalendar
            }
        }

        let activeCalendars = snapshot.activeCalendars

        if let calendarId = session.tinyHabitCalendarId,
            let calendar = activeCalendars.first(where: { $0.id == calendarId })
        {
            firstDotCalendar = calendar
            return calendar
        }

        guard let fallbackCalendar = activeCalendars.first else {
            return nil
        }

        session.tinyHabitCalendarId = fallbackCalendar.id
        firstDotCalendar = fallbackCalendar
        return fallbackCalendar
    }

    func resolvedFirstCalendarForView(in snapshot: CustomCalendarStoreSnapshot) -> CustomCalendar? {
        resolvedFirstCalendar(in: snapshot)
    }

    func isFirstDotCompletedToday(calendar: CustomCalendar?, date: Date = Date()) -> Bool {
        guard let calendar else { return false }
        return calendar.entry(for: date)?.completed == true
    }

    private func route(from step: OnboardingStep) {
        switch step {
        case .emotionalHook:
            transition(to: .appExplanation)
        case .appExplanation:
            transition(to: .identityCommitment)
        case .identityCommitment:
            guard !session.selectedIdentityCommitments.isEmpty else { return }
            trackOnboardingAction(.identityCompleted)
            transition(to: .tinyHabitSelection)
        case .tinyHabitSelection:
            tinyHabitContinueTapped()
        case .firstDot:
            break
        case .preReviewGate:
            transition(to: session.preReviewGateWasPositive ? .reviewRequest : .notificationPermission)
        case .reviewRequest:
            reviewRequestAnswered()
        case .notificationPermission:
            notificationPermissionRequested()
        case .readyWidgets:
            readyWidgetsCompleted()
        case .paywall:
            paywallClosed()
        }
    }

    private func transition(to step: OnboardingStep) {
        guard currentStep != step else { return }
        currentStep = step
        trackStepView(step)
    }

    private func trackStepView(_ step: OnboardingStep) {
        analytics.trackOnboardingStepViewed(stepId: step.rawValue)
    }

    private func trackOnboardingAction(_ action: OnboardingAction) {
        guard trackedOnboardingActions.insert(action).inserted else { return }
        analytics.trackOnboardingAction(action)
    }
}

enum OnboardingStep: String, CaseIterable, Identifiable {
    case emotionalHook
    case appExplanation
    case identityCommitment
    case tinyHabitSelection
    case firstDot
    case preReviewGate
    case reviewRequest
    case notificationPermission
    case readyWidgets
    case paywall

    var id: String { rawValue }
}

struct OnboardingSession {
    var selectedIdentityCommitments: [IdentityCommitment] = []
    var selectedTinyHabitName: String?
    var tinyHabitCalendarId: UUID?
    var didCompleteFirstDot = false
    var preReviewGateWasPositive = false
    var didRequestReview = false
    var didRequestNotifications = false

    mutating func toggleIdentityCommitment(_ commitment: IdentityCommitment) {
        if let index = selectedIdentityCommitments.firstIndex(of: commitment) {
            selectedIdentityCommitments.remove(at: index)
            return
        }

        selectedIdentityCommitments.append(commitment)
    }
}

enum PreReviewGateAnswer: String, CaseIterable, Identifiable {
    case positive
    case neutral
    case negative
    case skip

    var id: String { rawValue }

    var isPositive: Bool {
        self == .positive
    }
}

struct OnboardingView: View {
    @StateObject private var coordinator: OnboardingCoordinator

    init(onDone: @escaping () -> Void) {
        _coordinator = StateObject(wrappedValue: OnboardingCoordinator(onFinish: onDone))
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            stepView(for: coordinator.currentStep)
                .id(coordinator.currentStep)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    )
                )
        }
        .animation(.easeInOut(duration: 0.25), value: coordinator.currentStep)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func stepView(for step: OnboardingStep) -> some View {
        switch step {
        case .emotionalHook:
            WhatItIs(onNext: coordinator.continueTapped)
        case .appExplanation:
            HabitsMatter(onNext: coordinator.continueTapped)
        case .identityCommitment:
            IdentityFirst(
                selectedCommitments: coordinator.session.selectedIdentityCommitments,
                onCommitmentTapped: coordinator.identityCommitmentChanged,
                canContinue: !coordinator.session.selectedIdentityCommitments.isEmpty,
                onNext: coordinator.continueTapped
            )
        case .tinyHabitSelection:
            let habits = coordinator.session.selectedIdentityCommitments.last.map {
                OnboardingHabitCatalog.habits(for: $0)
            } ?? []
            TinyHabitSelectionView(
                habits: habits,
                selectedHabit: coordinator.session.selectedTinyHabitName,
                onHabitSelected: coordinator.habitSelectionChanged,
                onContinue: coordinator.tinyHabitContinueTapped
            )
        case .firstDot:
            let snapshot = CustomCalendarStore.shared.snapshot
            let firstDotCalendar = coordinator.resolvedFirstCalendarForView(in: snapshot)
            let isCompletedToday = coordinator.isFirstDotCompletedToday(calendar: firstDotCalendar)
            FirstDotView(
                calendar: firstDotCalendar,
                isCompletedToday: isCompletedToday || coordinator.session.didCompleteFirstDot,
                canMarkDayOne: firstDotCalendar != nil && !coordinator.session.didCompleteFirstDot,
                onMarkDayOne: coordinator.firstDotMarkDayOneTapped,
                onContinue: coordinator.firstDotContinueTapped
            )
        case .preReviewGate:
            PreReviewGateView(
                onPositive: { coordinator.preReviewGateAnswered(.positive) },
                onNotNow: { coordinator.preReviewGateAnswered(.neutral) },
                onSkip: { coordinator.preReviewGateAnswered(.skip) }
            )
        case .reviewRequest:
            ReviewRequestView(
                onLeaveReview: {
                    ReviewPrompter.shared.requestReviewNow()
                    coordinator.reviewRequestAnswered()
                },
                onNotNow: coordinator.reviewRequestSkipped
            )
        case .notificationPermission:
            NotificationPermissionView(
                isRequestingNotifications: coordinator.isRequestingNotifications,
                onTurnOnReminders: coordinator.notificationPermissionRequested,
                onNotNow: coordinator.notificationPermissionSkipped
            )
        case .readyWidgets:
            ReadyWidgetsView(onContinue: coordinator.readyWidgetsCompleted)
        case .paywall:
            OnboardingPaywall(onNext: coordinator.paywallClosed)
        }
    }
}

struct OnboardingStepContainer<Top: View, Content: View, Actions: View>: View {
    @ViewBuilder let top: () -> Top
    @ViewBuilder let content: () -> Content
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height

            VStack(spacing: 0) {
                ZStack {
                    top()
                }
                .frame(height: height * 0.7)

                CustomSeparator()

                VStack(alignment: .leading, spacing: 16) {
                    content()
                    Spacer()
                    actions()
                }
                .frame(maxHeight: height * 0.3)
                .padding(.horizontal)
                .background(.surfaceMuted)
            }
            .background(.surfaceMuted)
            .overlay {
                HStack {
                    Rectangle()
                        .fill(Color("devider-bottom"))
                        .frame(maxHeight: .infinity, alignment: .trailing)
                        .frame(maxWidth: 1)

                    Spacer()

                    Rectangle()
                        .fill(Color("devider-top"))
                        .frame(maxHeight: .infinity, alignment: .trailing)
                        .frame(maxWidth: 1)
                }
                .ignoresSafeArea()
            }
        }
    }
}

extension OnboardingView {
    struct ForwardButton: View {
        let title: LocalizedStringKey
        let onTap: () -> Void
        var disabled: Bool = false
        @Environment(\.colorScheme) var colorScheme

        var foregroundColor: Color {
            disabled ? .black : .brandInverted
        }

        var backgroundColor: Color {
            disabled ? .gray : .brand
        }

        var body: some View {
            VStack {
                Button(action: onTap) {
                    Text(title)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(foregroundColor)
                        .font(AppFont.pixelCircle(18))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .sameLevelBorder(radius: 4, color: backgroundColor)
                .disabled(disabled)
            }
            .padding(.all, 2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(getVoidColor(colorScheme: colorScheme))
            )
            .clipped()
            .outerSameLevelShadow()
        }
    }
}

struct TinyHabitSelectionView: View {
    let habits: [String]
    let selectedHabit: String?
    let onHabitSelected: (String) -> Void
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepContainer {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose one tiny habit.")
                    .font(AppFont.pixelCircle(24))
                    .foregroundStyle(.textPrimary)
                Text("Keep it small enough to do today.")
                    .font(AppFont.mono(14))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(habits, id: \.self) { habit in
                        Button {
                            onHabitSelected(habit)
                        } label: {
                            HStack {
                                Text(habit)
                                Spacer()
                                if habit == selectedHabit {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .padding()
                            .foregroundStyle(.textPrimary)
                            .sameLevelBorder(radius: 4, color: habit == selectedHabit ? .brand : .surfaceMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } content: {
            EmptyView()
        } actions: {
            OnboardingView.ForwardButton(title: "Create my habit", onTap: onContinue, disabled: selectedHabit == nil)
        }
    }
}

struct FirstDotView: View {
    let calendar: CustomCalendar?
    let isCompletedToday: Bool
    let canMarkDayOne: Bool
    let onMarkDayOne: () -> Void
    let onContinue: () -> Void
    @State private var animatedCompletion = false

    private var showingProofState: Bool {
        isCompletedToday || animatedCompletion
    }

    var body: some View {
        OnboardingStepContainer {
            VStack(spacing: 18) {
                Circle()
                    .fill(showingProofState ? Color.brand : Color.surfaceMuted)
                    .frame(width: 96, height: 96)
                    .scaleEffect(showingProofState ? 1.04 : 0.9)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.brand, lineWidth: 2)
                            .opacity(showingProofState ? 1 : 0.25)
                    }
                    .shadow(color: Color.brand.opacity(showingProofState ? 0.22 : 0), radius: 16, y: 6)

                if showingProofState {
                    Text("Proof added")
                        .font(AppFont.pixelCircle(18))
                        .foregroundStyle(.textPrimary)
                }
            }
            .padding(.top, 24)
        } content: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Make the first dot.")
                    .font(AppFont.pixelCircle(24))
                    .foregroundStyle(.textPrimary)
                Text(showingProofState ? "Day 1 is in place." : "A single completed day is enough to start.")
                    .font(AppFont.mono(14))
                    .foregroundStyle(.secondary)
            }
        } actions: {
            if showingProofState {
                OnboardingView.ForwardButton(title: "Continue", onTap: onContinue)
            } else {
                OnboardingView.ForwardButton(
                    title: "Mark Day 1",
                    onTap: onMarkDayOne,
                    disabled: !canMarkDayOne || calendar == nil
                )
            }
        }
        .onChange(of: isCompletedToday) { _, newValue in
            withAnimation(.easeInOut(duration: 0.22)) {
                animatedCompletion = newValue
            }
        }
        .onAppear {
            animatedCompletion = isCompletedToday
        }
    }
}

struct PreReviewGateView: View {
    let onPositive: () -> Void
    let onNotNow: () -> Void
    let onSkip: () -> Void

    var body: some View {
        OnboardingStepContainer {
            Color.clear
        } content: {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                Text("How did that first dot feel?")
                    .font(AppFont.pixelCircle(24))
                    .foregroundStyle(.textPrimary)
                Text("Pick the closest answer.")
                    .font(AppFont.mono(14))
                    .foregroundStyle(.secondary)
            }
        } actions: {
            VStack(spacing: 12) {
                OnboardingView.ForwardButton(title: "Great", onTap: onPositive)
                OnboardingView.ForwardButton(title: "Fine", onTap: onNotNow)
                OnboardingView.ForwardButton(title: "Not now", onTap: onSkip)
            }
        }
    }
}

struct ReviewRequestView: View {
    let onLeaveReview: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        OnboardingStepContainer {
            Color.clear
        } content: {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                Text("Review request")
                    .font(AppFont.pixelCircle(24))
                    .foregroundStyle(.textPrimary)
                Text("If the system shows a prompt, use it now.")
                    .font(AppFont.mono(14))
                    .foregroundStyle(.secondary)
            }
        } actions: {
            VStack(spacing: 12) {
                OnboardingView.ForwardButton(title: "Leave a review", onTap: onLeaveReview)
                OnboardingView.ForwardButton(title: "Not now", onTap: onNotNow)
            }
        }
    }
}

struct NotificationPermissionView: View {
    let isRequestingNotifications: Bool
    let onTurnOnReminders: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        OnboardingStepContainer {
            Color.clear
        } content: {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                Text("Turn on reminders.")
                    .font(AppFont.pixelCircle(24))
                    .foregroundStyle(.textPrimary)
                Text("You can change this later in Settings.")
                    .font(AppFont.mono(14))
                    .foregroundStyle(.secondary)
            }
        } actions: {
            VStack(spacing: 12) {
                OnboardingView.ForwardButton(
                    title: isRequestingNotifications ? "Requesting..." : "Turn on reminders",
                    onTap: onTurnOnReminders,
                    disabled: isRequestingNotifications
                )
                OnboardingView.ForwardButton(
                    title: "Not now",
                    onTap: onNotNow,
                    disabled: isRequestingNotifications
                )
            }
        }
    }
}

struct ReadyWidgetsView: View {
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepContainer {
            Color.clear
        } content: {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                Text("Widgets are ready.")
                    .font(AppFont.pixelCircle(24))
                    .foregroundStyle(.textPrimary)
                Text("Put the habit on your home screen.")
                    .font(AppFont.mono(14))
                    .foregroundStyle(.secondary)
            }
        } actions: {
            OnboardingView.ForwardButton(title: "Continue to paywall", onTap: onContinue)
        }
    }
}
