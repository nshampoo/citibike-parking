import Foundation

/// Shared storage between the app and the widget extension.
public enum AppGroup {
    /// Read from Info.plist (`AppGroupID`), which XcodeGen fills from the
    /// `APP_GROUP_ID` build setting — so the ID lives in exactly one place.
    public static let id: String =
        Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String
        ?? "group.com.nick.docknearby"
}
