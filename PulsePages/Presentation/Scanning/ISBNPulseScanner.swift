import SwiftUI
import UIKit
import VisionKit
import AVFoundation

enum ISBNNormalizer {
    static func digits(from raw: String) -> String? {
        let d = raw.filter(\.isNumber)
        guard !d.isEmpty else { return nil }
        if d.count >= 13 { return String(d.prefix(13)) }
        if d.count == 10 { return d }
        return nil
    }
}

struct ISBNPulseScanner: View {
    @Binding var isPresented: Bool
    var onDigits: (String) -> Void
    @State private var gate: LensPermissionGuard.Gate = .checking

    var body: some View {
        Group {
            switch gate {
            case .checking:
                PulseSpinner("Opening lens…")
            case .ready:
                PulseScannerBridge(onDigits: { digits in
                    isPresented = false
                    onDigits(digits)
                })
                .ignoresSafeArea()
            case .denied:
                ContentUnavailableView(
                    "Camera access needed",
                    systemImage: "camera.fill",
                    description: Text("Allow camera access in Settings to scan ISBN barcodes.")
                )
            case .unsupported:
                ContentUnavailableView(
                    "ISBN Scanner",
                    systemImage: "barcode.viewfinder",
                    description: Text("ISBN scanning requires a supported iPhone with a working camera.")
                )
            }
        }
        .navigationTitle("Scan ISBN")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { isPresented = false }
            }
        }
        .task { gate = await LensPermissionGuard.resolveGate() }
    }
}

private struct PulseScannerBridge: UIViewControllerRepresentable {
    var onDigits: (String) -> Void

    func makeCoordinator() -> Coord { Coord(onDigits: onDigits) }

    func makeUIViewController(context: Context) -> PulseScannerHost {
        PulseScannerHost(coordinator: context.coordinator)
    }

    func updateUIViewController(_ uiViewController: PulseScannerHost, context: Context) {}

    final class Coord {
        let onDigits: (String) -> Void
        private var last = Date.distantPast
        init(onDigits: @escaping (String) -> Void) { self.onDigits = onDigits }
        func ingest(_ items: [RecognizedItem]) {
            for item in items {
                guard case .barcode(let b) = item, let raw = b.payloadStringValue,
                      let digits = ISBNNormalizer.digits(from: raw) else { continue }
                let now = Date()
                guard now.timeIntervalSince(last) > 0.55 else { continue }
                last = now; onDigits(digits); return
            }
        }
    }

    final class PulseScannerHost: UIViewController {
        private let coordinator: Coord
        private var scanner: DataScannerViewController?
        private var stream: Task<Void, Never>?

        init(coordinator: Coord) { self.coordinator = coordinator; super.init(nibName: nil, bundle: nil) }
        @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
        deinit { stream?.cancel() }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = UIColor(red: 0.102, green: 0.063, blue: 0.157, alpha: 1)
            guard LensPermissionGuard.scannerSupported else { return }
            let types: Set<DataScannerViewController.RecognizedDataType> = [
                .barcode(symbologies: [.ean13, .ean8, .code128]),
            ]
            let sc = DataScannerViewController(
                recognizedDataTypes: types, qualityLevel: .balanced,
                recognizesMultipleItems: false, isHighFrameRateTrackingEnabled: true, isHighlightingEnabled: true
            )
            scanner = sc
            addChild(sc)
            sc.view.frame = view.bounds
            sc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(sc.view)
            sc.didMove(toParent: self)
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard let scanner, AVCaptureDevice.authorizationStatus(for: .video) == .authorized else { return }
            do {
                try scanner.startScanning()
            } catch {
                return
            }
            stream?.cancel()
            stream = Task { @MainActor [weak self] in
                guard let self, let scanner = self.scanner else { return }
                for await items in scanner.recognizedItems {
                    if Task.isCancelled { break }
                    self.coordinator.ingest(items)
                }
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            stream?.cancel(); stream = nil
            try? scanner?.stopScanning()
        }
    }
}
