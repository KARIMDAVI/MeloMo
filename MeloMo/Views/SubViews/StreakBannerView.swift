// StreakBannerView.swift — Shows current consecutive-day streak at top of Stats tab.
// Orange gradient subtly signals "on fire" without screaming at the user.
import SwiftUI
import FontAwesome

struct StreakBannerView: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(Icons.fire)
                .font(Font.fontAwesome(ofSize: 28, style: .solid))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) day streak")
                    .font(.title3).fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Keep picking your daily mood")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(colors: [.orange.opacity(0.2), .clear],
                           startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
