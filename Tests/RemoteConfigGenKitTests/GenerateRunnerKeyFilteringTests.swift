import Foundation
@testable import RemoteConfigGenKit
import Testing

struct GenerateRunnerKeyFilteringTests {
    private func makeTemporaryDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func writeFixture(
        config: String,
        template: String,
        to workingDirectory: URL,
    ) throws {
        try config.write(
            to: workingDirectory.appending(path: "remote-config-gen.yml"),
            atomically: true,
            encoding: .utf8,
        )
        try template.write(
            to: workingDirectory.appending(path: "remoteconfig.json"),
            atomically: true,
            encoding: .utf8,
        )
    }

    @Test("decodes the real firebase export shape while ignoring unrelated fields")
    func decodesRealFirebaseExportShape() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try writeFixture(
            config: """
            input: "remoteconfig.json"
            output: "Generated/RemoteConfigKeys.swift"
            """,
            template: """
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
            """,
            to: workingDirectory,
        )

        _ = try await GenerateRunner(workingDirectory: workingDirectory).run()
        let source = try String(
            contentsOf: workingDirectory.appending(path: "Generated/RemoteConfigKeys.swift"),
            encoding: .utf8,
        )
        #expect(source.contains("case newCheckoutFlowEnabled"))
    }

    @Test("a prefix removes matching keys from the default namespace")
    func prefixPartitionsDefaultKeys() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try writeFixture(
            config: """
            input: "remoteconfig.json"
            output: "Generated/RemoteConfigKeys.swift"
            additional_namespaces:
              FeatureFlag:
                key_prefix: "feature_flag_"
            """,
            template: """
            {
              "parameters": {
                "feature_flag_goalsApiWrite": {"valueType": "BOOLEAN"},
                "maintenanceModeStudyLegends": {"valueType": "BOOLEAN"}
              },
              "conditions": []
            }
            """,
            to: workingDirectory,
        )

        _ = try await GenerateRunner(workingDirectory: workingDirectory).run()
        let source = try String(
            contentsOf: workingDirectory.appending(path: "Generated/RemoteConfigKeys.swift"),
            encoding: .utf8,
        )
        #expect(source.contains("case goalsApiWrite = \"feature_flag_goalsApiWrite\""))
        #expect(source.contains("case maintenanceModeStudyLegends"))
        #expect(source.components(separatedBy: "feature_flag_goalsApiWrite").count == 2)
    }

    @Test("additional keys use the type inferred from the matching parameters")
    func additionalKeysUseInferredType() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try writeFixture(
            config: """
            input: "remoteconfig.json"
            output: "Generated/RemoteConfigKeys.swift"
            additional_namespaces:
              StringNamespace:
                key_prefix: "remote_"
                additional_keys: ["remote_buildLabel"]
            """,
            template: """
            {
              "parameters": {
                "remote_buildVersion": {"valueType": "STRING"}
              },
              "conditions": []
            }
            """,
            to: workingDirectory,
        )

        _ = try await GenerateRunner(workingDirectory: workingDirectory).run()
        let source = try String(
            contentsOf: workingDirectory.appending(path: "Generated/RemoteConfigKeys.swift"),
            encoding: .utf8,
        )
        #expect(source.contains("case buildVersion = \"remote_buildVersion\""))
        #expect(source.contains("case buildLabel = \"remote_buildLabel\""))
    }

    @Test("a namespace with no matching prefix throws")
    func noMatchingPrefixThrows() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try writeFixture(
            config: """
            input: "remoteconfig.json"
            output: "Generated/RemoteConfigKeys.swift"
            additional_namespaces:
              FeatureFlag:
                key_prefix: "feature_flag_"
            """,
            template: """
            {
              "parameters": {
                "maintenanceModeStudyLegends": {"valueType": "BOOLEAN"}
              },
              "conditions": []
            }
            """,
            to: workingDirectory,
        )

        await #expect(throws: RemoteConfigGenError.self) {
            try await GenerateRunner(workingDirectory: workingDirectory).run()
        }
    }

    @Test("a namespace containing multiple value types throws")
    func mixedValueTypesThrow() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try writeFixture(
            config: """
            input: "remoteconfig.json"
            output: "Generated/RemoteConfigKeys.swift"
            additional_namespaces:
              Mixed:
                key_prefix: "shared_"
            """,
            template: """
            {
              "parameters": {
                "shared_enabled": {"valueType": "BOOLEAN"},
                "shared_label": {"valueType": "STRING"}
              },
              "conditions": []
            }
            """,
            to: workingDirectory,
        )

        await #expect(throws: RemoteConfigGenError.self) {
            try await GenerateRunner(workingDirectory: workingDirectory).run()
        }
    }

    @Test("an additional key already present in the template throws")
    func duplicateAdditionalKeyThrows() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try writeFixture(
            config: """
            input: "remoteconfig.json"
            output: "Generated/RemoteConfigKeys.swift"
            additional_namespaces:
              FeatureFlag:
                key_prefix: "feature_flag_"
                additional_keys: ["feature_flag_goalsApiWrite"]
            """,
            template: """
            {
              "parameters": {
                "feature_flag_goalsApiWrite": {"valueType": "BOOLEAN"}
              },
              "conditions": []
            }
            """,
            to: workingDirectory,
        )

        await #expect(throws: RemoteConfigGenError.self) {
            try await GenerateRunner(workingDirectory: workingDirectory).run()
        }
    }
}
