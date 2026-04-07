import Foundation
import Combine

@MainActor
class TransitViewModel: ObservableObject {
    @Published var nextTrains: [Train] = []
    @Published var isLoading = true
    
    // We publish the current time so the UI redreaws every second when it ticks
    @Published var currentTime = Date() 
    
    private let apiService = TransitAPIService()
    private var timer: Timer?
    
    func loadData() async {
        isLoading = true
        do {
            let trains = try await apiService.fetchNextTrains()
            self.nextTrains = trains.sorted(by: { $0.arrivalTime < $1.arrivalTime })
            self.isLoading = false
            startTimer()
        } catch {
            print("Failed to load mock data")
            self.isLoading = false
        }
    }
    
    private func startTimer() {
        timer?.invalidate() // Clear any existing timers just in case
        
        // Fire every 1.0 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
    }
    
    private func tick() {
        // 1. Update the current time to force the UI to redraw the countdown strings
        currentTime = Date()
        
        // 2. If a train's arrival time has passed, remove it from the array!
        nextTrains.removeAll { $0.arrivalTime < currentTime }
    }
}