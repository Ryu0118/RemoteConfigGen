/// Remote Configのkey文字列（多くはsnake_case）をSwiftの識別子へ変換する。
enum IdentifierNaming {
    /// `new_checkout_flow_enabled` -> `newCheckoutFlowEnabled`
    ///
    /// `stripPrefix`が指定され、かつ`key`がその接頭辞から始まる場合、変換前に接頭辞を取り除く
    /// （例: `stripPrefix: "feature_flag_"`、key `feature_flag_goalsApiWrite` -> `goalsApiWrite`）。
    /// 接頭辞に一致しないkeyはそのまま変換する。
    static func camelCase(from key: String, stripPrefix: String? = nil) -> String {
        var key = key
        if let stripPrefix, key.hasPrefix(stripPrefix) {
            key.removeFirst(stripPrefix.count)
        }
        let parts = key.split(separator: "_").map(String.init)
        guard let first = parts.first else { return key }
        let rest = parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }
        let lowercasedFirst = first.prefix(1).lowercased() + first.dropFirst()
        return ([lowercasedFirst] + rest).joined()
    }
}
