import Foundation

/// `generate`コマンドの実処理。Config読込 → Template parse → Type mapping → Code生成 →
/// ファイル書き出し、という直列ステップを順に呼ぶオーケストレーター。
public struct GenerateRunner: Sendable {
    private let workingDirectory: URL
    private let configLoader: ConfigLoader
    private let templateLoader: RemoteConfigTemplateLoader
    private let fileWriter: @Sendable (String, URL) throws -> Void

    public init(workingDirectory: URL) {
        self.init(
            workingDirectory: workingDirectory,
            configLoader: ConfigLoader(),
            templateLoader: RemoteConfigTemplateLoader(),
            fileWriter: { content, url in
                try FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true,
                )
                try content.write(to: url, atomically: true, encoding: .utf8)
            },
        )
    }

    init(
        workingDirectory: URL,
        configLoader: ConfigLoader,
        templateLoader: RemoteConfigTemplateLoader,
        fileWriter: @escaping @Sendable (String, URL) throws -> Void,
    ) {
        self.workingDirectory = workingDirectory
        self.configLoader = configLoader
        self.templateLoader = templateLoader
        self.fileWriter = fileWriter
    }

    /// config.yml読込からファイル書き出しまでを一通り実行する。
    public func run() async throws {
        let config = try configLoader.load(from: workingDirectory)
        let templatePath = workingDirectory.appending(path: config.input.remoteConfigJSON)
        let template = try templateLoader.load(from: templatePath)

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

        let outputDirectory = workingDirectory.appending(path: config.output.directory)

        if !boolParameters.isEmpty {
            let source = BoolEnumGenerator(config: config).generate(
                parameters: boolParameters,
                conditionExpressions: conditionExpressions,
            )
            try fileWriter(source, outputDirectory.appending(path: config.boolOutput.fileName))
        }

        if !nonBoolParameters.isEmpty {
            let source = NonBoolKeysGenerator(config: config).generate(
                parameters: nonBoolParameters,
                conditionExpressions: conditionExpressions,
            )
            try fileWriter(source, outputDirectory.appending(path: config.nonBoolOutput.fileName))
        }
    }
}
