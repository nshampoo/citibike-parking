import WidgetKit
import SwiftUI
import BikeKit

// Lock Screen widgets render in a single tint, so color can't carry meaning —
// the dock count itself is the headline, labeled with a short street name ("72nd").

/// Short text for error/empty states, shared by all accessory sizes.
private func statusText(_ entry: DockEntry) -> String? {
    switch entry.state {
    case .failed: "Couldn't load"
    case .noFavorites: "Star stations in the app"
    case .noDestination: "Pick a destination"
    case .noCommute: "Set Home & Work in the app"
    case .loaded: entry.stations.isEmpty ? "No stations" : nil
    }
}

/// A "↻ 5 min ago" row over up to three dots: open docks inside, short street name below.
/// Tapping the top row refreshes.
struct RectangularView: View {
    let entry: DockEntry

    var body: some View {
        VStack(spacing: 2) {
            refreshRow
            if entry.stations.isEmpty {
                Label(statusText(entry) ?? "", systemImage: "bicycle")
                    .font(.caption)
                    .frame(maxHeight: .infinity)
            } else {
                HStack(spacing: 4) {
                    ForEach(entry.stations) { s in
                        VStack(spacing: 1) {
                            Text("\(s.docks)")
                                .font(.headline)
                                .minimumScaleFactor(0.6)
                                .frame(width: 30, height: 30)
                                .background { AccessoryWidgetBackground().clipShape(.circle) }
                                .widgetAccentable()
                            Text(s.shortName)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var refreshRow: some View {
        Button(intent: RefreshIntent()) {
            HStack(spacing: 3) {
                Image(systemName: "arrow.clockwise")
                DataAge(date: entry.date)
            }
            .font(.caption2)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .buttonStyle(.plain)
    }
}

/// How old the counts are. iOS 18+ counts up live ("5 min ago") without spending
/// widget reloads; iOS 17's live relative text is too wordy, so it shows the fetch time.
private struct DataAge: View {
    let date: Date

    var body: some View {
        if #available(iOS 18, *) {
            Text(.currentDate, format: .reference(to: date, allowedFields: [.hour, .minute], maxFieldCount: 1))
        } else {
            Text(date, style: .time)
        }
    }
}

/// Ring gauge of open docks vs. capacity; plain number if capacity is unknown.
struct CircularView: View {
    let entry: DockEntry

    var body: some View {
        if let s = entry.stations.first {
            if let capacity = s.capacity {
                Gauge(value: Double(min(s.docks, capacity)), in: 0...Double(capacity)) {
                    Image(systemName: "bicycle")
                } currentValueLabel: {
                    Text("\(s.docks)")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .widgetAccentable()
            } else {
                VStack(spacing: 0) {
                    Text("\(s.docks)").font(.title2.bold())
                    Text(s.shortName).font(.caption2).lineLimit(1).minimumScaleFactor(0.6)
                }
            }
        } else {
            Image(systemName: entry.state == .failed ? "exclamationmark.triangle" : "bicycle")
        }
    }
}

/// One line above the clock, e.g. "72nd 7 · 73rd 2". Inline widgets only render a single Text/Label.
struct InlineView: View {
    let entry: DockEntry

    var body: some View {
        if entry.stations.isEmpty {
            Label(statusText(entry) ?? "", systemImage: "bicycle")
        } else {
            Label(entry.stations.map { "\($0.shortName) \($0.docks)" }.joined(separator: " · "),
                  systemImage: "bicycle")
        }
    }
}
