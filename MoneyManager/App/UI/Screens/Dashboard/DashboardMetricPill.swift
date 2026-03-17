import SwiftUI

struct DashboardMetricPill: View {
    let title: String
    let value: String
    var onInfoTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))

                if let onInfoTap {
                    Button(action: onInfoTap) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.88))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
