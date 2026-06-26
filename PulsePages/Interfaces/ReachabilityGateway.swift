import Foundation

@MainActor
protocol ReachabilityGateway: AnyObject, ObservableObject {
    var isOffline: Bool { get }
}
