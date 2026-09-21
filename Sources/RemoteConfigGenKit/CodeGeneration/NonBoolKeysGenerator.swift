/// Bool以外のparameterの集まりから、`static let`宣言をまとめたenum/namespaceのソースコードを組み立てる。
struct NonBoolKeysGenerator {
    let config: GeneratorConfig

    /// `parameters`はkey名でソート済みであること（呼び出し元の`GenerateRunner`が保証する）。
    func generate(parameters: [NamedParameter], conditionExpressions: [String: String]) -> String {
        let prefix = config.output.accessLevel.declarationPrefix

        var lines: [String] = []
        lines.append("// \(config.output.headerComment)")
        lines.append("")
        lines.append("\(prefix)enum \(config.nonBoolOutput.namespace) {")
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
            let propertyName = IdentifierNaming.camelCase(from: parameter.key)
            let keyExpression = "\(config.nonBoolOutput.keyType)<\(parameter.swiftType.typeName)>(\"\(parameter.key)\")"
            lines.append("    \(prefix)static let \(propertyName) = \(keyExpression)")
        }
        lines.append("}")
        lines.append("")
        return lines.joined(separator: "\n")
    }
}
