#if os(iOS)
import Combine
import CoreMotion
import Foundation

final class DeviceMotionOverlay: ObservableObject {
    private let motion = CMMotionManager()

    @Published var offset: CGSize = .zero

    @Published var directionRotationDegrees: Double = 0

    func start() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 45.0
        motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] data, _ in
            guard let attitude = data?.attitude else { return }
            let x = CGFloat(attitude.roll) * 95
            let y = CGFloat(attitude.pitch) * 78
            self?.offset = CGSize(width: x, height: y)
            self?.directionRotationDegrees = attitude.roll * (180.0 / .pi) * 0.35
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
    }
}
#endif
