/// YAMLのキー名（snake_case）をそのままデコードするための中間表現。全フィールドoptionalにし、
/// 未指定を「defaultを使う」と「明示的に無効化した」で区別できるようにする。
struct RawConfig: Decodable {
    let input: RawInput?
    let output: RawOutput?
    let naming: RawNaming?
    let boolOutput: RawBoolOutput?
    let nonBoolOutput: RawNonBoolOutput?
    let typeFallback: RawTypeFallback?
    let documentation: RawDocumentation?

    enum CodingKeys: String, CodingKey {
        case input
        case output
        case naming
        case boolOutput = "bool_output"
        case nonBoolOutput = "non_bool_output"
        case typeFallback = "type_fallback"
        case documentation
    }
}

struct RawInput: Decodable {
    let remoteConfigJSON: String?
    enum CodingKeys: String, CodingKey { case remoteConfigJSON = "remote_config_json" }
}

struct RawOutput: Decodable {
    let directory: String?
    let accessLevel: String?
    let headerComment: String?
    enum CodingKeys: String, CodingKey {
        case directory
        case accessLevel = "access_level"
        case headerComment = "header_comment"
    }
}

struct RawNaming: Decodable {
    let caseConvention: String?
    enum CodingKeys: String, CodingKey { case caseConvention = "case_convention" }
}

struct RawBoolOutput: Decodable {
    let fileName: String?
    let enumName: String?
    let rawValue: Bool?
    let conformances: [String]?
    let stripKeyPrefix: String?
    let includeKeyPrefix: String?
    let additionalKeys: [String]?
    enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
        case enumName = "enum_name"
        case rawValue = "raw_value"
        case conformances
        case stripKeyPrefix = "strip_key_prefix"
        case includeKeyPrefix = "include_key_prefix"
        case additionalKeys = "additional_keys"
    }
}

struct RawNonBoolOutput: Decodable {
    let fileName: String?
    let namespace: String?
    let keyType: String?
    enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
        case namespace
        case keyType = "key_type"
    }
}

struct RawTypeFallback: Decodable {
    let unspecifiedValueType: String?
    enum CodingKeys: String, CodingKey { case unspecifiedValueType = "unspecified_value_type" }
}

struct RawDocumentation: Decodable {
    let includeConditionSummary: Bool?
    enum CodingKeys: String, CodingKey { case includeConditionSummary = "include_condition_summary" }
}
