#if os(iOS)
import AVFoundation
import Combine

@MainActor
final class CameraSession: NSObject, ObservableObject {
    let session = AVCaptureSession()

    @Published private(set) var isConfigured = false
    @Published var errorMessage: String?

    func requestAccessAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted {
                        self?.configureAndStart()
                    } else {
                        self?.errorMessage = "Camera access denied."
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = "Camera access denied. Enable it in Settings → Privacy → Camera."
        @unknown default:
            errorMessage = "Unknown camera authorization state."
        }
    }

    private func configureAndStart() {
        session.beginConfiguration()
        session.sessionPreset = .high

        do {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                errorMessage = "No rear camera found."
                session.commitConfiguration()
                return
            }
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                errorMessage = "Could not add camera input."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        session.commitConfiguration()
        isConfigured = true

        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.startRunning()
        }
    }

    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.stopRunning()
        }
    }
}
#endif
