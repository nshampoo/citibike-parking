import SwiftUI

/// Shown until the user answers the location prompt. iOS only shows that
/// prompt once, so explain why before asking.
struct OnboardingView: View {
    let onAllow: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "bicycle.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(.blue)
            Text("Find open docks nearby").font(.title.bold())
            Text("DockNearby uses your location to show the closest Citi Bike stations — in the app and in the home screen widget.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            Button(action: onAllow) {
                Text("Allow Location").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(32)
    }
}

#Preview { OnboardingView(onAllow: {}) }
