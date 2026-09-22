import Foundation

/// エラー全般を表す型。原因と対処法を1文で説明する。
public enum RemoteConfigGenError: Error, LocalizedError, Sendable {
    case configNotFound(directory: URL)
    case invalidConfig(reason: String)
    case remoteConfigTemplateNotFound(path: URL)
    case invalidRemoteConfigTemplate(reason: String)
    case writeFailed(path: URL)
    case duplicateAdditionalKey(key: String)

    /// 原因と対処法を1文で説明するメッセージ。
    public var errorDescription: String? {
        switch self {
        case let .configNotFound(directory):
            "No remote-config-gen.yml found in \(directory.path()). Create one with an `input` path and "
                + "at least one entry under `outputs`, or pass --config to point at the file directly."
        case let .invalidConfig(reason):
            "remote-config-gen.yml is invalid: \(reason)"
        case let .remoteConfigTemplateNotFound(path):
            "Remote Config template not found at \(path.path()). Check remote-config-gen.yml's `input` path, "
                + "or run `firebase remoteconfig:get` to fetch a fresh template."
        case let .invalidRemoteConfigTemplate(reason):
            "Remote Config template is invalid: \(reason)"
        case let .writeFailed(path):
            "Failed to write generated code to \(path.path()). Check that the output directory is writable."
        case let .duplicateAdditionalKey(key):
            "An `enum` output's `additional_keys` contains \"\(key)\", but that key already exists in the "
                + "Remote Config template. Remove it from `additional_keys` now that it's managed by Remote Config."
        }
    }
}
