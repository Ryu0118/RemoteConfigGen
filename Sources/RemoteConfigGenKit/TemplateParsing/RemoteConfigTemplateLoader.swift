import FileManagerProtocol
import Foundation

/// Loads a `RemoteConfigTemplate` from a file path.
public struct RemoteConfigTemplateLoader: Sendable {
    private let fileManager: any FileManagerProtocol

    public init(fileManager: some FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }

    /// Loads the template at `path`. Throws `.remoteConfigTemplateNotFound` when the file is missing.
    public func load(from path: URL) throws -> RemoteConfigTemplate {
        guard let data = fileManager.contents(atPath: path.path()) else {
            throw RemoteConfigGenError.remoteConfigTemplateNotFound(path: path)
        }
        do {
            return try JSONDecoder().decode(RemoteConfigTemplate.self, from: data)
        } catch {
            throw RemoteConfigGenError.invalidRemoteConfigTemplate(reason: error.localizedDescription)
        }
    }
}
