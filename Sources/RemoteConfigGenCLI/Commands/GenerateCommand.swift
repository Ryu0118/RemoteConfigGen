import ArgumentParser
import Foundation
import Logging
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
            let logger = Logger(label: "com.ryu0118.remoteconfiggen")
            let workingDirectory = URL(filePath: configDirectory ?? FileManager.default.currentDirectoryPath)
            let result = try await GenerateRunner(workingDirectory: workingDirectory).run()

            if result.writtenFiles.isEmpty {
                let message = "Read \(result.parameterCount) parameter(s) from the Remote Config template, "
                    + "but generated no files."
                logger.warning("\(message)")
            } else {
                for file in result.writtenFiles {
                    logger.info("Generated \(file.path())")
                }
            }
        }
    }
}
