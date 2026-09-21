/// `BoolEnumGenerator`/`NonBoolKeysGenerator`共通の、enum宣言ソースコードの組み立て。
/// ヘッダーコメント・宣言行・member行ごとのcondition doc commentという構造だけを担い、
/// member行そのもの（`case ... = "..."` か `static let ... = ...(...)`）は呼び出し元が渡す。
enum EnumSourceBuilder {
    struct Member {
        let parameter: NamedParameter
        let declaration: String
    }

    static func build(
        config: GeneratorConfig,
        declarationLine: String,
        members: [Member],
        conditionExpressions: [String: String],
    ) -> String {
        var lines: [String] = []
        lines.append("// \(config.output.headerComment)")
        lines.append("")
        lines.append(declarationLine)
        for member in members {
            if config.documentation.includeConditionSummary {
                let conditionLines = ConditionSummary.lines(
                    conditionalValueKeys: Array(member.parameter.conditionalValueKeys),
                    conditionExpressions: conditionExpressions,
                )
                for docLine in conditionLines {
                    lines.append("    /// \(docLine)")
                }
            }
            lines.append(member.declaration)
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
