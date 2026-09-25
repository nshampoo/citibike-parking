import SwiftUI
import MapKit
import BikeKit

/// Address/place search. For Home/Work, picking a result saves it right away;
/// for other places it asks for a name first.
struct AddDestinationView: View {
    var kind: Destination.Kind = .other
    @Environment(DestinationsStore.self) private var destinations
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var picked: MKMapItem?
    @State private var name = ""

    /// Bias search results toward the Citi Bike service area.
    private static let serviceArea = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.74, longitude: -73.95),
        latitudinalMeters: 40_000, longitudinalMeters: 40_000)

    var body: some View {
        List(results, id: \.self) { item in
            Button {
                if kind == .other {
                    picked = item
                    name = item.name ?? ""
                } else {
                    destinations.add(name: kind == .home ? "Home" : "Work", kind: kind, at: item.placeCoordinate)
                    dismiss()
                }
            } label: {
                VStack(alignment: .leading) {
                    Text(item.name ?? "Unknown place")
                    if let subtitle = item.placeSubtitle {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .tint(.primary)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Address or place")
        .task(id: query) { await search() }
        .alert("Name this destination", isPresented: .init(get: { picked != nil }, set: { if !$0 { picked = nil } })) {
            TextField("Work, Home…", text: $name)
            Button("Save") { save() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var title: String {
        switch kind {
        case .home: "Set Home"
        case .work: "Set Work"
        case .other: "Add Place"
        }
    }

    private func search() async {
        guard query.count >= 3 else { results = []; return }
        // Debounce: .task(id:) cancels this when the query changes, so only a pause searches.
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = Self.serviceArea
        results = (try? await MKLocalSearch(request: request).start())?.mapItems ?? []
    }

    private func save() {
        guard let picked else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        destinations.add(name: trimmed.isEmpty ? (picked.name ?? "Destination") : trimmed, at: picked.placeCoordinate)
        dismiss()
    }
}

// MKMapItem's placemark is deprecated in iOS 26 in favor of location/address.
extension MKMapItem {
    var placeCoordinate: CLLocationCoordinate2D {
        if #available(iOS 26, *) { location.coordinate } else { placemark.coordinate }
    }

    var placeSubtitle: String? {
        if #available(iOS 26, *) { address?.shortAddress } else { placemark.title }
    }
}
