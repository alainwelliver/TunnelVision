import SwiftUI

struct DirectionArrowView: View {
    let direction: Direction

    private let green = Color(hex: "#17c964")

    var body: some View {
        switch direction {
        case .straight:
            tripleArrows(systemName: "chevron.up")
        case .bearLeft:
            tripleArrows(systemName: "arrow.up.left")
        case .bearRight:
            tripleArrows(systemName: "arrow.up.right")
        case .turnLeft:
            tripleArrows(systemName: "arrow.turn.up.left")
        case .turnRight:
            tripleArrows(systemName: "arrow.turn.up.right")
        case .upStairs:
            stairsArrow(up: true)
        case .downStairs:
            stairsArrow(up: false)
        case .splitAhead:
            splitArrow()
        }
    }

    @ViewBuilder
    private func tripleArrows(systemName: String) -> some View {
        VStack(spacing: -8) {
            Image(systemName: systemName)
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(green)
            Image(systemName: systemName)
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(green.opacity(0.55))
            Image(systemName: systemName)
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(green.opacity(0.25))
        }
    }

    @ViewBuilder
    private func stairsArrow(up: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: up ? "arrow.up" : "arrow.down")
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(green)
            Image(systemName: "staircase")
                .font(.system(size: 64, weight: .semibold))
                .foregroundColor(green)
                .scaleEffect(x: 1, y: up ? 1 : -1)
        }
    }

    @ViewBuilder
    private func splitArrow() -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 24) {
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(green)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(green)
            }
            Image(systemName: "arrow.up")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(green.opacity(0.5))
        }
    }
}
