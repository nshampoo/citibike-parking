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

    /// "PARKING" on the left, "now ↻" pinned to the right.
    private var refreshRow: some View {
        HStack(spacing: 0) {
            Text(countLabel(for: entry.need))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            RefreshButton(date: entry.date, arrowSize: 15)
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
