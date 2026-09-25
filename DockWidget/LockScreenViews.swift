import WidgetKit
import SwiftUI
import BikeKit

// Lock Screen widgets render in a single tint, so color can't carry meaning —
// the dock count itself is the headline, labeled with a short street name ("72nd").

/// Icon for what's being counted: a parking sign for docks, a bolt for e-bikes, else a bike.
private func symbol(for need: Need) -> String {
    switch need {
    case .dock: "parkingsign"
    case .eBike: "bolt.fill"
    case .anyBike, .classicBike: "bicycle"
    }
}

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

/// A "↻ 5 min ago" row (right-aligned) over up to three dots: open docks inside, short street name below.
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
                            DockDot(count: s.count(of: entry.need))
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

    /// "now ↻" pinned to the right. The Spacer sits outside the Button: widget buttons
    /// shrink to their content, so a frame inside the label wouldn't push it over.
    private var refreshRow: some View {
        HStack(spacing: 0) {
            // What the dots count: "PARKING", "BIKES", "E-BIKES"…
            Text(entry.need == .dock ? "PARKING" : entry.need.noun(for: 2).uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Button(intent: RefreshIntent()) {
                HStack(spacing: 4) {
                    // Live dates reserve room for their longest value ("59 minutes ago");
                    // trailing alignment keeps "now" snug against the arrow.
                    DataAge(date: entry.date)
                        .font(.caption2)
                        .multilineTextAlignment(.trailing)
                    Image(systemName: "arrow.clockwise").font(.system(size: 15))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

/// A solid light circle with the dock count cut out of it. Lock Screen widgets
/// render in one tint, so "dark text on light" means letting the wallpaper show through.
private struct DockDot: View {
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
            let n = s.count(of: entry.need)
            if let capacity = s.capacity {
                Gauge(value: Double(min(n, capacity)), in: 0...Double(capacity)) {
                    Image(systemName: symbol(for: entry.need))
                } currentValueLabel: {
                    Text("\(n)")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .widgetAccentable()
            } else {
                VStack(spacing: 0) {
                    Text("\(n)").font(.title2.bold())
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
            Label(entry.stations.map { "\($0.shortName) \($0.count(of: entry.need))" }.joined(separator: " · "),
                  systemImage: symbol(for: entry.need))
        }
    }
}
