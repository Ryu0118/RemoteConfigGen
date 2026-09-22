/// BOOLEAN以外のparameterの集まりから、`static let`宣言をまとめたenum/namespaceのソースコードを組み立てる。
struct NonBoolKeysGenerator {
    let config: GeneratorConfig
    let output: GeneratorConfig.KeysOutput

    /// `parameters`はkey名でソート済みであること（呼び出し元の`GenerateRunner`が保証する）。
    func generate(parameters: [NamedParameter], conditionExpressions: [String: String]) -> String {
        let prefix = config.accessLevel.declarationPrefix
        let declarationLine = "\(prefix)enum \(output.namespace) {"

        let members = parameters.map { parameter in
            let propertyName = IdentifierNaming.camelCase(from: parameter.key)
            let keyExpression = "\(output.keyType)<\(parameter.swiftType.typeName)>(\"\(parameter.key)\")"
            let declaration = "    \(prefix)static let \(propertyName) = \(keyExpression)"
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
