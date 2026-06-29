import SharedModels
import SwiftUI

enum MilestoneKind: String {
    case streak
    case showedUp
    case showedUpMonth
    case showedUpYear
}

struct MilestoneCopy {
    let header: LocalizedStringKey
    let kicker: LocalizedStringKey
    let label: LocalizedStringKey
}

extension MilestoneKind {
    func copy(milestone: Int, cadence: CalendarCadence) -> MilestoneCopy {
        let unitSingular = cadence == .weekly ? "Week" : "Day"
        let unitPlural = cadence == .weekly ? "Weeks" : "Days"

        switch self {
        case .streak:
            return streakCopy(milestone: milestone, cadence: cadence, unitSingular: unitSingular, unitPlural: unitPlural)
        case .showedUp:
            return showedUpCopy(milestone: milestone, cadence: cadence, unitPlural: unitPlural)
        case .showedUpMonth:
            return showedUpMonthCopy(milestone: milestone, unitPlural: unitPlural)
        case .showedUpYear:
            return showedUpYearCopy(milestone: milestone, unitPlural: unitPlural)
        }
    }

    private func streakCopy(
        milestone: Int,
        cadence: CalendarCadence,
        unitSingular: String,
        unitPlural: String
    ) -> MilestoneCopy {
        switch milestone {
        case 1:
            return MilestoneCopy(
                header: cadence == .weekly ? "First week down" : "First day down",
                kicker: "Streak started",
                label: "\(unitSingular) in a row"
            )
        case 2 ... 3:
            return MilestoneCopy(header: "Keep it going", kicker: "Momentum building", label: "\(unitPlural) in a row")
        case 4 ... 5:
            return MilestoneCopy(
                header: "You are on fire",
                kicker: cadence == .weekly ? "Strong weekly momentum" : "Strong daily momentum",
                label: "\(unitPlural) in a row"
            )
        case 6 ... 10:
            return MilestoneCopy(
                header: "This is real",
                kicker: cadence == .weekly ? "Locked in week after week" : "Locked in day after day",
                label: "\(unitPlural) straight"
            )
        case 11 ... 20:
            return MilestoneCopy(
                header: "Streak machine",
                kicker: cadence == .weekly ? "Weekly consistency unlocked" : "Daily consistency unlocked",
                label: "\(unitPlural) straight"
            )
        case 21 ... 30:
            return MilestoneCopy(
                header: "No misses",
                kicker: cadence == .weekly ? "Still stacking great weeks" : "Still stacking great days",
                label: "\(unitPlural) straight"
            )
        case 31 ... 50:
            return MilestoneCopy(
                header: "Unreal run",
                kicker: cadence == .weekly ? "An unreal weekly run" : "An unreal daily run",
                label: "\(unitPlural) blazing"
            )
        default:
            return MilestoneCopy(
                header: "Legendary streak",
                kicker: "\(milestone) \(cadence == .weekly ? "weeks" : "days") strong",
                label: "\(unitPlural) blazing"
            )
        }
    }

    private func showedUpCopy(milestone: Int, cadence: CalendarCadence, unitPlural: String) -> MilestoneCopy {
        switch milestone {
        case 5:
            return MilestoneCopy(
                header: "You showed up",
                kicker: cadence == .weekly ? "A strong weekly start" : "A strong daily start",
                label: "\(unitPlural) showed up"
            )
        case 10:
            return MilestoneCopy(
                header: "Consistency unlocked",
                kicker: cadence == .weekly ? "Week after week" : "Day after day",
                label: "\(unitPlural) showed up"
            )
        case 20:
            return MilestoneCopy(header: "You are in it", kicker: "Deep into the rhythm", label: "\(unitPlural) showed up")
        case 30:
            return MilestoneCopy(
                header: cadence == .weekly ? "A huge run" : "A full month",
                kicker: cadence == .weekly ? "That is serious consistency" : "Thirty days strong",
                label: "\(unitPlural) showed up"
            )
        case 40:
            return MilestoneCopy(
                header: "No excuses",
                kicker: cadence == .weekly ? "Still showing up every week" : "Still showing up every day",
                label: "\(unitPlural) showed up"
            )
        case 50:
            return MilestoneCopy(
                header: "Beast mode",
                kicker: cadence == .weekly ? "Weekly consistency on lock" : "Fifty days strong",
                label: "\(unitPlural) showed up"
            )
        case 75:
            return MilestoneCopy(
                header: "You are relentless",
                kicker: "Seventy-five \(cadence == .weekly ? "weeks" : "days")",
                label: "\(unitPlural) showed up"
            )
        case 100:
            return MilestoneCopy(
                header: "Century club",
                kicker: "100 \(cadence == .weekly ? "weeks" : "days") showed up",
                label: "\(unitPlural) showed up"
            )
        case 150:
            return MilestoneCopy(
                header: "Absolutely unreal",
                kicker: "150 \(cadence == .weekly ? "weeks" : "days") in",
                label: "\(unitPlural) showed up"
            )
        default:
            return MilestoneCopy(
                header: "Built different",
                kicker: "\(milestone) \(cadence == .weekly ? "weeks" : "days") showed up",
                label: "\(unitPlural) showed up"
            )
        }
    }

    private func showedUpMonthCopy(milestone: Int, unitPlural: String) -> MilestoneCopy {
        switch milestone {
        case 3:
            return MilestoneCopy(
                header: "Month in motion",
                kicker: "A clean start this month",
                label: "\(unitPlural) showed up this month"
            )
        case 5 ... 7:
            return MilestoneCopy(
                header: "You are showing up",
                kicker: "This month has momentum",
                label: "\(unitPlural) showed up this month"
            )
        case 8 ... 14:
            return MilestoneCopy(
                header: "Strong month",
                kicker: "You keep coming back",
                label: "\(unitPlural) showed up this month"
            )
        case 15 ... 21:
            return MilestoneCopy(
                header: "Locked in",
                kicker: "Half the month and counting",
                label: "\(unitPlural) showed up this month"
            )
        default:
            return MilestoneCopy(
                header: "Month owned",
                kicker: "This month has your name on it",
                label: "\(unitPlural) showed up this month"
            )
        }
    }

    private func showedUpYearCopy(milestone: Int, unitPlural: String) -> MilestoneCopy {
        switch milestone {
        case 7:
            return MilestoneCopy(
                header: "Year started right",
                kicker: "Seven days already banked",
                label: "\(unitPlural) showed up this year"
            )
        case 8 ... 30:
            return MilestoneCopy(
                header: "Building the year",
                kicker: "A real base is forming",
                label: "\(unitPlural) showed up this year"
            )
        case 31 ... 90:
            return MilestoneCopy(
                header: "This is lasting",
                kicker: "You keep stacking good days",
                label: "\(unitPlural) showed up this year"
            )
        case 91 ... 180:
            return MilestoneCopy(
                header: "Half-year pace",
                kicker: "This is bigger than a phase",
                label: "\(unitPlural) showed up this year"
            )
        default:
            return MilestoneCopy(
                header: "Year on lock",
                kicker: "You are writing the whole story",
                label: "\(unitPlural) showed up this year"
            )
        }
    }
}
