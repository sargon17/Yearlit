import Garnish
import SharedModels
import SwiftUI

@MainActor
final class OnboardingCoordinator: ObservableObject {
    @Published private(set) var currentStep: OnboardingStep
    @Published var session: OnboardingSession

    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        currentStep = .emotionalHook
        session = OnboardingSession()
    }

    func continueTapped() {
        route(from: currentStep)
    }

    func habitSelectionChanged(_ name: String) {
        session.selectedTinyHabitName = name
    }

    func tinyHabitContinueTapped() {
        createTinyHabitCalendarIfNeeded()
        currentStep = .firstDot
    }

    func firstDotCompleted() {
        logFirstDotIfNeeded()
        session.didCompleteFirstDot = true
        currentStep = .preReviewGate
    }

    func preReviewGateAccepted() {
        session.didAcceptReviewGate = true
        currentStep = .reviewRequest
    }

    func preReviewGateSkipped() {
        session.didAcceptReviewGate = false
        currentStep = .notificationPermission
    }

    func reviewRequestCompleted() {
        addPositiveEvent(.completedOnboarding)
        session.didRequestReview = true
        currentStep = .notificationPermission
    }

    func notificationPermissionCompleted() {
        requestNotificationPermissions { _ in
            Task { @MainActor in
                self.session.didRequestNotifications = true
                self.currentStep = .readyWidgets
            }
        }
    }

    func readyWidgetsCompleted() {
        currentStep = .paywall
    }

    func paywallClosed() {
        onFinish()
    }

    private func createTinyHabitCalendarIfNeeded() {
        guard session.tinyHabitCalendarId == nil else { return }
        let isFirstCalendar = CustomCalendarStore.shared.snapshot.calendars.filter { !$0.isArchived }.isEmpty

        let calendar = CustomCalendar(
            name: session.selectedTinyHabitName,
            color: "qs-amber",
            cadence: .daily,
            trackingType: .binary,
            trackingStartedAt: Date(),
            dailyTarget: 1,
            entries: [:],
            isArchived: false,
            recurringReminderEnabled: false,
            reminderTime: nil,
            reminderWeekday: nil,
            unit: nil,
            defaultRecordValue: nil,
            currencySymbol: nil,
            reminderTimeZone: TimeZone.current.identifier,
            notificationPrivacyMode: .full,
            suppressWhenCompleted: true,
            additionalReminderTimes: [],
            streakProtectionEnabled: true,
            streakProtectionThreshold: 5
        )

        session.tinyHabitCalendarId = calendar.id
        CustomCalendarStore.shared.addCalendar(calendar)
        CalendarAnalyticsTracker.shared.trackCalendarCreated(
            calendar: calendar,
            isFirstCalendar: isFirstCalendar
        )
        scheduleNotifications(for: calendar, store: CustomCalendarStore.shared)
    }

    private func logFirstDotIfNeeded() {
        guard let calendarId = session.tinyHabitCalendarId else { return }
        guard !session.didCompleteFirstDot else { return }
        let entry = defaultEntry(date: Date(), trackingType: .binary)
        CustomCalendarStore.shared.addEntry(calendarId: calendarId, entry: entry)
    }

    private func route(from step: OnboardingStep) {
        switch step {
        case .emotionalHook:
            currentStep = .appExplanation
        case .appExplanation:
            currentStep = .identityCommitment
        case .identityCommitment:
            currentStep = .tinyHabitSelection
        case .tinyHabitSelection:
            tinyHabitContinueTapped()
        case .firstDot:
            firstDotCompleted()
        case .preReviewGate:
            currentStep = session.didAcceptReviewGate ? .reviewRequest : .notificationPermission
        case .reviewRequest:
            reviewRequestCompleted()
        case .notificationPermission:
            notificationPermissionCompleted()
        case .readyWidgets:
            readyWidgetsCompleted()
        case .paywall:
            paywallClosed()
        }
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
    var selectedTinyHabitName: String = "Daily Training"
    var tinyHabitCalendarId: UUID?
    var didCompleteFirstDot = false
    var didAcceptReviewGate = false
    var didRequestReview = false
    var didRequestNotifications = false
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
            IdentityFirst(onNext: coordinator.continueTapped)
        case .tinyHabitSelection:
            TinyHabitSelectionView(
                selectedHabit: coordinator.session.selectedTinyHabitName,
                onHabitSelected: coordinator.habitSelectionChanged,
                onContinue: coordinator.tinyHabitContinueTapped
            )
        case .firstDot:
            FirstDotView(
                onContinue: coordinator.firstDotCompleted
            )
        case .preReviewGate:
            PreReviewGateView(
                onReview: coordinator.preReviewGateAccepted,
                onSkip: coordinator.preReviewGateSkipped
            )
        case .reviewRequest:
            ReviewRequestView(
                onContinue: coordinator.reviewRequestCompleted
            )
        case .notificationPermission:
            NotificationPermissionView(
                onContinue: coordinator.notificationPermissionCompleted
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
    let selectedHabit: String
    let onHabitSelected: (String) -> Void
    let onContinue: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private let habits = ["Daily Training", "Reading", "Walking", "Mindfulness"]

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
            OnboardingView.ForwardButton(title: "Continue", onTap: onContinue)
        }
    }
}

struct FirstDotView: View {
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepContainer {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Make the first dot.")
                    .font(AppFont.pixelCircle(24))
                    .foregroundStyle(.textPrimary)
                Text("A single completed day is enough to start.")
                    .font(AppFont.mono(14))
                    .foregroundStyle(.secondary)
            }
        } actions: {
            OnboardingView.ForwardButton(title: "I did it", onTap: onContinue)
        }
    }
}

struct PreReviewGateView: View {
    let onReview: () -> Void
    let onSkip: () -> Void

    var body: some View {
        OnboardingStepContainer {
            Color.clear
        } content: {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                Text("Want to help?")
                    .font(AppFont.pixelCircle(24))
                    .foregroundStyle(.textPrimary)
                Text("A quick review helps more than you think.")
                    .font(AppFont.mono(14))
                    .foregroundStyle(.secondary)
            }
        } actions: {
            VStack(spacing: 12) {
                OnboardingView.ForwardButton(title: "Leave a review", onTap: onReview)
                OnboardingView.ForwardButton(title: "Skip", onTap: onSkip)
            }
        }
    }
}

struct ReviewRequestView: View {
    let onContinue: () -> Void

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
            OnboardingView.ForwardButton(title: "Continue", onTap: {
                onContinue()
            })
        }
    }
}

struct NotificationPermissionView: View {
    let onContinue: () -> Void

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
            OnboardingView.ForwardButton(title: "Request permissions", onTap: {
                onContinue()
            })
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
