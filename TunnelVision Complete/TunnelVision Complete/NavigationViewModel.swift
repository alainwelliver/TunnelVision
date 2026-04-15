import Foundation
import Combine
import CoreMotion
import UIKit

@MainActor
final class NavigationViewModel: ObservableObject {

    // Landing page
    @Published var showLanding: Bool = true

    // Trip overview (route card + start button before active navigation)
    @Published var showTripOverview: Bool = false

    // Pre-fill for SearchView when coming from landing "Starting from" button
    @Published var prefillStart: Station? = nil

    // Tab selection
    @Published var selectedTab: Int = 0

    // Navigation session state
    @Published var isNavigating: Bool = false
    @Published var isARMode: Bool = false
    @Published var currentStepIndex: Int = 0
    @Published var arrived: Bool = false

    // Route endpoints (set by search screen)
    @Published var startStation: Station?
    @Published var destStation: Station?

    // Pedometer (single source of truth for both 2D and AR)
    @Published var stepCount: Int = 0

    private let pedometer = CMPedometer()

    private func fireDirectionHaptic() {
        guard UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled") else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    var currentStep: NavStep { navSteps[currentStepIndex] }
    var isFirstStep: Bool { currentStepIndex == 0 }
    var isLastStep: Bool { currentStepIndex == navSteps.count - 1 }

    var currentWaypoint: Waypoint { sharedWaypoints[currentStepIndex] }
    var activeWaypointCount: Int { sharedWaypoints.count - 1 }

    var stepsRemainingInLeg: Int {
        let nextIndex = currentStepIndex + 1
        guard nextIndex < sharedWaypoints.count else { return 0 }
        return max(0, sharedWaypoints[nextIndex].stepThreshold - stepCount)
    }

    // MARK: - Session lifecycle

    func startNavigation() {
        showLanding = false
        showTripOverview = false
        isNavigating = true
        isARMode = false
        currentStepIndex = 0
        arrived = false
        stepCount = 0
        selectedTab = 1
        startPedometer()
    }

    func startFromLanding(destination: Station) {
        if destination.name == "AGH Ground Floor Elevators" {
            startStation = demoStations.first { $0.name == "HCI Classroom" }
        } else {
            startStation = demoStations.first { $0.name == "AGH Lobby" }
        }
        destStation = destination
        prepareTrip()
    }

    func goToSearchFromLanding() {
        prefillStart = demoStations.first { $0.name == "AGH Lobby" }
        showLanding = false
        selectedTab = 0
    }

    func prepareTrip() {
        showLanding = false
        showTripOverview = true
        selectedTab = 1
    }

    func reset() {
        stopPedometer()
        isNavigating = false
        isARMode = false
        showTripOverview = false
        currentStepIndex = 0
        arrived = false
        stepCount = 0
        startStation = nil
        destStation = nil
        selectedTab = 0
        showLanding = true
    }

    // MARK: - 2D manual step controls

    func nextStep() {
        guard !arrived else { return }
        if isLastStep {
            arrived = true
            stopPedometer()
        } else {
            currentStepIndex += 1
            fireDirectionHaptic()
        }
    }

    func previousStep() {
        if currentStepIndex > 0 {
            currentStepIndex -= 1
        }
    }

    // MARK: - AR mode toggle

    func toggleARMode() {
        isARMode.toggle()
    }

    // MARK: - Called by TunnelRouteNavigator when AR auto-advances

    func syncStepFromAR(legIndex: Int, didArrive: Bool) {
        let mapped = min(legIndex, navSteps.count - 1)
        let changed = mapped != currentStepIndex
        currentStepIndex = mapped
        if changed { fireDirectionHaptic() }
        if didArrive {
            arrived = true
            stopPedometer()
        }
    }

    // MARK: - Auto-advance based on step thresholds

    private func checkStepThresholdAdvance() {
        guard isNavigating, !arrived else { return }
        let nextIndex = currentStepIndex + 1
        guard nextIndex < sharedWaypoints.count else { return }

        if stepCount >= sharedWaypoints[nextIndex].stepThreshold {
            if nextIndex >= sharedWaypoints.count - 1 {
                currentStepIndex = navSteps.count - 1
                fireDirectionHaptic()
                arrived = true
                stopPedometer()
            } else {
                currentStepIndex = nextIndex
                fireDirectionHaptic()
                checkStepThresholdAdvance()
            }
        }
    }

    // MARK: - Pedometer

    private func startPedometer() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            guard error == nil, let data else { return }
            Task { @MainActor in
                self?.stepCount = data.numberOfSteps.intValue
                self?.checkStepThresholdAdvance()
            }
        }
    }

    private func stopPedometer() {
        pedometer.stopUpdates()
    }
}
