import SwiftUI

/// Shown until the user answers the location prompt. iOS only shows that
/// prompt once, so explain why before asking. The button says "Continue", not
/// "Allow": App Review (5.1.1) rejects pre-prompts that mimic granting permission.
struct OnboardingView: View {
    let onAllow: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "bicycle.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(.blue)
            Text("Find open docks nearby").font(.title.bold())
            Text("Park It uses your location to show the closest Citi Bike stations — in the app and on your Lock Screen.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            Button(action: onAllow) {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(32)
    }
}

#Preview { OnboardingView(onAllow: {}) }
