/// Bool parameterの集まりから、enumのソースコードを1つ組み立てる。
struct BoolEnumGenerator {
    let config: GeneratorConfig

    /// `parameters`はkey名でソート済みであること（呼び出し元の`GenerateRunner`が保証する）。
    func generate(parameters: [NamedParameter], conditionExpressions: [String: String]) -> String {
        let conformances = ([config.boolOutput.rawValue ? "String" : nil] + config.boolOutput.conformances)
            .compactMap(\.self)
            .joined(separator: ", ")
        let declarationLine =
            "\(config.output.accessLevel.declarationPrefix)enum \(config.boolOutput.enumName): \(conformances) {"

        let members = parameters.map { parameter in
            let caseName = IdentifierNaming.camelCase(
                from: parameter.key,
                stripPrefix: config.boolOutput.stripKeyPrefix,
            )
            let declaration = config.boolOutput.rawValue
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
