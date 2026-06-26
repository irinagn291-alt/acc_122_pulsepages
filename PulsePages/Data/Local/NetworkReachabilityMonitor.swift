import Foundation
import Network

@MainActor
final class NetworkReachabilityMonitor: ReachabilityGateway, ObservableObject {
    @Published private(set) var isOffline = false
    private let monitor = NWPathMonitor()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in self?.isOffline = path.status != .satisfied }
        }
        monitor.start(queue: DispatchQueue(label: "io.readpulse.pages.reachability"))
    }
}
