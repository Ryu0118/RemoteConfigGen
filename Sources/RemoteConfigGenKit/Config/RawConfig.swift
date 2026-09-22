/// YAMLのsnake_caseキーをSwiftの設定型へ変換する前の中間表現。
struct RawConfig: Decodable {
    let input: String?
    let output: String?
    let additionalNamespaces: [String: RawNamespace]?

    enum CodingKeys: String, CodingKey {
        case input
        case output
        case additionalNamespaces = "additional_namespaces"
    }
}

/// `additional_namespaces`の1エントリ。
struct RawNamespace: Decodable {
    let keyPrefix: String?
    let additionalKeys: [String]?

    enum CodingKeys: String, CodingKey {
        case keyPrefix = "key_prefix"
        case additionalKeys = "additional_keys"
    }
}
