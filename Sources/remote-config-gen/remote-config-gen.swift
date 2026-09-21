import Logging
import RemoteConfigGenCLI

@main
struct RemoteConfigGen {
    static func main() async throws {
        LoggingSystem.bootstrap(StreamLogHandler.standardOutput)
        await RemoteConfigGenCommand.main()
    }
}
