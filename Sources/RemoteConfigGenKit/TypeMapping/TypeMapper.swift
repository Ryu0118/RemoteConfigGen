/// Converts a `RemoteConfigValueType` into a Swift type and a default-namespace group.
public struct TypeMapper: Sendable {
    public init() {}

    /// Treats `nil` and `.unspecified` as `.string`.
    public func normalizedValueType(for valueType: RemoteConfigValueType?) -> RemoteConfigValueType {
        switch valueType {
        case .boolean: .boolean
        case .number: .number
        case .json: .json
        case .string, .unspecified, nil: .string
        }
    }

    /// Returns the Swift value type for `valueType`.
    public func swiftType(for valueType: RemoteConfigValueType?) -> SwiftType {
        switch normalizedValueType(for: valueType) {
        case .boolean: .bool
        case .number: .double
        case .json, .string: .string
        case .unspecified: .string
        }
    }
}
