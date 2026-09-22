import Foundation
@testable import RemoteConfigGenKit
import Testing

struct GenerateRunnerTests {
    private let mixedConfig = """
    input: "remoteconfig.json"
    output: "Generated/RemoteConfigKeys.swift"
    additional_namespaces:
      CustomNamespace:
        key_prefix: "custom_"
        additional_keys: ["custom_generatedOnly"]
    """

    private let mixedTemplate = """
    {
      "parameters": {
        "custom_primaryAction": {
          "defaultValue": {"value": "true"},
          "valueType": "BOOLEAN"
        },
        "custom_secondaryAction": {
          "defaultValue": {"value": "false"},
          "valueType": "BOOLEAN"
        },
        "maintenanceMode": {
          "defaultValue": {"value": "false"},
          "valueType": "BOOLEAN"
        },
        "forceUpdateVersion": {
          "defaultValue": {"value": "1.0.0"},
          "valueType": "STRING"
        },
        "fallbackVersion": {
          "defaultValue": {"value": "1.0.0"},
          "valueType": "STRING"
        },
        "maxUploadSizeMb": {
          "defaultValue": {"value": "50"},
          "valueType": "NUMBER"
        },
        "blockedWords": {
          "defaultValue": {"value": "[\\"spoiler\\"]"},
          "valueType": "JSON"
        }
      },
      "conditions": []
    }
    """

    private func makeTemporaryDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @Test("generates every value type as a nested enum and partitions additional namespaces")
    func generatesDefaultAndAdditionalNamespaces() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try mixedConfig.write(
            to: workingDirectory.appending(path: "remote-config-gen.yml"),
            atomically: true,
            encoding: .utf8,
        )

        try mixedTemplate.write(
            to: workingDirectory.appending(path: "remoteconfig.json"),
            atomically: true,
            encoding: .utf8,
        )

        let result = try await GenerateRunner(workingDirectory: workingDirectory).run()
        #expect(result.parameterCount == 7)
        #expect(result.writtenFiles.count == 1)

        let source = try String(
            contentsOf: workingDirectory.appending(path: "Generated/RemoteConfigKeys.swift"),
            encoding: .utf8,
        )

        #expect(source.contains("public enum RemoteConfigKeys {"))
        #expect(source.contains("public enum BooleanKeys: String, CaseIterable, Sendable {"))
        #expect(source.contains("case maintenanceMode"))
        #expect(source.contains("public enum StringKeys: String, CaseIterable, Sendable {"))
        #expect(source.contains("case forceUpdateVersion"))
        #expect(source.contains("public enum NumberKeys: String, CaseIterable, Sendable {"))
        #expect(source.contains("case maxUploadSizeMb"))
        #expect(source.contains("public enum JSONKeys: String, CaseIterable, Sendable {"))
        #expect(source.contains("case blockedWords"))
        #expect(source.contains("public enum CustomNamespace: String, CaseIterable, Sendable {"))
        #expect(source.contains("case primaryAction = \"custom_primaryAction\""))
        #expect(source.contains("case secondaryAction = \"custom_secondaryAction\""))
        #expect(source.contains("case generatedOnly = \"custom_generatedOnly\""))
        #expect(source.components(separatedBy: "custom_primaryAction").count == 2)
    }

    @Test("writes an empty wrapper when the template has no parameters")
    func writesEmptyWrapperForEmptyTemplate() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input: "remoteconfig.json"
        output: "Generated/RemoteConfigKeys.swift"
        """.write(
            to: workingDirectory.appending(path: "remote-config-gen.yml"),
            atomically: true,
            encoding: .utf8,
        )
        try """
        {"parameters": {}, "conditions": []}
        """.write(
            to: workingDirectory.appending(path: "remoteconfig.json"),
            atomically: true,
            encoding: .utf8,
        )

        let result = try await GenerateRunner(workingDirectory: workingDirectory).run()
        #expect(result.parameterCount == 0)
        #expect(result.writtenFiles.count == 1)
        let source = try String(
            contentsOf: workingDirectory.appending(path: "Generated/RemoteConfigKeys.swift"),
            encoding: .utf8,
        )
        #expect(source.contains("public enum RemoteConfigKeys {"))
    }

    @Test("missing remote config template throws remoteConfigTemplateNotFound")
    func missingTemplateThrows() async throws {
        let workingDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        try """
        input: "missing.json"
        output: "Generated/RemoteConfigKeys.swift"
        """.write(
            to: workingDirectory.appending(path: "remote-config-gen.yml"),
            atomically: true,
            encoding: .utf8,
        )

        await #expect(throws: RemoteConfigGenError.self) {
            try await GenerateRunner(workingDirectory: workingDirectory).run()
        }
    }
}
