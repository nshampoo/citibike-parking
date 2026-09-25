import WidgetKit
import SwiftUI
import AppIntents
import CoreLocation
import BikeKit

// The "Station" widget: everything about one station — parking, classic bikes, e-bikes.
// Like the official app's widget, but it defaults to your nearest favorite.

struct StationConfig: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Station" }
    static var description: IntentDescription { "Parking and bikes at one station." }

    /// Leave empty to follow your nearest favorite.
    @Parameter(title: "Station")
    var station: StationEntity?
}

struct StationEntry: TimelineEntry {
    enum State { case loaded, failed, noStation }

    let date: Date
    let station: NearbyStation?
    let state: State
    var isFavorite = false

    static let sample = StationEntry(
        date: .now,
        station: NearbyStation(id: "1", name: "W 70 St & Amsterdam Ave", meters: 110, docks: 7, classic: 4, ebikes: 3,
                               renting: true, capacity: 20, latitude: 40.7780, longitude: -73.9819),
        state: .loaded, isFavorite: true)
}

struct StationProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> StationEntry { .sample }

    func snapshot(for config: StationConfig, in context: Context) async -> StationEntry {
        context.isPreview ? .sample : await entry(for: config)
    }

    func timeline(for config: StationConfig, in context: Context) async -> Timeline<StationEntry> {
        Timeline(entries: [await entry(for: config)], policy: .after(.now.addingTimeInterval(15 * 60)))
    }

    private func entry(for config: StationConfig) async -> StationEntry {
        let favorites = SharedStore.favorites
        let here = await LocationFetcher.current()
        do {
            let station: NearbyStation?
            if let id = config.station?.id {
                station = try await GBFSClient.shared.nearest(to: here, count: 1, only: [id]).first
            } else if !favorites.isEmpty {
                station = try await GBFSClient.shared.nearest(to: here, count: 1, only: favorites).first
            } else {
                return StationEntry(date: .now, station: nil, state: .noStation)
            }
            return StationEntry(date: .now, station: station, state: station == nil ? .failed : .loaded,
                                isFavorite: station.map { favorites.contains($0.id) } ?? false)
        } catch {
            return StationEntry(date: .now, station: nil, state: .failed)
        }
    }
}

struct StationWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "StationWidget", intent: StationConfig.self, provider: StationProvider()) {
            StationWidgetView(entry: $0)
        }
        .configurationDisplayName("Station")
        .description("Parking, classic bikes, and e-bikes at one station — your nearest favorite unless you pick one.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Views

struct StationWidgetView: View {
    let entry: StationEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let s = entry.station {
                if family == .systemSmall { small(s) } else { medium(s) }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "star").font(.title3).foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Text(entry.state == .noStation ? "Star a station in the app, or pick one in Edit Widget."
                                                   : "Couldn't load")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .containerBackground(.background, for: .widget)
    }

    /// ★ 70th  ↻ / full name / three big numbers with icons.
    private func small(_ s: NearbyStation) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                if entry.isFavorite { Image(systemName: "star.fill").foregroundStyle(.yellow) }
                Text(s.shortName).fontWeight(.bold).lineLimit(1)
                Spacer(minLength: 0)
                refreshButton(showAge: false)
            }
            .font(.subheadline)
            Text(s.name).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            Spacer(minLength: 0)
            if !s.renting { notRenting }
            HStack(spacing: 0) {
                stat(s.docks, icon: "parkingsign")
                stat(s.classic, icon: "bicycle", dimmed: !s.renting)
                stat(s.ebikes, icon: "bolt.fill", dimmed: !s.renting)
            }
        }
    }

    /// Name on top (distance, age and ↻ at the right); the three numbers, labeled, across the bottom.
    private func medium(_ s: NearbyStation) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if entry.isFavorite { Image(systemName: "star.fill").foregroundStyle(.yellow) }
                Text(s.shortName).fontWeight(.bold)
                Spacer(minLength: 4)
                HStack(spacing: 4) {
                    Text(Measurement(value: s.meters, unit: UnitLength.meters),
                         format: .measurement(width: .abbreviated, usage: .road))
                    Text("·")
                    refreshButton(showAge: true)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .font(.headline)
            Text(s.name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            if !s.renting { notRenting }
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                stat(s.docks, icon: "parkingsign", label: "parking")
                stat(s.classic, icon: "bicycle", label: "classic", dimmed: !s.renting)
                stat(s.ebikes, icon: "bolt.fill", label: "e-bikes", dimmed: !s.renting)
            }
        }
    }

    private func stat(_ value: Int, icon: String, label: String? = nil, dimmed: Bool = false) -> some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(label == nil ? .title2.bold() : .largeTitle.bold())   // bigger on medium, which has room
                .monospacedDigit()
                .foregroundStyle(dimmed ? AnyShapeStyle(.secondary) : AnyShapeStyle(availabilityColor(value)))
            HStack(spacing: 3) {
                Image(systemName: icon)
                if let label { Text(label) }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var notRenting: some View {
        Label("Not renting", systemImage: "exclamationmark.triangle.fill")
            .font(.caption2)
            .foregroundStyle(.orange)
    }

    private func refreshButton(showAge: Bool) -> some View {
        Button(intent: RefreshIntent()) {
            HStack(spacing: 3) {
                if showAge { DataAge(date: entry.date) }
                Image(systemName: "arrow.clockwise")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview(as: .systemSmall) { StationWidget() } timeline: { StationEntry.sample }
#Preview(as: .systemMedium) { StationWidget() } timeline: { StationEntry.sample }
