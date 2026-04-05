import SwiftUI

struct HelloStylesView: View {
    //labels of colors with codes
    let heroColors: [(name: String, hex: String)] = [
        ("Success", "#17c964"),
        ("Primary", "#006FEE"),
        ("Danger", "#f31260"),
        ("Warning", "#f5a524"),
        ("Default", "#d4d4d8"),
        ("Secondary", "#7828c8")
    ]
    
    //font sizes
    let fontSizes: [CGFloat] = [12, 16, 20, 24]
    
    var body: some View {
        //if content is too much
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                
                Text("Style Guide")
                    .font(.system(size: 32, weight: .bold))
                
                //Color Pallette section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hero UI Colors")
                        .font(.headline)
                    
                    // arange horizontally
                    HStack(spacing: 15) {
                        ForEach(heroColors, id: \.name) { colorItem in
                            VStack {
                                Circle()
                                    .fill(Color(hex: colorItem.hex)) //using Alains Hex decoder
                                    .frame(width: 40, height: 40)
                                    .shadow(radius: 2)
                            }
                        }
                    }
                }
                
                //Typography section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Typography (System Fallback for Inter)")
                        .font(.headline)
                    
                    ForEach(fontSizes, id: \.self) { size in
                        HStack(spacing: 20) {
                            Text("Regular \(Int(size))px")
                                .font(.system(size: size, weight: .regular))
                            
                            Text("Semi-Bold \(Int(size))px")
                                .font(.system(size: size, weight: .semibold))
                        }
                    }
                }
                
                //Icons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sample Icons")
                        .font(.headline)
                    
                    HStack(spacing: 24) {
                        Image(systemName: "house")
                        Image(systemName: "magnifyingglass")
                        Image(systemName: "bell")
                        Image(systemName: "gearshape")
                        Image(systemName: "person")
                    }
                    .font(.system(size: 24)) // size for icons
                    .foregroundColor(Color(hex: "#006FEE"))
                }
            }
            .padding(24) 
        }
    }
}

#Preview {
    HelloStylesView()
}