/// `RemoteConfigValueType` を `SwiftType` へ変換する。
public struct TypeMapper: Sendable {
    private let unspecifiedFallback: SwiftType

    public init(config: GeneratorConfig) {
        switch config.typeFallback.unspecifiedValueType {
        case .string: unspecifiedFallback = .string
        }
    }

    /// `valueType`が`nil`（Consoleで未指定）の場合もUNSPECIFIEDと同じ扱いにする。
    public func swiftType(for valueType: RemoteConfigValueType?) -> SwiftType {
        switch valueType {
        case .boolean: .bool
        case .number: .double
        case .string, .json, .unspecified, nil: unspecifiedFallback
        }
    }
}
