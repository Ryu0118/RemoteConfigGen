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

    @Test("strips the given prefix before converting")
    func stripsPrefixBeforeConverting() {
        let result = IdentifierNaming.camelCase(from: "custom_primaryAction", stripPrefix: "custom_")
        #expect(result == "primaryAction")
    }

    @Test("leaves the key untouched when the prefix does not match")
    func leavesKeyUntouchedWhenPrefixDoesNotMatch() {
        let result = IdentifierNaming.camelCase(from: "onboarding_variant", stripPrefix: "custom_")
        #expect(result == "onboardingVariant")
    }

    @Test("nil stripPrefix behaves like the default")
    func nilStripPrefixBehavesLikeDefault() {
        let result = IdentifierNaming.camelCase(from: "max_upload_size_mb", stripPrefix: nil)
        #expect(result == "maxUploadSizeMb")
    }
}
