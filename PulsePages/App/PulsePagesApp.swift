import SwiftUI

@main
struct PulsePagesApp: App {
    @StateObject private var container = PulseContainer()

    var body: some Scene {
        WindowGroup {
            PulseRootView()
                .environmentObject(container)
        }
    }
}
