import Foundation
@testable import RemoteConfigGenKit
import Testing

struct GenerateRunnerTests {
    private func makeTemporaryDirectory() -> URL {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("generates a bool enum and a non-bool namespace from a mixed template")
    func generatesMixedTemplate() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input:
          remote_config_json: "remoteconfig.json"
        output:
          directory: "Generated"
        """.write(to: workingDirectory.appending(path: "config.yml"), atomically: true, encoding: .utf8)

        try """
        {
          "parameters": {
            "study_streak_banner_enabled": {
              "defaultValue": {"value": "true"},
              "valueType": "BOOLEAN",
              "conditionalValues": {
                "fifty_percent_rollout": {"value": {"value": "false"}}
              }
            },
            "onboarding_variant": {
              "defaultValue": {"value": "control"},
              "valueType": "STRING"
            },
            "max_upload_size_mb": {
              "defaultValue": {"value": "50"},
              "valueType": "NUMBER"
            }
          },
          "conditions": [
            {"name": "fifty_percent_rollout", "expression": "percent('seed') <= 50"}
          ]
        }
        """.write(to: workingDirectory.appending(path: "remoteconfig.json"), atomically: true, encoding: .utf8)

        try await GenerateRunner(workingDirectory: workingDirectory).run()

        let generatedDirectory = workingDirectory.appending(path: "Generated")
        let flagSourceURL = generatedDirectory.appending(path: "FeatureFlag.swift")
        let flagSource = try String(contentsOf: flagSourceURL, encoding: .utf8)
        #expect(flagSource.contains("enum FeatureFlag: String, CaseIterable, Sendable"))
        #expect(flagSource.contains("case studyStreakBannerEnabled = \"study_streak_banner_enabled\""))
        #expect(flagSource.contains("Rollout: `percent('seed') <= 50` (condition: \"fifty_percent_rollout\")"))

        let keysSourceURL = generatedDirectory.appending(path: "RemoteConfigKeys.swift")
        let keysSource = try String(contentsOf: keysSourceURL, encoding: .utf8)
        #expect(keysSource.contains("enum RemoteConfigKeys"))
        #expect(keysSource.contains("static let onboardingVariant = RemoteConfigKey<String>(\"onboarding_variant\")"))
        #expect(keysSource.contains("static let maxUploadSizeMb = RemoteConfigKey<Double>(\"max_upload_size_mb\")"))
    }

    @Test("omits the bool file entirely when the template has no boolean parameters")
    func omitsBoolFileWhenNoBooleanParameters() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input:
          remote_config_json: "remoteconfig.json"
        output:
          directory: "Generated"
        """.write(to: workingDirectory.appending(path: "config.yml"), atomically: true, encoding: .utf8)

        try """
        {
          "parameters": {
            "onboarding_variant": {
              "defaultValue": {"value": "control"},
              "valueType": "STRING"
            }
          },
          "conditions": []
        }
        """.write(to: workingDirectory.appending(path: "remoteconfig.json"), atomically: true, encoding: .utf8)

        try await GenerateRunner(workingDirectory: workingDirectory).run()

        let generatedDirectory = workingDirectory.appending(path: "Generated")
        let flagPath = generatedDirectory.appending(path: "FeatureFlag.swift").path()
        let keysPath = generatedDirectory.appending(path: "RemoteConfigKeys.swift").path()
        #expect(!FileManager.default.fileExists(atPath: flagPath))
        #expect(FileManager.default.fileExists(atPath: keysPath))
    }

    @Test("missing remote config template throws remoteConfigTemplateNotFound")
    func missingTemplateThrows() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input:
          remote_config_json: "missing.json"
        output:
          directory: "Generated"
        """.write(to: workingDirectory.appending(path: "config.yml"), atomically: true, encoding: .utf8)

        let runner = GenerateRunner(workingDirectory: workingDirectory)

        await #expect(throws: RemoteConfigGenError.self) {
            try await runner.run()
        }
    }
}
