import Foundation
@testable import RemoteConfigGenKit
import Testing

struct GenerateRunnerKeyFilteringTests {
    private func makeTemporaryDirectory() -> URL {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("decodes the real firebase remoteconfig:get export shape, including fields RemoteConfigGen ignores")
    func decodesRealFirebaseExportShape() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input:
          remote_config_json: "remoteconfig.json"
        output:
          directory: "Generated"
        """.write(to: workingDirectory.appending(path: "config.yml"), atomically: true, encoding: .utf8)

        // `firebase remoteconfig:get`が実際に吐く形。conditionalValuesは defaultValue と同じ
        // フラットな{"value": "..."} / {"useInAppDefault": true}形式で、RemoteConfigConditionalValueの
        // ような追加のネストは存在しない。description/tagColorはRemoteConfigGenが使わない余剰フィールド。
        try """
        {
          "parameters": {
            "new_checkout_flow_enabled": {
              "defaultValue": {"value": "true"},
              "conditionalValues": {
                "fifty_percent_rollout": {"value": "false"},
                "fallback_to_app_default": {"useInAppDefault": true}
              },
              "description": "Gradual rollout flag.",
              "valueType": "BOOLEAN"
            }
          },
          "conditions": [
            {"name": "fifty_percent_rollout", "expression": "percent('seed') <= 50", "tagColor": "BLUE"}
          ]
        }
        """.write(to: workingDirectory.appending(path: "remoteconfig.json"), atomically: true, encoding: .utf8)

        let result = try await GenerateRunner(workingDirectory: workingDirectory).run()
        #expect(result.parameterCount == 1)

        let flagSourceURL = workingDirectory.appending(path: "Generated").appending(path: "FeatureFlag.swift")
        let flagSource = try String(contentsOf: flagSourceURL, encoding: .utf8)
        #expect(flagSource.contains("case newCheckoutFlowEnabled = \"new_checkout_flow_enabled\""))
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
}
