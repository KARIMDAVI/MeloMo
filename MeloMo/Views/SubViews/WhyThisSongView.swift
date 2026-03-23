// WhyThisSongView.swift — Expandable match explanation panel.
// Shows the backend's match_reason with a subtle reveal animation.
import SwiftUI

struct WhyThisSongView: View {
    let reason: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                HStack {
                    Text(Icons.info)
                        .font(Font.fontAwesome(ofSize: 14, style: .solid))
                    Text("Why this song?")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.7))
            }
            if isExpanded {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
