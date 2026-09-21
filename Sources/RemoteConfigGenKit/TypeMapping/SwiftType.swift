/// Remote Configのparameterが対応するSwiftの型。
public enum SwiftType: Equatable, Sendable {
    case bool
    case double
    case string

    /// 生成コード中の型名（`RemoteConfigKey<Bool>`のジェネリック引数等に使う）。
    public var typeName: String {
        switch self {
        case .bool: "Bool"
        case .double: "Double"
        case .string: "String"
        }
    }
}
