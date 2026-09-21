import Foundation

/// `remote_config_json` で指定されたパスから `RemoteConfigTemplate` を読み込む。
public struct RemoteConfigTemplateLoader: Sendable {
    public init() {}

    /// 指定したパスからRemote Configテンプレートを読み込む。ファイルが無ければ `.remoteConfigTemplateNotFound` を投げる。
    public func load(from path: URL) throws -> RemoteConfigTemplate {
        guard let data = FileManager.default.contents(atPath: path.path()) else {
            throw RemoteConfigGenError.remoteConfigTemplateNotFound(path: path)
        }
        do {
            return try JSONDecoder().decode(RemoteConfigTemplate.self, from: data)
        } catch {
            throw RemoteConfigGenError.invalidRemoteConfigTemplate(reason: error.localizedDescription)
        }
    }
}
