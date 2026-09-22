import Foundation
@testable import RemoteConfigGenKit
import Testing

struct GenerateRunnerTests {
    private func makeTemporaryDirectory() -> URL {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("generates a bool enum and a keys namespace from a mixed template")
    func generatesMixedTemplate() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input: "remoteconfig.json"
        outputs:
          - type: "enum"
            name: "FeatureFlag"
            path: "Generated/FeatureFlag.swift"
          - type: "keys"
            path: "Generated/RemoteConfigKeys.swift"
        """.write(to: workingDirectory.appending(path: "remote-config-gen.yml"), atomically: true, encoding: .utf8)

        try """
        {
          "parameters": {
            "new_checkout_flow_enabled": {
              "defaultValue": {"value": "true"},
              "valueType": "BOOLEAN",
              "conditionalValues": {
                "fifty_percent_rollout": {"value": "false"}
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

        let flagSourceURL = workingDirectory.appending(path: "Generated/FeatureFlag.swift")
        let flagSource = try String(contentsOf: flagSourceURL, encoding: .utf8)
        #expect(flagSource.contains("enum FeatureFlag: String, CaseIterable, Sendable"))
        #expect(flagSource.contains("case newCheckoutFlowEnabled = \"new_checkout_flow_enabled\""))
        #expect(flagSource.contains("Rollout: `percent('seed') <= 50` (condition: \"fifty_percent_rollout\")"))

        let keysSourceURL = workingDirectory.appending(path: "Generated/RemoteConfigKeys.swift")
        let keysSource = try String(contentsOf: keysSourceURL, encoding: .utf8)
        #expect(keysSource.contains("enum RemoteConfigKeys"))
        let welcomeVariantDeclaration = "static let welcomeMessageVariant = "
            + "RemoteConfigKey<String>(\"welcome_message_variant\")"
        #expect(keysSource.contains(welcomeVariantDeclaration))
        #expect(keysSource.contains("static let maxUploadSizeMb = RemoteConfigKey<Double>(\"max_upload_size_mb\")"))
    }

    @Test("key_prefix removes the prefix from case names but keeps it in the raw value")
    func keyPrefixAffectsOnlyCaseNames() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input: "remoteconfig.json"
        outputs:
          - type: "enum"
            name: "FeatureFlag"
            key_prefix: "feature_flag_"
            path: "Generated/FeatureFlag.swift"
        """.write(to: workingDirectory.appending(path: "remote-config-gen.yml"), atomically: true, encoding: .utf8)

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

        let flagSourceURL = workingDirectory.appending(path: "Generated/FeatureFlag.swift")
        let flagSource = try String(contentsOf: flagSourceURL, encoding: .utf8)
        #expect(flagSource.contains("case goalsApiWrite = \"feature_flag_goalsApiWrite\""))
    }

    @Test("omits an output entirely when no matching parameters exist")
    func omitsOutputWhenNoMatchingParameters() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input: "remoteconfig.json"
        outputs:
          - type: "enum"
            name: "FeatureFlag"
            path: "Generated/FeatureFlag.swift"
          - type: "keys"
            path: "Generated/RemoteConfigKeys.swift"
        """.write(to: workingDirectory.appending(path: "remote-config-gen.yml"), atomically: true, encoding: .utf8)

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

        let flagPath = workingDirectory.appending(path: "Generated/FeatureFlag.swift").path()
        let keysPath = workingDirectory.appending(path: "Generated/RemoteConfigKeys.swift").path()
        #expect(!FileManager.default.fileExists(atPath: flagPath))
        #expect(FileManager.default.fileExists(atPath: keysPath))
    }

    @Test("an empty outputs list generates nothing but still reports the parameter count")
    func emptyOutputsGeneratesNothing() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input: "remoteconfig.json"
        """.write(to: workingDirectory.appending(path: "remote-config-gen.yml"), atomically: true, encoding: .utf8)

        try """
        {
          "parameters": {},
          "conditions": []
        }
        """.write(to: workingDirectory.appending(path: "remoteconfig.json"), atomically: true, encoding: .utf8)

        let result = try await GenerateRunner(workingDirectory: workingDirectory).run()
        #expect(result.parameterCount == 0)
        #expect(result.writtenFiles.isEmpty)
    }

    @Test("missing remote config template throws remoteConfigTemplateNotFound")
    func missingTemplateThrows() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input: "missing.json"
        """.write(to: workingDirectory.appending(path: "remote-config-gen.yml"), atomically: true, encoding: .utf8)

        let runner = GenerateRunner(workingDirectory: workingDirectory)

        await #expect(throws: RemoteConfigGenError.self) {
            try await runner.run()
        }
    }
}
