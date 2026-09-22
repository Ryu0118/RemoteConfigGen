@testable import RemoteConfigGenKit
import Testing

struct ConfigLoaderTests {
    private let loader = ConfigLoader()

    @Test("parses the required fields and defaults additional namespaces to empty")
    func parsesRequiredFields() throws {
        let config = try loader.parse(
            """
            input: "firebase/remoteconfig.production.json"
            output: "Generated/RemoteConfigKeys.swift"
            """,
        )

        #expect(config.input == "firebase/remoteconfig.production.json")
        #expect(config.output == "Generated/RemoteConfigKeys.swift")
        #expect(config.additionalNamespaces.isEmpty)
    }

    @Test("parses additional namespaces as a name-to-namespace map")
    func parsesAdditionalNamespaces() throws {
        let config = try loader.parse(
            """
            input: "firebase/remoteconfig.production.json"
            output: "Generated/RemoteConfigKeys.swift"
            additional_namespaces:
              CustomNamespace:
                key_prefix: "custom_"
                additional_keys: ["custom_generatedOnly"]
            """,
        )

        #expect(config.additionalNamespaces.count == 1)
        #expect(config.additionalNamespaces["CustomNamespace"] == .init(
            keyPrefix: "custom_",
            additionalKeys: ["custom_generatedOnly"],
        ))
    }

    @Test("allows a namespace without optional fields")
    func namespaceUsesDefaults() throws {
        let config = try loader.parse(
            """
            input: "a.json"
            output: "Generated/Keys.swift"
            additional_namespaces:
              AllKeys: {}
            """,
        )

        #expect(config.additionalNamespaces["AllKeys"] == .init(keyPrefix: nil, additionalKeys: []))
    }

    @Test("missing input is an error")
    func missingInputIsError() {
        #expect(throws: RemoteConfigGenError.self) {
            try loader.parse("output: Generated/Keys.swift")
        }
    }

    @Test("missing output is an error")
    func missingOutputIsError() {
        #expect(throws: RemoteConfigGenError.self) {
            try loader.parse("input: a.json")
        }
    }

    @Test("the old outputs schema is rejected because output is required")
    func oldOutputsSchemaIsRejected() {
        #expect(throws: RemoteConfigGenError.self) {
            try loader.parse(
                """
                input: "a.json"
                outputs:
                  - type: enum
                    name: Flags
                    path: Flags.swift
                """,
            )
        }
    }
}
