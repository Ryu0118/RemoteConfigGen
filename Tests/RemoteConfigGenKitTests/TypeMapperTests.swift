@testable import RemoteConfigGenKit
import Testing

struct TypeMapperTests {
    private func makeConfig() -> GeneratorConfig {
        GeneratorConfig(input: "a.json")
    }

    @Test("BOOLEAN maps to Bool", arguments: [
        (RemoteConfigValueType.boolean, SwiftType.bool),
        (.number, .double),
        (.string, .string),
        (.json, .string),
        (.unspecified, .string),
    ])
    func mapsKnownValueTypes(valueType: RemoteConfigValueType, expected: SwiftType) {
        let mapper = TypeMapper(config: makeConfig())
        #expect(mapper.swiftType(for: valueType) == expected)
    }

    @Test("nil valueType falls back to the same rule as UNSPECIFIED")
    func nilValueTypeFallsBackToString() {
        let mapper = TypeMapper(config: makeConfig())
        #expect(mapper.swiftType(for: nil) == .string)
    }
}
