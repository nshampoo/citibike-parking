import SwiftUI

/// The (i) popup: who made this, what it does, where the data comes from.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "bicycle.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                        Text("Hi, I'm Nick 👋").font(.title3.bold())
                        Text("I'm a small developer who's become a Citi Bike addict over the last few years. One feature I always wanted was a Lock Screen widget for parking, so I wouldn't have to open the Citi Bike app mid-ride. So I built it! I hope you all enjoy it as much as I do.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("What it does") {
                    feature("map", "Live map", "Every pin shows how many docks are open right now.")
                    feature("arrow.left.arrow.right", "Park or Ride", "Switch between open docks and bikes to grab — or just e-bikes, or just classics.")
                    feature("parkingsign.circle", "Hide empty", "Hide stations with no open docks (or no bikes).")
                    feature("star.fill", "Favorites", "Star the stations you use most; they stay at the top.")
                    feature("mappin", "Places", "Save Home, Work, or anywhere, and check the docks there before you arrive.")
                    feature("square.grid.2x2", "Widgets", "Parking or bikes nearby, at your favorites, or near a place — on your Home Screen or Lock Screen.")
                    feature("arrow.triangle.swap", "Commute", "Set Home and Work, and the widget shows docks near Work in the morning and Home after noon.")
                    feature("mic.fill", "Siri", "“How many docks at … in Park It” or “Docks near Work in Park It.”")
                    feature("bicycle", "Directions", "Hand off to Apple Maps for cycling directions to any station.")
                }

                Section {
                    Text("Station data comes from Citi Bike's public feed and refreshes every time you open the app. Park It isn't affiliated with Citi Bike or Lyft.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } footer: {
                    Text("Version \(Self.version)")
                }
            }
            .navigationTitle("About Park It")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func feature(_ systemImage: String, _ title: String, _ detail: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage).foregroundStyle(.blue)
        }
    }

    private static let version =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
}

#Preview { AboutView() }
