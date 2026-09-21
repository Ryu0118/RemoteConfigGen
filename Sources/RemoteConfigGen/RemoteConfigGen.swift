import RemoteConfigGenCLI

@main
struct RemoteConfigGen {
    static func main() async throws {
        await RemoteConfigGenCommand.main()
    }
}
