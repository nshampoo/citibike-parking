import SwiftUI

// Compiled into both the app and the widget (see project.yml).

/// Plenty, few, none (of docks or bikes) — softer than the system traffic-light colors.
func availabilityColor(_ count: Int) -> Color {
    switch count {
    case 0: Color(red: 0.86, green: 0.30, blue: 0.31)       // muted red
    case 1...3: Color(red: 0.93, green: 0.62, blue: 0.20)   // amber
    default: Color(red: 0.20, green: 0.64, blue: 0.44)      // deep green
    }
}
