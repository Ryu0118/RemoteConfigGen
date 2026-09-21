/// コード生成時に扱いやすい形へ正規化した、1 parameter分の情報。
struct NamedParameter {
    let key: String
    let swiftType: SwiftType
    let conditionalValueKeys: [String]

    init(key: String, swiftType: SwiftType, conditionalValueKeys: [String] = []) {
        self.key = key
        self.swiftType = swiftType
        self.conditionalValueKeys = conditionalValueKeys
    }
}
