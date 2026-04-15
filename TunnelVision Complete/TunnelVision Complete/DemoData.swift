#if os(iOS)
import CoreLocation
#endif
import Foundation

// MARK: - Demo Stations

let demoStations = [
    Station(name: "Penn Station - Platform 1"),
    Station(name: "50th Street - Rockefeller Center"),
    Station(name: "Times Square - 42nd St"),
    Station(name: "AGH Lobby"),
    Station(name: "HCI Classroom"),
    Station(name: "AGH Ground Floor Elevators"),
]

// MARK: - Shared Waypoints (single source of truth for both 2D and AR)

let sharedWaypoints: [Waypoint] = [
    Waypoint(id: 1, name: "Start: HCI Classroom",  instruction: "Walk straight toward the door",        direction: .straight,  stepThreshold: 0),
    Waypoint(id: 2, name: "Classroom Door",         instruction: "Turn right and walk down the hallway", direction: .turnRight,  stepThreshold: 10),
    Waypoint(id: 3, name: "Hallway Junction",       instruction: "Turn right toward the elevators",      direction: .turnRight,  stepThreshold: 40),
    Waypoint(id: 4, name: "Arrived: Elevators",     instruction: "You have arrived.",                    direction: .straight,   stepThreshold: 50),
]

// MARK: - Derived Nav Steps (for 2D navigation backward compatibility)

let navSteps: [NavStep] = {
    let avgStepLength = 0.75
    let secondsPerStep = 1.5
    var steps: [NavStep] = []
    let activeWaypoints = sharedWaypoints.dropLast()
    for (i, wp) in activeWaypoints.enumerated() {
        let nextThreshold = sharedWaypoints[i + 1].stepThreshold
        let segmentSteps = nextThreshold - wp.stepThreshold
        let dist = Double(segmentSteps) * avgStepLength
        let totalRemainingSteps = sharedWaypoints.last!.stepThreshold - wp.stepThreshold
        let totalRemainingSec = Int(Double(totalRemainingSteps) * secondsPerStep)
        let mins = totalRemainingSec / 60
        let secs = totalRemainingSec % 60
        let timeStr = String(format: "~%d:%02d", mins, secs)
        steps.append(NavStep(
            id: wp.id,
            direction: wp.direction,
            label: wp.instruction,
            estimatedTimeRemaining: timeStr,
            trainLine: "L",
            trainColor: "#2185D5",
            distanceMeters: dist
        ))
    }
    return steps
}()

// MARK: - Route Timeline Generator (for search screen)

func generateDemoRoute(from start: String, to destination: String) -> [RouteStep] {
    let totalSteps = (sharedWaypoints.last?.stepThreshold ?? 50) - (sharedWaypoints.first?.stepThreshold ?? 0)
    let walkingSeconds = Double(totalSteps) * 1.5
    let walkingMinutes = Int(ceil(walkingSeconds / 60.0))
    let directionCount = sharedWaypoints.count - 1

    return [
        RouteStep(instruction: start, subtitle: "Starting point"),
        RouteStep(instruction: "Navigate this transfer", subtitle: "Follow AR arrows\n~\(walkingMinutes) min walking · \(directionCount) directions"),
        RouteStep(instruction: destination, subtitle: "Destination"),
    ]
}

// MARK: - TunnelRoute (for AR navigation)

#if os(iOS)
struct TunnelRoute {
    let waypoints: [CLLocationCoordinate2D]
    let legInstructions: [String]

    init(start: CLLocationCoordinate2D, legs: [RouteLeg]) {
        var pts = [start]
        var instructions: [String] = []
        var current = start
        for leg in legs {
            current = Self.destination(from: current, bearingDeg: leg.bearingDegrees, distanceM: leg.distanceMeters)
            pts.append(current)
            instructions.append(leg.instruction)
        }
        self.waypoints = pts
        self.legInstructions = instructions
    }

    private static func destination(from: CLLocationCoordinate2D, bearingDeg: Double, distanceM: Double) -> CLLocationCoordinate2D {
        let R = 6_371_000.0
        let φ1 = from.latitude * .pi / 180
        let λ1 = from.longitude * .pi / 180
        let θ = bearingDeg * .pi / 180
        let δ = distanceM / R
        let φ2 = asin(sin(φ1) * cos(δ) + cos(φ1) * sin(δ) * cos(θ))
        let λ2 = λ1 + atan2(sin(θ) * sin(δ) * cos(φ1), cos(δ) - sin(φ1) * sin(φ2))
        return CLLocationCoordinate2D(latitude: φ2 * 180 / .pi, longitude: λ2 * 180 / .pi)
    }
}

@MainActor
enum DemoRoutes {
    private static let avgStepLength = 0.75

    static let hciToElevators: TunnelRoute = {
        let legs: [RouteLeg] = {
            var result: [RouteLeg] = []
            var runningBearing: Double = 180
            for i in 0 ..< (sharedWaypoints.count - 1) {
                let wp = sharedWaypoints[i]
                let next = sharedWaypoints[i + 1]
                let segmentSteps = next.stepThreshold - wp.stepThreshold
                let dist = Double(segmentSteps) * avgStepLength

                switch wp.direction {
                case .turnRight, .bearRight:  runningBearing += 90
                case .turnLeft, .bearLeft:    runningBearing -= 90
                default: break
                }
                runningBearing = runningBearing.truncatingRemainder(dividingBy: 360)
                if runningBearing < 0 { runningBearing += 360 }

                result.append(RouteLeg(
                    bearingDegrees: runningBearing,
                    distanceMeters: dist,
                    instruction: wp.instruction
                ))
            }
            return result
        }()

        return TunnelRoute(
            start: CLLocationCoordinate2D(latitude: 40.75890, longitude: -73.98550),
            legs: legs
        )
    }()

    static let straightCorridor = TunnelRoute(
        start: CLLocationCoordinate2D(latitude: 40.75890, longitude: -73.98550),
        legs: [
            RouteLeg(bearingDegrees: 180, distanceMeters: 100, instruction: "Walk straight"),
        ]
    )
}
#endif
