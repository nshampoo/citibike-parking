import WidgetKit
import SwiftUI
import BikeKit

/// Picks the layout for whichever size the user placed.
struct DockWidgetView: View {
    let entry: DockEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            RectangularView(entry: entry).containerBackground(.clear, for: .widget)
        case .accessoryCircular:
            CircularView(entry: entry).containerBackground(for: .widget) { AccessoryWidgetBackground() }
        case .accessoryInline:
            InlineView(entry: entry).containerBackground(.clear, for: .widget)
        default:
            HomeScreenView(entry: entry)
        }
    }
}

/// Everything this extension offers in the widget gallery.
@main
struct ParkItWidgets: WidgetBundle {
    var body: some Widget {
        DockWidget()
        StationWidget()
    }
}

struct DockWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "DockWidget", intent: DockConfig.self, provider: Provider()) {
            DockWidgetView(entry: $0)
        }
        .configurationDisplayName("Citi Bike Docks")
        .description("Parking or bikes at nearby, favorite, or destination stations.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryRectangular, .accessoryCircular, .accessoryInline,   // Lock Screen
        ])
    }
}

#Preview(as: .systemMedium) { DockWidget() } timeline: { DockEntry.sample }
#Preview(as: .systemSmall) { DockWidget() } timeline: { DockEntry.sample }

#Preview(as: .accessoryRectangular) { DockWidget() } timeline: {
    DockEntry.sample
    DockEntry(date: .now, stations: [], state: .noFavorites)
}
#Preview(as: .accessoryCircular) { DockWidget() } timeline: { DockEntry.sample }
#Preview(as: .accessoryInline) { DockWidget() } timeline: { DockEntry.sample }
