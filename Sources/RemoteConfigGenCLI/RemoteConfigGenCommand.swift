import ArgumentParser
import RemoteConfigGenKit

/// RemoteConfigGenのルートコマンド。
public struct RemoteConfigGenCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "RemoteConfigGen",
        abstract: "Generate type-safe Swift bindings from a Firebase Remote Config template.",
        version: RemoteConfigGenVersion.current,
        subcommands: [
            GenerateCommand.self,
        ],
        defaultSubcommand: GenerateCommand.self,
    )

    public init() {}
}
