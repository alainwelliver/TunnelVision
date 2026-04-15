import SwiftUI

struct SettingsView: View {
    @AppStorage("useMetricUnits") private var useMetric = true
    @AppStorage("hapticFeedbackEnabled") private var hapticEnabled = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TunnelVision")
                                .font(.headline)
                            Text("Subway Transfer Navigator")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                }

                Section("Navigation") {
                    Label("Default to AR Mode", systemImage: "arkit")
                    Toggle(isOn: $hapticEnabled) {
                        Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                    }
                    Label("Step Counter Display", systemImage: "figure.walk")
                    Toggle(isOn: $useMetric) {
                        Label("Use Metric Units", systemImage: "ruler")
                    }
                    HStack {
                        Text("Distance Unit")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(useMetric ? "Meters" : "Feet")
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    .font(.footnote)
                }

                Section("Transit") {
                    Label("Train Line Alerts", systemImage: "bell")
                    Label("Missed Train Notifications", systemImage: "exclamationmark.triangle")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("HCI Assignment 5")
                        Spacer()
                        Text("Spring 2026")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
