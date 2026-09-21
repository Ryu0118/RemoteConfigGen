@testable import RemoteConfigGenKit
import Testing

struct IdentifierNamingTests {
    @Test("snake_case converts to camelCase", arguments: [
        ("new_checkout_flow_enabled", "newCheckoutFlowEnabled"),
        ("max_upload_size_mb", "maxUploadSizeMb"),
        ("welcome_message_variant", "welcomeMessageVariant"),
        ("already_camel", "alreadyCamel"),
        ("single", "single"),
    ])
    func convertsSnakeCaseToCamelCase(input: String, expected: String) {
        #expect(IdentifierNaming.camelCase(from: input) == expected)
    }
}
