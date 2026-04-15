import SwiftUI

struct SearchView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel

    @State private var startText = ""
    @State private var destText = ""

    @State private var startStation: Station? = nil
    @State private var destStation: Station? = nil

    enum FocusField {
        case start
        case destination
    }
    @FocusState private var activeField: FocusField?

    var body: some View {
        VStack(spacing: 0) {

            // Header: search bars
            VStack(alignment: .leading, spacing: 12) {

                // From field
                HStack(spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#006FEE"))

                    TextField("Where are you starting?", text: $startText, prompt: Text("Where are you starting?").foregroundColor(.gray))
                        .foregroundColor(.black)
                        .focused($activeField, equals: .start)
                        .onChange(of: startText) { _ in
                            if startStation != nil && startText != startStation?.name {
                                startStation = nil
                            }
                        }

                    if !startText.isEmpty && activeField == .start {
                        Button(action: { startText = ""; startStation = nil }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(activeField == .start ? Color.blue.opacity(0.05) : Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(activeField == .start ? Color(hex: "#006FEE") : Color.gray.opacity(0.3), lineWidth: 1))

                // To field
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#f31260"))

                    TextField("Where to?", text: $destText, prompt: Text("Where to?").foregroundColor(.gray))
                        .foregroundColor(.black)
                        .focused($activeField, equals: .destination)
                        .onChange(of: destText) { _ in
                            if destStation != nil && destText != destStation?.name {
                                destStation = nil
                            }
                        }

                    if !destText.isEmpty && activeField == .destination {
                        Button(action: { destText = ""; destStation = nil }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(activeField == .destination ? Color.red.opacity(0.05) : Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(activeField == .destination ? Color(hex: "#f31260") : Color.gray.opacity(0.3), lineWidth: 1))
            }
            .padding(.horizontal)
            .padding(.top, 20)

            // Content area
            VStack {
                if activeField != nil {
                    searchResultsView
                } else if let start = startStation, let dest = destStation {
                    routeCardView(start: start.name, dest: dest.name)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Spacer()
                }
            }
            .padding(.top, 10)

            Spacer()
        }
        .background(Color(hex: "#fcfcfc").ignoresSafeArea())
        .animation(.spring(), value: activeField)
        .animation(.spring(), value: startStation)
        .animation(.spring(), value: destStation)
        .onAppear {
            if let prefill = navigationVM.prefillStart {
                startText = prefill.name
                startStation = prefill
                navigationVM.prefillStart = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    activeField = .destination
                }
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                let query = activeField == .start ? startText : destText
                let results = demoStations.filter { query.isEmpty || $0.name.lowercased().contains(query.lowercased()) }

                if results.isEmpty {
                    Text("No stations found.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(results) { station in
                        Button(action: {
                            if activeField == .start {
                                startText = station.name
                                startStation = station
                                activeField = .destination
                            } else {
                                destText = station.name
                                destStation = station
                                activeField = nil
                                if let start = startStation {
                                    navigationVM.startStation = start
                                    navigationVM.destStation = station
                                    navigationVM.prepareTrip()
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: activeField == .start ? "circle.fill" : "mappin.and.ellipse")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 10))
                                Text(station.name)
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                        }
                        Divider().padding(.horizontal)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }

    // MARK: - Route Card

    private func beginNavigation() {
        navigationVM.startStation = startStation
        navigationVM.destStation = destStation
        navigationVM.startNavigation()
    }

    private func routeCardView(start: String, dest: String) -> some View {
        let currentRoute = generateDemoRoute(from: start, to: dest)

        return VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(currentRoute.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 0) {
                            Circle()
                                .stroke(Color(hex: "#f31260"), lineWidth: 2)
                                .background(Circle().fill(Color.white))
                                .frame(width: 16, height: 16)

                            if index < currentRoute.count - 1 {
                                Rectangle()
                                    .fill(Color(hex: "#f31260"))
                                    .frame(width: 2)
                                    .frame(minHeight: 40)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            if index == 1 {
                                Button(action: beginNavigation) {
                                    Text(step.instruction)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: "#006FEE"))
                                        .cornerRadius(12)
                                }
                            } else {
                                Text(step.instruction)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black)
                            }

                            if let subtitle = step.subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.top, -2)
                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

            Button(action: beginNavigation) {
                HStack {
                    Image(systemName: "map")
                    Text("Start Transfer Navigation")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(Color(hex: "#17c964"))
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#17c964"), lineWidth: 2))
            }
        }
        .padding(.horizontal)
    }
}
