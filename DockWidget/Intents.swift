import AppIntents
import WidgetKit

enum StationMode: String, AppEnum {
    case closest, favorites, destination

    // Computed (not `static var x = ...`): Swift 6 rejects mutable globals.
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Stations" }
    static var caseDisplayRepresentations: [StationMode: DisplayRepresentation] {
        [.closest: "Closest to me", .favorites: "My favorites", .destination: "Near a destination"]
    }
}

/// The per-widget setting shown under long-press > Edit Widget.
struct DockConfig: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Stations" }
    static var description: IntentDescription { "Choose which stations the widget shows." }

    @Parameter(title: "Show", default: .closest)
    var mode: StationMode

    @Parameter(title: "Destination")
    var destination: DestinationEntity?

    @Parameter(title: "Only stations with room", default: false)
    var needsRoom: Bool

    // Only ask for a destination when that mode is picked.
    static var parameterSummary: some ParameterSummary {
        When(\DockConfig.$mode, .equalTo, StationMode.destination) {
            Summary {
                \.$mode
                \.$destination
                \.$needsRoom
            }
        } otherwise: {
            Summary {
                \.$mode
                \.$needsRoom
            }
        }
    }
}

/// Tapping a Button(intent:) runs perform(), then WidgetKit reloads the timeline.
struct RefreshIntent: AppIntent {
    static var title: LocalizedStringResource { "Refresh Citi Bike" }
    static var isDiscoverable: Bool { false }   // widget-only; hide from Shortcuts

    func perform() async throws -> some IntentResult { .result() }
}
