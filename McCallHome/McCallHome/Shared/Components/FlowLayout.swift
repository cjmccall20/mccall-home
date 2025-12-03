//
//  FlowLayout.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import SwiftUI

/// A layout that arranges its children in a flowing manner, wrapping to new lines as needed
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        let totalHeight = currentY + lineHeight
        return (CGSize(width: maxWidth, height: totalHeight), frames)
    }
}

/// A selectable chip/tag component for labels
struct LabelChip: View {
    let label: String
    let isSelected: Bool
    var iconName: String? = nil
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.caption2)
                }
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .blue : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        FlowLayout(spacing: 8) {
            LabelChip(label: "Organic", isSelected: true, onTap: {})
            LabelChip(label: "Grass-Fed", isSelected: false, onTap: {})
            LabelChip(label: "Free-Range", isSelected: true, onTap: {})
            LabelChip(label: "Non-GMO", isSelected: false, onTap: {})
            LabelChip(label: "Kosher", isSelected: false, onTap: {})
        }
        .padding()
    }
}
