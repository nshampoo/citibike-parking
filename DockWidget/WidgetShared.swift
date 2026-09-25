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

/// "now ↻" — tap to refresh. Put it after a Spacer to right-align it: widget buttons
/// shrink to their content, so a frame inside the label wouldn't push it over.
struct RefreshButton: View {
    let date: Date
    var showsAge = true
    /// nil matches the text size.
    var arrowSize: CGFloat? = nil

    var body: some View {
        Button(intent: RefreshIntent()) {
            HStack(spacing: 4) {
                if showsAge {
                    // Live dates reserve room for their longest value ("59 minutes ago");
                    // trailing alignment keeps "now" snug against the arrow.
                    DataAge(date: date).multilineTextAlignment(.trailing)
                }
                Image(systemName: "arrow.clockwise").font(arrowSize.map { .system(size: $0) })
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}

/// A solid light circle with a count cut out of it. Lock Screen widgets
/// render in one tint, so "dark text on light" means letting the wallpaper show through.
struct DockDot: View {
    let count: Int

    var body: some View {
        ZStack {
            Circle()
            Text("\(count)")
                .font(.headline.weight(.heavy))
                .minimumScaleFactor(0.6)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .frame(width: 30, height: 30)
        .widgetAccentable()
    }
}
