import Foundation

/// エラー全般を表す型。原因と対処法を1文で説明する。
public enum RemoteConfigGenError: Error, LocalizedError, Sendable {
    case configNotFound(directory: URL)
    case invalidConfig(reason: String)
    case remoteConfigTemplateNotFound(path: URL)
    case invalidRemoteConfigTemplate(reason: String)
    case writeFailed(path: URL)
    case duplicateAdditionalKey(key: String)
    case additionalNamespaceHasNoMatchingKeys(namespace: String, keyPrefix: String?)
    case additionalNamespaceHasMixedValueTypes(namespace: String)
    case additionalNamespaceOverlaps(namespace: String, key: String)

    /// 原因と対処法を1文で説明するメッセージ。
    public var errorDescription: String? {
        switch self {
        case let .configNotFound(directory):
            return "No remote-config-gen.yml found in \(directory.path()). Create one with `input` and `output`."
        case let .invalidConfig(reason):
            return "remote-config-gen.yml is invalid: \(reason)"
        case let .remoteConfigTemplateNotFound(path):
            return "Remote Config template not found at \(path.path()). Check remote-config-gen.yml's `input` path, "
                + "or run `firebase remoteconfig:get` to fetch a fresh template."
        case let .invalidRemoteConfigTemplate(reason):
            return "Remote Config template is invalid: \(reason)"
        case let .writeFailed(path):
            return "Failed to write generated code to \(path.path()). Check that the output directory is writable."
        case let .duplicateAdditionalKey(key):
            return "An `additional_keys` entry contains \"\(key)\", but that key already exists in the "
                + "Remote Config template."
        case let .additionalNamespaceHasNoMatchingKeys(namespace, keyPrefix):
            let prefix = keyPrefix.map { " with key_prefix \"\($0)\"" } ?? ""
            return "Additional namespace \"\(namespace)\"\(prefix) has no matching Remote Config parameters."
        case let .additionalNamespaceHasMixedValueTypes(namespace):
            return "Additional namespace \"\(namespace)\" matches parameters with multiple value types."
        case let .additionalNamespaceOverlaps(namespace, key):
            return "Additional namespace \"\(namespace)\" overlaps another namespace at key \"\(key)\"."
        }
    }
}
