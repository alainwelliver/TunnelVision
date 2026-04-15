import Foundation
import Combine

@MainActor
class TransitViewModel: ObservableObject {
    @Published var nextTrains: [Train] = []
    @Published var isLoading = true
    @Published var currentTime = Date()
    @Published var statusMessage: String?

    private let apiService = TransitAPIService()
    private var timer: Timer?
    private var lastSuccessfulRefresh: Date?
    private let refreshInterval: TimeInterval = 30

    func loadData() async {
        await refreshTrains(showLoading: true)
        startTimer()
    }

    var emptyStateMessage: String {
        statusMessage ?? "No upcoming trains"
    }

    private func refreshNeeded(now: Date) -> Bool {
        guard let lastSuccessfulRefresh else { return true }
        return now.timeIntervalSince(lastSuccessfulRefresh) >= refreshInterval
    }

    private func refreshTrains(showLoading: Bool) async {
        if showLoading {
            isLoading = true
        }

        do {
            let trains = try await apiService.fetchNextTrains(now: Date())
            nextTrains = trains.sorted(by: { $0.arrivalTime < $1.arrivalTime })
            statusMessage = nil
            lastSuccessfulRefresh = Date()
        } catch let error as TransitServiceError {
            nextTrains = []
            statusMessage = error.errorDescription
        } catch {
            nextTrains = []
            statusMessage = "Realtime ETAs unavailable right now."
        }

        isLoading = false
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
    }

    private func tick() {
        currentTime = Date()

        nextTrains.removeAll { $0.arrivalTime < currentTime }

        if refreshNeeded(now: currentTime) {
            Task { [weak self] in
                await self?.refreshTrains(showLoading: false)
            }
        }
    }
}
