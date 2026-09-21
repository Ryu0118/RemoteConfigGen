@testable import RemoteConfigGenKit
import Testing

struct IdentifierNamingTests {
    @Test("snake_case converts to camelCase", arguments: [
        ("study_streak_banner_enabled", "studyStreakBannerEnabled"),
        ("max_upload_size_mb", "maxUploadSizeMb"),
        ("onboarding_variant", "onboardingVariant"),
        ("already_camel", "alreadyCamel"),
        ("single", "single"),
    ])
    func convertsSnakeCaseToCamelCase(input: String, expected: String) {
        #expect(IdentifierNaming.camelCase(from: input) == expected)
    }
}
