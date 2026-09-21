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
            "new_checkout_flow_enabled": {
              "defaultValue": {"value": "true"},
              "valueType": "BOOLEAN",
              "conditionalValues": {
                "fifty_percent_rollout": {"value": {"value": "false"}}
              }
            },
            "welcome_message_variant": {
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

        let result = try await GenerateRunner(workingDirectory: workingDirectory).run()
        #expect(result.parameterCount == 3)
        #expect(result.writtenFiles.count == 2)

        let generatedDirectory = workingDirectory.appending(path: "Generated")
        let flagSourceURL = generatedDirectory.appending(path: "FeatureFlag.swift")
        let flagSource = try String(contentsOf: flagSourceURL, encoding: .utf8)
        #expect(flagSource.contains("enum FeatureFlag: String, CaseIterable, Sendable"))
        #expect(flagSource.contains("case newCheckoutFlowEnabled = \"new_checkout_flow_enabled\""))
        #expect(flagSource.contains("Rollout: `percent('seed') <= 50` (condition: \"fifty_percent_rollout\")"))

        let keysSourceURL = generatedDirectory.appending(path: "RemoteConfigKeys.swift")
        let keysSource = try String(contentsOf: keysSourceURL, encoding: .utf8)
        #expect(keysSource.contains("enum RemoteConfigKeys"))
        let welcomeVariantDeclaration = "static let welcomeMessageVariant = "
            + "RemoteConfigKey<String>(\"welcome_message_variant\")"
        #expect(keysSource.contains(welcomeVariantDeclaration))
        #expect(keysSource.contains("static let maxUploadSizeMb = RemoteConfigKey<Double>(\"max_upload_size_mb\")"))
    }

    @Test("strip_key_prefix removes the prefix from case names but keeps it in the raw value")
    func stripKeyPrefixAffectsOnlyCaseNames() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input:
          remote_config_json: "remoteconfig.json"
        output:
          directory: "Generated"
        bool_output:
          strip_key_prefix: "feature_flag_"
        """.write(to: workingDirectory.appending(path: "config.yml"), atomically: true, encoding: .utf8)

        try """
        {
          "parameters": {
            "feature_flag_goalsApiWrite": {
              "defaultValue": {"value": "true"},
              "valueType": "BOOLEAN"
            }
          },
          "conditions": []
        }
        """.write(to: workingDirectory.appending(path: "remoteconfig.json"), atomically: true, encoding: .utf8)

        try await GenerateRunner(workingDirectory: workingDirectory).run()

        let generatedDirectory = workingDirectory.appending(path: "Generated")
        let flagSourceURL = generatedDirectory.appending(path: "FeatureFlag.swift")
        let flagSource = try String(contentsOf: flagSourceURL, encoding: .utf8)
        #expect(flagSource.contains("case goalsApiWrite = \"feature_flag_goalsApiWrite\""))
    }

    @Test("include_key_prefix excludes bool parameters that don't match the prefix")
    func includeKeyPrefixFiltersNonMatchingBoolParameters() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input:
          remote_config_json: "remoteconfig.json"
        output:
          directory: "Generated"
        bool_output:
          include_key_prefix: "feature_flag_"
        """.write(to: workingDirectory.appending(path: "config.yml"), atomically: true, encoding: .utf8)

        try """
        {
          "parameters": {
            "feature_flag_goalsApiWrite": {
              "defaultValue": {"value": "true"},
              "valueType": "BOOLEAN"
            },
            "maintenanceModeStudyLegends": {
              "defaultValue": {"value": "false"},
              "valueType": "BOOLEAN"
            }
          },
          "conditions": []
        }
        """.write(to: workingDirectory.appending(path: "remoteconfig.json"), atomically: true, encoding: .utf8)

        try await GenerateRunner(workingDirectory: workingDirectory).run()

        let flagSourceURL = workingDirectory.appending(path: "Generated").appending(path: "FeatureFlag.swift")
        let flagSource = try String(contentsOf: flagSourceURL, encoding: .utf8)
        #expect(flagSource.contains("case featureFlagGoalsApiWrite = \"feature_flag_goalsApiWrite\""))
        #expect(!flagSource.contains("maintenanceModeStudyLegends"))
    }

    @Test("additional_keys are generated as if they were bool parameters in the template")
    func additionalKeysAreGeneratedAsBoolParameters() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input:
          remote_config_json: "remoteconfig.json"
        output:
          directory: "Generated"
        bool_output:
          strip_key_prefix: "feature_flag_"
          additional_keys: ["feature_flag_mentorInvitation"]
        """.write(to: workingDirectory.appending(path: "config.yml"), atomically: true, encoding: .utf8)

        try """
        {
          "parameters": {
            "feature_flag_goalsApiWrite": {
              "defaultValue": {"value": "true"},
              "valueType": "BOOLEAN"
            }
          },
          "conditions": []
        }
        """.write(to: workingDirectory.appending(path: "remoteconfig.json"), atomically: true, encoding: .utf8)

        try await GenerateRunner(workingDirectory: workingDirectory).run()

        let flagSourceURL = workingDirectory.appending(path: "Generated").appending(path: "FeatureFlag.swift")
        let flagSource = try String(contentsOf: flagSourceURL, encoding: .utf8)
        #expect(flagSource.contains("case mentorInvitation = \"feature_flag_mentorInvitation\""))
        #expect(flagSource.contains("case goalsApiWrite = \"feature_flag_goalsApiWrite\""))
    }

    @Test("an additional_keys entry that already exists in the template throws duplicateAdditionalKey")
    func additionalKeyDuplicatedInTemplateThrows() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input:
          remote_config_json: "remoteconfig.json"
        output:
          directory: "Generated"
        bool_output:
          additional_keys: ["feature_flag_goalsApiWrite"]
        """.write(to: workingDirectory.appending(path: "config.yml"), atomically: true, encoding: .utf8)

        try """
        {
          "parameters": {
            "feature_flag_goalsApiWrite": {
              "defaultValue": {"value": "true"},
              "valueType": "BOOLEAN"
            }
          },
          "conditions": []
        }
        """.write(to: workingDirectory.appending(path: "remoteconfig.json"), atomically: true, encoding: .utf8)

        let runner = GenerateRunner(workingDirectory: workingDirectory)
        await #expect(throws: RemoteConfigGenError.self) {
            try await runner.run()
        }
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
            "welcome_message_variant": {
              "defaultValue": {"value": "control"},
              "valueType": "STRING"
            }
          },
          "conditions": []
        }
        """.write(to: workingDirectory.appending(path: "remoteconfig.json"), atomically: true, encoding: .utf8)

        let result = try await GenerateRunner(workingDirectory: workingDirectory).run()
        #expect(result.parameterCount == 1)
        #expect(result.writtenFiles.count == 1)

        let generatedDirectory = workingDirectory.appending(path: "Generated")
        let flagPath = generatedDirectory.appending(path: "FeatureFlag.swift").path()
        let keysPath = generatedDirectory.appending(path: "RemoteConfigKeys.swift").path()
        #expect(!FileManager.default.fileExists(atPath: flagPath))
        #expect(FileManager.default.fileExists(atPath: keysPath))
    }

    @Test("reports the parameter count even when nothing is generated")
    func reportsParameterCountWhenTemplateIsEmpty() async throws {
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
          "parameters": {},
          "conditions": []
        }
        """.write(to: workingDirectory.appending(path: "remoteconfig.json"), atomically: true, encoding: .utf8)

        let result = try await GenerateRunner(workingDirectory: workingDirectory).run()
        #expect(result.parameterCount == 0)
        #expect(result.writtenFiles.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: workingDirectory.appending(path: "Generated").path()))
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
