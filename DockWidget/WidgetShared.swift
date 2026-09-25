import WidgetKit
import SwiftUI
import BikeKit

// Pieces used by every widget size, home screen and Lock Screen alike.

/// What the numbers count, as a row label: "PARKING", "BIKES", "E-BIKES"…
func countLabel(for need: Need) -> String {
    need == .dock ? "PARKING" : need.noun(for: 2).uppercased()
}

/// Short text for error/empty states, shared by every widget size.
func statusText(_ entry: DockEntry) -> String? {
    switch entry.state {
    case .failed: "Couldn't load"
    case .noFavorites: "Star stations in the app"
    case .noDestination: "Pick a destination"
    case .noCommute: "Set Home & Work in the app"
    case .loaded: entry.stations.isEmpty ? "No stations" : nil
    }
}

/// How old the counts are. iOS 18+ counts up live ("5 min ago") without spending
/// widget reloads; iOS 17's live relative text is too wordy, so it shows the fetch time.
struct DataAge: View {
    let date: Date

    var body: some View {
        if #available(iOS 18, *) {
            Text(.currentDate, format: .reference(to: date, allowedFields: [.hour, .minute], maxFieldCount: 1))
        } else {
            Text(date, style: .time)
        }
    }
}
