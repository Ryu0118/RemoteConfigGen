/// BOOLEAN parameterの集まりから、enumのソースコードを1つ組み立てる。
struct BoolEnumGenerator {
    let config: GeneratorConfig
    let output: GeneratorConfig.EnumOutput

    /// `parameters`はkey名でソート済みであること（呼び出し元の`GenerateRunner`が保証する）。
    func generate(parameters: [NamedParameter], conditionExpressions: [String: String]) -> String {
        let conformances = ([output.rawValue ? "String" : nil] + output.conformances)
            .compactMap(\.self)
            .joined(separator: ", ")
        let declarationLine =
            "\(config.accessLevel.declarationPrefix)enum \(output.name): \(conformances) {"

        let members = parameters.map { parameter in
            let caseName = IdentifierNaming.camelCase(
                from: parameter.key,
                stripPrefix: output.keyPrefix,
            )
            let declaration = output.rawValue
                ? "    case \(caseName) = \"\(parameter.key)\""
                : "    case \(caseName)"
            return EnumSourceBuilder.Member(parameter: parameter, declaration: declaration)
        }

        return EnumSourceBuilder.build(
            config: config,
            declarationLine: declarationLine,
            members: members,
            conditionExpressions: conditionExpressions,
        )
    }
}
