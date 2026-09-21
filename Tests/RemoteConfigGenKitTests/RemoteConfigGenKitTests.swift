@testable import RemoteConfigGenKit
import Testing

struct RemoteConfigGenKitTests {
    @Test("returns the starter greeting")
    func greeting() {
        #expect(RemoteConfigGenKit.greeting() == "Hello from RemoteConfigGen")
    }
}
