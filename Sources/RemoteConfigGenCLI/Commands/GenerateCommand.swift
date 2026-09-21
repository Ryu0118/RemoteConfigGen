import ArgumentParser
import Foundation
import RemoteConfigGenKit

extension RemoteConfigGenCommand {
    struct GenerateCommand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "generate",
            abstract: "Read config.yml in the current directory and generate Swift bindings.",
        )

        @Option(name: .long, help: "Directory containing config.yml. Defaults to the current directory.")
        var configDirectory: String?

        func run() async throws {
            let workingDirectory = URL(filePath: configDirectory ?? FileManager.default.currentDirectoryPath)
            try await GenerateRunner(workingDirectory: workingDirectory).run()
        }
    }
}
