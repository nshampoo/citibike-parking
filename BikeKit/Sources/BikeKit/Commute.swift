import Foundation

/// Which way you're commuting at a given time: mornings to Work, the rest of the day Home.
public enum Commute {
    public enum Leg: Sendable { case toWork, toHome }

    /// Work from 4am until noon. The 4am start keeps a late ride home after midnight on Home.
    static let workHours = 4..<12

    public static func leg(at date: Date, calendar: Calendar = .current) -> Leg {
        workHours.contains(calendar.component(.hour, from: date)) ? .toWork : .toHome
    }

    /// The next time `leg(at:)` flips — so the widget can refresh right at the switch.
    public static func nextSwitch(after date: Date, calendar: Calendar = .current) -> Date {
        [workHours.lowerBound, workHours.upperBound]
            .compactMap { calendar.nextDate(after: date, matching: DateComponents(hour: $0, minute: 0),
                                            matchingPolicy: .nextTime) }
            .min() ?? date.addingTimeInterval(3_600)
    }
}
