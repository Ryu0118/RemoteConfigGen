/// parameterが持つconditionalValuesを、doc commentへ焼き込むための説明行へ変換する。
/// 値の分岐ロジック自体は実装しない（実行時判定はFirebase SDKに任せる）。
enum ConditionSummary {
    /// `conditionName -> expression` の対応表と、parameterが参照するcondition名から、
    /// doc commentの行（"Rollout: ..." 形式）を組み立てる。参照するconditionが無ければ`nil`。
    static func lines(
        conditionalValueKeys: [String],
        conditionExpressions: [String: String],
    ) -> [String] {
        conditionalValueKeys.sorted().map { name in
            if let expression = conditionExpressions[name] {
                "Rollout: `\(expression)` (condition: \"\(name)\")"
            } else {
                "Rollout: condition \"\(name)\""
            }
        }
    }
}
