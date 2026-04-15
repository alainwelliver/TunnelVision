import SwiftUI

struct Navigation2DView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel
    @EnvironmentObject var transitVM: TransitViewModel
    @AppStorage("useMetricUnits") private var useMetric = true

    @State private var showExitConfirmation = false

    private let green = Color(hex: "#17c964")

    private var step: NavStep { navigationVM.currentStep }

    private var formattedDistance: String {
        if useMetric {
            return String(format: "%.0f m", step.distanceMeters)
        } else {
            return String(format: "%.0f ft", step.distanceMeters * 3.28084)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { showExitConfirmation = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "xmark")
                        Text("Exit")
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.red)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.12))
                    )
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            TrainArrivalPill()
                .padding(.top, 8)
                .padding(.bottom, 8)

            Spacer()

            // Direction arrows
            DirectionArrowView(direction: step.direction)
                .frame(height: 200)
                .animation(.easeInOut(duration: 0.25), value: navigationVM.currentStepIndex)

            Spacer().frame(height: 24)

            // Direction label
            Text(step.label)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)

            Spacer().frame(height: 8)

            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    Label(formattedDistance, systemImage: "ruler")
                    Label("\(navigationVM.stepsRemainingInLeg) steps left", systemImage: "shoeprints.fill")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(green)

                Text("Estimated Time Remaining: \(step.estimatedTimeRemaining)")
                    .font(.system(size: 14))
                    .foregroundColor(green.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding(.horizontal, 32)

            Spacer()

            // Activate AR button
            Button(action: {
                navigationVM.toggleARMode()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arkit")
                    Text("Activate AR Mode")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(.white)
                .background(Capsule().fill(Color(hex: "#006FEE")))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 12)

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text("Step \(navigationVM.currentStepIndex + 1) of \(navigationVM.activeWaypointCount)")
                    Text("|")
                    Text("Lost? Skip to a different step")
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    NavButton(title: "Skip Back", action: {
                        navigationVM.previousStep()
                    }, filled: false)
                    .opacity(navigationVM.isFirstStep ? 0 : 1)
                    .disabled(navigationVM.isFirstStep)

                    NavButton(title: navigationVM.isLastStep ? "Arrived" : "Skip Ahead", action: {
                        navigationVM.nextStep()
                    }, filled: true)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: navigationVM.currentStepIndex)
        .alert("Exit Navigation?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Exit", role: .destructive) { navigationVM.reset() }
        } message: {
            Text("This will end your current route and return to the home screen.")
        }
    }
}

// MARK: - Nav Button

struct NavButton: View {
    let title: String
    let action: () -> Void
    let filled: Bool

    private let green = Color(hex: "#17c964")

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(filled ? .white : green)
                .background(
                    Capsule()
                        .fill(filled ? green : Color.clear)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(green, lineWidth: 2)
                )
        }
    }
}
