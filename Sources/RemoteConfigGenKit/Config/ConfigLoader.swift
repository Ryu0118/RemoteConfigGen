import FileManagerProtocol
import Foundation
import Yams

/// カレントディレクトリの `remote-config-gen.yml` を読み込み `GeneratorConfig` へ変換する。
public struct ConfigLoader: Sendable {
    private let fileManager: any FileManagerProtocol

    public init(fileManager: some FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }

    /// `directory/remote-config-gen.yml`を読み込む。
    public func load(from directory: URL) throws -> GeneratorConfig {
        let configPath = directory.appending(path: "remote-config-gen.yml")
        guard let data = fileManager.contents(atPath: configPath.path()) else {
            throw RemoteConfigGenError.configNotFound(directory: directory)
        }
        guard let yamlString = String(data: data, encoding: .utf8) else {
            throw RemoteConfigGenError.invalidConfig(reason: "remote-config-gen.yml is not valid UTF-8.")
        }
        return try parse(yamlString)
    }

    func parse(_ yamlString: String) throws -> GeneratorConfig {
        let raw = try decode(yamlString)
        guard let input = raw.input, !input.isEmpty else {
            throw RemoteConfigGenError.invalidConfig(reason: "`input` is required.")
        }
        guard let output = raw.output, !output.isEmpty else {
            throw RemoteConfigGenError.invalidConfig(reason: "`output` is required.")
        }

        let additionalNamespaces = (raw.additionalNamespaces ?? [:]).mapValues { rawNamespace in
            GeneratorConfig.NamespaceConfig(
                keyPrefix: rawNamespace.keyPrefix,
                additionalKeys: rawNamespace.additionalKeys ?? [],
            )
        }
        return GeneratorConfig(
            input: input,
            output: output,
            additionalNamespaces: additionalNamespaces,
        )
    }

    private func decode(_ yamlString: String) throws -> RawConfig {
        do {
            return try YAMLDecoder().decode(RawConfig.self, from: yamlString)
        } catch {
            throw RemoteConfigGenError.invalidConfig(reason: error.localizedDescription)
        }
    }
}
