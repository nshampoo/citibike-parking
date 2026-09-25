import Foundation

/// Squeezes a station name into a few characters for Lock Screen widgets.
public enum StationName {
    /// "W 72 St & Amsterdam Ave" → "72nd". Prefers a numbered street, then any
    /// numbered road ("3 Ave" → "3rd Av"), then the first road minus its suffix
    /// ("Vesey St & Church St" → "Vesey").
    public static func short(_ name: String) -> String {
        // Names join cross streets with "&", and some add a landmark after " - ".
        let parts = name.split(separator: /\s[&-]\s/).map { $0.trimmingCharacters(in: .whitespaces) }

        for part in parts {
            if let m = part.wholeMatch(of: /(?:[NSEW] )?(\d+) St/), let n = Int(m.1) {
                return ordinal(n)
            }
        }
        for part in parts {
            if let m = part.wholeMatch(of: /(?:[NSEW] )?(\d+) (Ave|Rd|Dr|Pl|Ter|Ct)(?: [NSEW])?/), let n = Int(m.1) {
                return "\(ordinal(n)) \(m.2 == "Ave" ? "Av" : String(m.2))"
            }
        }

        var words = (parts.first ?? name).split(separator: " ").map(String.init)
        if words.count > 1, ["N", "S", "E", "W"].contains(words[0]) { words.removeFirst() }
        if words.count > 1, suffixes.contains(words[words.count - 1]) { words.removeLast() }
        return words.joined(separator: " ")
    }

    private static let suffixes: Set<String> = ["St", "Ave", "Av", "Pl", "Rd", "Blvd", "Pkwy", "Dr", "Ct", "Ln", "Ter", "Sq"]

    /// 1st, 2nd, 3rd, 4th … 11th, 12th, 13th … 21st, 22nd …
    static func ordinal(_ n: Int) -> String {
        let suffix = switch (n % 10, n % 100) {
        case (_, 11...13): "th"
        case (1, _): "st"
        case (2, _): "nd"
        case (3, _): "rd"
        default: "th"
        }
        return "\(n)\(suffix)"
    }
}

extension NearbyStation {
    /// A few-character label, e.g. "72nd". See `StationName.short`.
    public var shortName: String { StationName.short(name) }
}
