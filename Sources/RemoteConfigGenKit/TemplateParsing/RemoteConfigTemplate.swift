import Foundation

/// Firebase Remote Config template export (the output of `firebase remoteconfig:get`).
public struct RemoteConfigTemplate: Decodable, Equatable, Sendable {
    /// Parameter definitions keyed by parameter name.
    public var parameters: [String: RemoteConfigParameter]
    /// Conditions declared on the template.
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

/// Definition of a single Remote Config parameter.
public struct RemoteConfigParameter: Decodable, Equatable, Sendable {
    /// The default value.
    public var defaultValue: RemoteConfigDefaultValue?
    /// Value type set in the Firebase console. `nil` when it is not specified.
    public var valueType: RemoteConfigValueType?
    /// Conditional values keyed by condition name, such as staged rollouts. Uses the same
    /// `{"value": "..."}` or `{"useInAppDefault": true}` shape as `defaultValue` (the
    /// Firebase Remote Config REST API `RemoteConfigParameterValue` type).
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

/// A default value is either `{"value": "..."}` (a static value) or
/// `{"useInAppDefault": true}` (use the in-app default).
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

/// Firebase Remote Config parameter value type.
public enum RemoteConfigValueType: String, Decodable, Equatable, Hashable, Sendable {
    case boolean = "BOOLEAN"
    case string = "STRING"
    case number = "NUMBER"
    case json = "JSON"
    case unspecified = "PARAMETER_VALUE_TYPE_UNSPECIFIED"
}

/// A Remote Config condition, such as a percent rollout.
public struct RemoteConfigCondition: Decodable, Equatable, Sendable {
    /// Condition name. Corresponds to a key in a parameter's `conditionalValues`.
    public var name: String
    /// Condition expression (for example, `percent('seed') <= 50`).
    public var expression: String

    public init(name: String, expression: String) {
        self.name = name
        self.expression = expression
    }
}
