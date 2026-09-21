/// Remote Configのkey文字列（多くはsnake_case）をSwiftの識別子へ変換する。
enum IdentifierNaming {
    /// `study_streak_banner_enabled` -> `studyStreakBannerEnabled`
    static func camelCase(from key: String) -> String {
        let parts = key.split(separator: "_").map(String.init)
        guard let first = parts.first else { return key }
        let rest = parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }
        return ([first.lowercased()] + rest).joined()
    }
}
