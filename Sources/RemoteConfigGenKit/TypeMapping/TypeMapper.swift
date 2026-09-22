/// `RemoteConfigValueType`をSwiftの型やdefault namespace分類へ変換する。
public struct TypeMapper: Sendable {
    public init() {}

    /// `valueType`が`nil`またはUNSPECIFIEDの場合もStringとして扱う。
    public func normalizedValueType(for valueType: RemoteConfigValueType?) -> RemoteConfigValueType {
        switch valueType {
        case .boolean: .boolean
        case .number: .number
        case .json: .json
        case .string, .unspecified, nil: .string
        }
    }

    /// `valueType`が対応するSwiftの値型を返す。
    public func swiftType(for valueType: RemoteConfigValueType?) -> SwiftType {
        switch normalizedValueType(for: valueType) {
        case .boolean: .bool
        case .number: .double
        case .json, .string: .string
        case .unspecified: .string
        }
    }
}
