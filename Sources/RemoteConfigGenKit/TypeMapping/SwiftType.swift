/// Swift type that corresponds to a Remote Config parameter.
public enum SwiftType: Equatable, Sendable {
    case bool
    case double
    case string

    /// Type name used in generated code, such as the generic argument of `RemoteConfigKey<Bool>`.
    public var typeName: String {
        switch self {
        case .bool: "Bool"
        case .double: "Double"
        case .string: "String"
        }
    }
}
