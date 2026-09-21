import Foundation

/// エラー全般を表す型。原因と対処法を1文で説明する。
public enum RemoteConfigGenError: Error, LocalizedError, Sendable {
    case configNotFound(directory: URL)
    case invalidConfig(reason: String)
    case remoteConfigTemplateNotFound(path: URL)
    case invalidRemoteConfigTemplate(reason: String)
    case writeFailed(path: URL)

    /// 原因と対処法を1文で説明するメッセージ。
    public var errorDescription: String? {
        switch self {
        case let .configNotFound(directory):
            "No config.yml found in \(directory.path()). Create one with an `input.remote_config_json` and "
                + "`output.directory` key, or pass --config-directory to point at the directory that contains it."
        case let .invalidConfig(reason):
            "config.yml is invalid: \(reason)"
        case let .remoteConfigTemplateNotFound(path):
            "Remote Config template not found at \(path.path()). Check config.yml's `input.remote_config_json` "
                + "path, or run `firebase remoteconfig:get` to fetch a fresh template."
        case let .invalidRemoteConfigTemplate(reason):
            "Remote Config template is invalid: \(reason)"
        case let .writeFailed(path):
            "Failed to write generated code to \(path.path()). Check that the output directory is writable."
        }
    }
}
