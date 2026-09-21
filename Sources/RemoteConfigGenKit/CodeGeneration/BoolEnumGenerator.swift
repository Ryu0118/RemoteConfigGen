/// Bool parameterの集まりから、enumのソースコードを1つ組み立てる。
struct BoolEnumGenerator {
    let config: GeneratorConfig

    /// `parameters`はkey名でソート済みであること（呼び出し元の`GenerateRunner`が保証する）。
    func generate(parameters: [NamedParameter], conditionExpressions: [String: String]) -> String {
        let conformances = ([config.boolOutput.rawValue ? "String" : nil] + config.boolOutput.conformances)
            .compactMap(\.self)
            .joined(separator: ", ")

        var lines: [String] = []
        lines.append("// \(config.output.headerComment)")
        lines.append("")
        lines.append(
            "\(config.output.accessLevel.declarationPrefix)enum \(config.boolOutput.enumName): \(conformances) {",
        )
        for parameter in parameters {
            let conditionLines = config.documentation.includeConditionSummary
                ? ConditionSummary.lines(
                    conditionalValueKeys: Array(parameter.conditionalValueKeys),
                    conditionExpressions: conditionExpressions,
                )
                : []
            for docLine in conditionLines {
                lines.append("    /// \(docLine)")
            }
            let caseName = IdentifierNaming.camelCase(from: parameter.key)
            if config.boolOutput.rawValue {
                lines.append("    case \(caseName) = \"\(parameter.key)\"")
            } else {
                lines.append("    case \(caseName)")
            }
        }
        lines.append("}")
        lines.append("")
        return lines.joined(separator: "\n")
    }
}

extension GeneratorConfig.AccessLevel {
    /// 宣言の先頭に置く文字列。`internal`は明示不要なので空文字（末尾スペース無し）。
    var declarationPrefix: String {
        switch self {
        case .public: "public "
        case .package: "package "
        case .internal: ""
        }
    }
}
