import Foundation

/// Firebase Remote Configのテンプレートエクスポート形式（`firebase remoteconfig:get`の出力）。
public struct RemoteConfigTemplate: Decodable, Equatable, Sendable {
    /// parameter key名をキーとするparameter定義の辞書。
    public var parameters: [String: RemoteConfigParameter]
    /// テンプレートが持つcondition一覧。
    public var conditions: [RemoteConfigCondition]

    public init(parameters: [String: RemoteConfigParameter], conditions: [RemoteConfigCondition]) {
        self.parameters = parameters
        self.conditions = conditions
    }

    enum CodingKeys: String, CodingKey {
        case parameters
        case conditions
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parameters = try container.decodeIfPresent([String: RemoteConfigParameter].self, forKey: .parameters) ?? [:]
        conditions = try container.decodeIfPresent([RemoteConfigCondition].self, forKey: .conditions) ?? []
    }
}

/// 1つのRemote Configパラメータの定義。
public struct RemoteConfigParameter: Decodable, Equatable, Sendable {
    /// 既定値。
    public var defaultValue: RemoteConfigDefaultValue?
    /// Firebase Consoleで設定された値の型。未指定の場合は`nil`。
    public var valueType: RemoteConfigValueType?
    /// condition名をキーとするconditional value（段階ロールアウト等）の辞書。`defaultValue`と同じ
    /// `{"value": "..."}` / `{"useInAppDefault": true}`形式（Firebase Remote Config REST APIの
    /// `RemoteConfigParameterValue`と同型）。
    public var conditionalValues: [String: RemoteConfigDefaultValue]

    public init(
        defaultValue: RemoteConfigDefaultValue?,
        valueType: RemoteConfigValueType?,
        conditionalValues: [String: RemoteConfigDefaultValue] = [:],
    ) {
        self.defaultValue = defaultValue
        self.valueType = valueType
        self.conditionalValues = conditionalValues
    }

    enum CodingKeys: String, CodingKey {
        case defaultValue
        case valueType
        case conditionalValues
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultValue = try container.decodeIfPresent(RemoteConfigDefaultValue.self, forKey: .defaultValue)
        valueType = try container.decodeIfPresent(RemoteConfigValueType.self, forKey: .valueType)
        let decoded = try container.decodeIfPresent(
            [String: RemoteConfigDefaultValue].self,
            forKey: .conditionalValues,
        )
        conditionalValues = decoded ?? [:]
    }
}

/// `defaultValue`は `{"value": "..."}` （静的値）または `{"useInAppDefault": true}`（アプリ内既定値を使う）のいずれか。
public enum RemoteConfigDefaultValue: Decodable, Equatable, Sendable {
    case value(String)
    case useInAppDefault

    enum CodingKeys: String, CodingKey {
        case value
        case useInAppDefault
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try container.decodeIfPresent(String.self, forKey: .value) {
            self = .value(value)
        } else {
            self = .useInAppDefault
        }
    }
}

/// Firebase Remote Configのparameter値型。
public enum RemoteConfigValueType: String, Decodable, Equatable, Sendable {
    case boolean = "BOOLEAN"
    case string = "STRING"
    case number = "NUMBER"
    case json = "JSON"
    case unspecified = "PARAMETER_VALUE_TYPE_UNSPECIFIED"
}

/// Remote Configのcondition定義（percent rollout等）。
public struct RemoteConfigCondition: Decodable, Equatable, Sendable {
    /// condition名。parameterの`conditionalValues`のキーと対応する。
    public var name: String
    /// condition式（例: `percent('seed') <= 50`）。
    public var expression: String

    public init(name: String, expression: String) {
        self.name = name
        self.expression = expression
    }
}
