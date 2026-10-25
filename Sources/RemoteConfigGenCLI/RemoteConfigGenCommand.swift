import ArgumentParser
import RemoteConfigGenKit

/// Root command for RemoteConfigGen.
public struct RemoteConfigGenCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "remote-config-gen",
        abstract: "Generate type-safe Swift bindings from a Firebase Remote Config template.",
        version: RemoteConfigGenVersion.current,
        subcommands: [
            GenerateCommand.self,
        ],
        defaultSubcommand: GenerateCommand.self,
    )

    public init() {}
}
