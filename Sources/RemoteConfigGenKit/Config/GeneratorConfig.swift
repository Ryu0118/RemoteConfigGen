/// `remote-config-gen.yml`の内容を表す設定。
public struct GeneratorConfig: Equatable, Sendable {
    /// Remote Configテンプレートexport JSONへの、config基準の相対パス。
    public var input: String
    /// 生成するSwiftファイルの、config基準の相対パス。
    public var output: String
    /// default namespaceから切り出して生成する追加namespaceの設定。
    public var additionalNamespaces: [String: NamespaceConfig]

    public init(
        input: String,
        output: String,
        additionalNamespaces: [String: NamespaceConfig] = [:],
    ) {
        self.input = input
        self.output = output
        self.additionalNamespaces = additionalNamespaces
    }
}

public extension GeneratorConfig {
    /// default namespaceからkeyを切り出すための追加namespace設定。
    struct NamespaceConfig: Equatable, Sendable {
        /// 切り出すkeyのprefix。`nil`なら全parameterが対象になる。
        public var keyPrefix: String?
        /// Remote Configテンプレートに存在しないがnamespaceへ含めるkey。
        public var additionalKeys: [String]

        public init(keyPrefix: String? = nil, additionalKeys: [String] = []) {
            self.keyPrefix = keyPrefix
            self.additionalKeys = additionalKeys
        }
    }
}
