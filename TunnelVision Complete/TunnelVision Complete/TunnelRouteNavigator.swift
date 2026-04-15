#if os(iOS)
import Combine
import CoreLocation
import Foundation
import simd
import UIKit

// MARK: - Geo / vector helpers

private func bearingDegrees(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
    let φ1 = from.latitude * .pi / 180
    let φ2 = to.latitude * .pi / 180
    let Δλ = (to.longitude - from.longitude) * .pi / 180
    let y = sin(Δλ) * cos(φ2)
    let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)
    let θ = atan2(y, x) * 180 / .pi
    var b = θ.truncatingRemainder(dividingBy: 360)
    if b < 0 { b += 360 }
    return b
}

private func distanceMeters(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
    CLLocation(latitude: from.latitude, longitude: from.longitude)
        .distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
}

private func shortestAngleDegrees(_ a: Double, _ b: Double) -> Double {
    var d = b - a
    while d > 180 { d -= 360 }
    while d < -180 { d += 360 }
    return d
}

private func bearingToWorldUnit(_ bearingDeg: Double) -> SIMD2<Float> {
    let rad = Float(bearingDeg * .pi / 180)
    return SIMD2<Float>(sin(rad), -cos(rad))
}

// MARK: - Navigator (shared waypoints + ARKit visual odometry)

@MainActor
final class TunnelRouteNavigator: NSObject, ObservableObject {

    // UI state
    @Published var arrowRotationDegrees: Double = 0
    @Published var primaryInstruction: String = "Follow the route"
    @Published var currentDirection: Direction = .straight
    @Published var distanceToNextWaypoint: Double = 0
    @Published var currentLegIndex: Int = 0
    @Published var totalLegs: Int = 0
    @Published var arrived: Bool = false
    @Published var isWrongDirection: Bool = false

    // AR tracker (injected)
    private var tracker: ARPositionTracker?

    // Sync to shared NavigationViewModel (owns pedometer + step index)
    weak var navigationViewModel: NavigationViewModel?

    // Route geometry for AR arrow rotation
    private let geoWaypoints: [CLLocationCoordinate2D]
    private let legInstructions: [String]
    private var legDistances: [Double] = []

    private var distanceWalkedThisLeg: Double = 0
    private var deviceHeadingDegrees: Double?
    private let arrivalThresholdMeters: Double = 3.0

    private var stepObserver: AnyCancellable?

    init(route: TunnelRoute = DemoRoutes.hciToElevators) {
        self.geoWaypoints = route.waypoints
        self.legInstructions = route.legInstructions
        super.init()
        precondition(geoWaypoints.count >= 2)
        totalLegs = geoWaypoints.count - 1
        buildLegDistances()
    }

    func start(tracker: ARPositionTracker) {
        self.tracker = tracker
        arrived = false
        distanceWalkedThisLeg = 0

        syncFromViewModel()
        updateDistanceToWaypoint()

        tracker.onDisplacement = { [weak self] displacement in
            self?.handleDisplacement(displacement)
        }

        stepObserver = navigationViewModel?.$currentStepIndex
            .receive(on: RunLoop.main)
            .sink { [weak self] newIndex in
                self?.handleViewModelStepChange(newIndex)
            }

        recomputeUI()
    }

    func stop() {
        tracker?.onDisplacement = nil
        stepObserver?.cancel()
        stepObserver = nil
        tracker = nil
    }

    func updateDeviceHeadingDegrees(_ degrees: Double?) {
        deviceHeadingDegrees = degrees
        recomputeUI()
    }

    var sessionSteps: Int {
        navigationViewModel?.stepCount ?? 0
    }

    // MARK: - Sync from NavigationViewModel

    private func syncFromViewModel() {
        guard let vm = navigationViewModel else { return }
        let vmStep = vm.currentStepIndex
        let mapped = min(vmStep, totalLegs - 1)
        if mapped != currentLegIndex {
            currentLegIndex = mapped
            distanceWalkedThisLeg = 0
            updateDistanceToWaypoint()
        }
        arrived = vm.arrived
    }

    private func handleViewModelStepChange(_ newIndex: Int) {
        let mapped = min(newIndex, totalLegs - 1)
        if mapped != currentLegIndex {
            currentLegIndex = mapped
            distanceWalkedThisLeg = 0
            updateDistanceToWaypoint()
        }
        if let vm = navigationViewModel, vm.arrived {
            arrived = true
        }
        recomputeUI()
    }

    // MARK: - ARKit displacement

    private func handleDisplacement(_ displacement: SIMD2<Float>) {
        guard !arrived else { return }

        let waypointDir = bearingToWorldUnit(bearingToNextWaypoint())
        let projected = simd_dot(displacement, waypointDir)

        distanceWalkedThisLeg += Double(projected)
        distanceWalkedThisLeg = max(0, distanceWalkedThisLeg)

        if currentLegIndex < legDistances.count,
           distanceWalkedThisLeg >= legDistances[currentLegIndex] - arrivalThresholdMeters {
            advanceToNextWaypoint()
        }

        updateDistanceToWaypoint()
        recomputeUI()
    }

    // MARK: - Route geometry

    private func buildLegDistances() {
        legDistances = []
        for i in 0 ..< (geoWaypoints.count - 1) {
            legDistances.append(distanceMeters(from: geoWaypoints[i], to: geoWaypoints[i + 1]))
        }
    }

    private func bearingToNextWaypoint() -> Double {
        guard currentLegIndex < geoWaypoints.count - 1 else { return 0 }
        return bearingDegrees(from: geoWaypoints[currentLegIndex], to: geoWaypoints[currentLegIndex + 1])
    }

    private func updateDistanceToWaypoint() {
        guard currentLegIndex < legDistances.count else {
            distanceToNextWaypoint = 0
            return
        }
        distanceToNextWaypoint = max(0, legDistances[currentLegIndex] - distanceWalkedThisLeg)
    }

    private func advanceToNextWaypoint() {
        if currentLegIndex < legDistances.count {
            let overshoot = distanceWalkedThisLeg - legDistances[currentLegIndex]
            currentLegIndex += 1
            distanceWalkedThisLeg = max(0, overshoot)
        }
        if currentLegIndex >= geoWaypoints.count - 1 {
            arrived = true
            distanceWalkedThisLeg = 0
        }

        navigationViewModel?.syncStepFromAR(legIndex: currentLegIndex, didArrive: arrived)
    }

    // MARK: - UI

    private func recomputeUI() {
        if arrived {
            arrowRotationDegrees = 0
            currentDirection = .straight
            primaryInstruction = "You have arrived"
            distanceToNextWaypoint = 0
            isWrongDirection = false
            return
        }

        if currentLegIndex < sharedWaypoints.count {
            currentDirection = sharedWaypoints[currentLegIndex].direction
        } else {
            currentDirection = .straight
        }

        let target = bearingToNextWaypoint()

        if let h = deviceHeadingDegrees {
            let raw = shortestAngleDegrees(h, target)
            let wasWrongDirection = isWrongDirection
            if abs(raw) > 140 {
                isWrongDirection = true
            } else if abs(raw) < 120 {
                isWrongDirection = false
            }
            if !wasWrongDirection && isWrongDirection,
               UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled") {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            var clamped = raw
            if clamped > 90 { clamped = 90 }
            if clamped < -90 { clamped = -90 }
            arrowRotationDegrees = clamped
        } else {
            arrowRotationDegrees = 0
            isWrongDirection = false
        }

        if currentLegIndex < legInstructions.count {
            primaryInstruction = legInstructions[currentLegIndex]
        } else {
            primaryInstruction = "Walk straight"
        }
    }
}
#endif
