//
//  PedometerViewModel.swift
//  tunnelvision-req-4
//

import Foundation
import Combine
import CoreMotion

struct Waypoint {
    let id: Int
    let name: String
    let instruction: String
    let stepThreshold: Int
}

@MainActor
final class PedometerViewModel: ObservableObject {

    let route: [Waypoint] = [
        Waypoint(id: 1, name: "Start: AGH Lobby",      instruction: "Begin walking toward the main corridor", stepThreshold: 0),
        Waypoint(id: 2, name: "Main Corridor",          instruction: "Continue straight past the elevators",   stepThreshold: 30),
        Waypoint(id: 3, name: "Corridor Junction",      instruction: "Bear left at the junction",              stepThreshold: 65),
        Waypoint(id: 4, name: "Exit Hallway",           instruction: "Walk toward the exit doors",             stepThreshold: 100),
        Waypoint(id: 5, name: "Arrived: 34th St Exit",  instruction: "You have arrived.",                      stepThreshold: 130),
    ]

    @Published var stepCount: Int = 0
    @Published var currentWaypointIndex: Int = 0

    private let pedometer = CMPedometer()
    private var startDate: Date = Date()

    var currentWaypoint: Waypoint { route[currentWaypointIndex] }
    var isArrived: Bool { currentWaypointIndex == route.count - 1 }
    var nextWaypoint: Waypoint? { isArrived ? nil : route[currentWaypointIndex + 1] }

    var stepsToNext: Int? {
        guard let next = nextWaypoint else { return nil }
        return max(0, next.stepThreshold - stepCount)
    }

    var progress: Double {
        let total = Double(route.last!.stepThreshold)
        return min(Double(stepCount) / total, 1.0)
    }

    func startTracking() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        startDate = Date()
        pedometer.startUpdates(from: startDate) { [weak self] data, _ in
            guard let self, let data else { return }
            let steps = data.numberOfSteps.intValue
            Task { @MainActor in
                self.stepCount = steps
                self.updateWaypoint()
            }
        }
    }

    func reset() {
        pedometer.stopUpdates()
        stepCount = 0
        currentWaypointIndex = 0
        startTracking()
    }

    private func updateWaypoint() {
        for i in stride(from: route.count - 1, through: 0, by: -1) {
            if stepCount >= route[i].stepThreshold {
                if i != currentWaypointIndex {
                    currentWaypointIndex = i
                }
                break
            }
        }
        if isArrived {
            pedometer.stopUpdates()
        }
    }
}
