import Foundation

/// `generate`コマンドの実処理。Config読込 → Template parse → Type mapping → Code生成 →
/// ファイル書き出し、という直列ステップを順に呼ぶオーケストレーター。
public struct GenerateRunner: Sendable {
    private let workingDirectory: URL
    private let configLoader = ConfigLoader()
    private let templateLoader = RemoteConfigTemplateLoader()

    public init(workingDirectory: URL) {
        self.workingDirectory = workingDirectory
    }

    /// config.yml読込からファイル書き出しまでを一通り実行し、書き出したファイルのURLを返す。
    @discardableResult
    public func run() async throws -> [URL] {
        let config = try configLoader.load(from: workingDirectory)
        let templatePath = workingDirectory.appending(path: config.input.remoteConfigJSON)
        let template = try templateLoader.load(from: templatePath)

        let generatedFiles = generatedFiles(from: template, config: config)

        let outputDirectory = workingDirectory.appending(path: config.output.directory)
        for file in generatedFiles {
            let destination = outputDirectory.appending(path: file.fileName)
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true,
            )
            try file.source.write(to: destination, atomically: true, encoding: .utf8)
        }

        return generatedFiles.map { outputDirectory.appending(path: $0.fileName) }
    }

    /// config.ymlとRemote Configテンプレートから、書き出すべき生成コードを計算する（ファイルI/Oは行わない）。
    private func generatedFiles(
        from template: RemoteConfigTemplate,
        config: GeneratorConfig,
    ) -> [(fileName: String, source: String)] {
        let typeMapper = TypeMapper(config: config)
        let conditionExpressions = Dictionary(
            uniqueKeysWithValues: template.conditions.map { ($0.name, $0.expression) },
        )

        var boolParameters: [NamedParameter] = []
        var nonBoolParameters: [NamedParameter] = []
        for (key, parameter) in template.parameters.sorted(by: { $0.key < $1.key }) {
            let swiftType = typeMapper.swiftType(for: parameter.valueType)
            let named = NamedParameter(
                key: key,
                swiftType: swiftType,
                conditionalValueKeys: Array(parameter.conditionalValues.keys),
            )
            if swiftType == .bool {
                boolParameters.append(named)
            } else {
                nonBoolParameters.append(named)
            }
        }

        var result: [(fileName: String, source: String)] = []

        if !boolParameters.isEmpty {
            let source = BoolEnumGenerator(config: config).generate(
                parameters: boolParameters,
                conditionExpressions: conditionExpressions,
            )
            result.append((config.boolOutput.resolvedFileName, source))
        }

        if !nonBoolParameters.isEmpty {
            let source = NonBoolKeysGenerator(config: config).generate(
                parameters: nonBoolParameters,
                conditionExpressions: conditionExpressions,
            )
            result.append((config.nonBoolOutput.resolvedFileName, source))
        }

        return result
    }
}
