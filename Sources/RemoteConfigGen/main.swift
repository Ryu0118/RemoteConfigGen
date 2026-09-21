import RemoteConfigGenKit

@main
struct RemoteConfigGenMain {
    static func main() {
        if CommandLine.arguments.dropFirst().contains("--version") {
            print(RemoteConfigGenVersion.current)
            return
        }
        print(RemoteConfigGenKit.greeting())
    }
}
