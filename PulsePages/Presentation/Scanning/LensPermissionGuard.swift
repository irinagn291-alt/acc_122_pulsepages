import AVFoundation
import VisionKit

enum LensPermissionGuard {
    enum Gate: Equatable {
        case checking
        case ready
        case denied
        case unsupported
    }

    @MainActor
    static var scannerSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    @MainActor
    static func resolveGate() async -> Gate {
        guard scannerSupported else { return .unsupported }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .ready
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .ready : .denied
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }
}
