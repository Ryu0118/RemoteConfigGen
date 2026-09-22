@testable import RemoteConfigGenKit
import Testing

struct TypeMapperTests {
    private let mapper = TypeMapper()

    @Test("maps Firebase value types to the Swift types used by callers", arguments: [
        (RemoteConfigValueType.boolean, SwiftType.bool),
        (.number, .double),
        (.string, .string),
        (.json, .string),
        (.unspecified, .string),
    ])
    func mapsKnownValueTypes(valueType: RemoteConfigValueType, expected: SwiftType) {
        #expect(mapper.swiftType(for: valueType) == expected)
    }

    @Test("missing value metadata uses the String mapping")
    func nilValueTypeFallsBackToString() {
        #expect(mapper.swiftType(for: nil) == .string)
    }

    @Test("normalizes unspecified and missing value types to STRING")
    func normalizesUnknownValueTypes() {
        #expect(mapper.normalizedValueType(for: .unspecified) == .string)
        #expect(mapper.normalizedValueType(for: nil) == .string)
    }
}
