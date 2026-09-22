/// YAMLのキー名（snake_case）をそのままデコードするための中間表現。トップレベルの必須フィールドは
/// `input`のみで、それ以外はoptionalにし、未指定を「defaultを使う」で扱う。
struct RawConfig: Decodable {
    let input: String?
    let outputs: [RawOutput]?
    let accessLevel: String?
    let headerComment: String?
    let includeConditionSummary: Bool?
    let unspecifiedValueType: String?

    enum CodingKeys: String, CodingKey {
        case input
        case outputs
        case accessLevel = "access_level"
        case headerComment = "header_comment"
        case includeConditionSummary = "include_condition_summary"
        case unspecifiedValueType = "unspecified_value_type"
    }
}

/// `outputs`の1エントリ。`type: enum` / `type: keys`で後続フィールドの意味が変わる。
struct RawOutput: Decodable {
    let type: String?
    let name: String?
    let keyPrefix: String?
    let additionalKeys: [String]?
    let path: String?
    let rawValue: Bool?
    let conformances: [String]?
    let namespace: String?
    let keyType: String?

    enum CodingKeys: String, CodingKey {
        case type
        case name
        case keyPrefix = "key_prefix"
        case additionalKeys = "additional_keys"
        case path
        case rawValue = "raw_value"
        case conformances
        case namespace
        case keyType = "key_type"
    }
}
