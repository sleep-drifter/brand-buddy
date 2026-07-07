import PhotosUI
import SwiftUI
import UIKit

// Custom-Layout playgrounds ported from Koshimizu-Takehito's my-toybox
// (RadialLayout / FlowLayout). Pure SwiftUI Layout protocol — no Metal.

// MARK: - Radial ring layout

/// Places subviews evenly around a ring, sizing each to touch its neighbours.
private struct RadialRingLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews _: Subviews, cache _: inout Void) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout Void) {
        guard !subviews.isEmpty else { return }
        let side = min(bounds.size.width, bounds.size.height)
        // A single item has no ring to sit on (sin(π) ≈ 0 → zero radius); centre it.
        if subviews.count == 1 {
            let d = side * 0.6
            subviews[0].place(at: CGPoint(x: bounds.midX, y: bounds.midY),
                              anchor: .center,
                              proposal: ProposedViewSize(width: d, height: d))
            return
        }
        let angle = Double.pi / Double(subviews.count)
        let itemRadius = (side / 2.0) * sin(angle) / (1.0 + sin(angle))
        let ringRadius = (side / 2.0) * (1.0 + sin(angle)).rounded(.down)
        let step = Angle.radians(2.0 * angle).radians
        for (index, subview) in subviews.enumerated() {
            var center = CGPoint(x: 0, y: -ringRadius + itemRadius).applying(
                CGAffineTransform(rotationAngle: step * Double(index))
            )
            center.x += bounds.midX
            center.y += bounds.midY
            let proposal = ProposedViewSize(width: 2 * itemRadius, height: 2 * itemRadius)
            subview.place(at: center, anchor: .center, proposal: proposal)
        }
    }
}

struct RadialLayoutView: View {
    @State private var count: Double = 12
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RadialRingLayout {
                    ForEach(0..<Int(count), id: \.self) { i in
                        ringItem(i)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.black,
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .animation(.snappy, value: count)

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text("Items").frame(width: 90, alignment: .leading)
                        Slider(value: $count, in: 1...24, step: 1)
                        Text("\(Int(count))")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .trailing)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    Divider().padding(.leading, 16)
                    HStack {
                        Text("Photos").frame(width: 90, alignment: .leading)
                        Spacer()
                        PhotosPicker(selection: $photoItems, matching: .images) {
                            Label(images.isEmpty ? "Choose Photos" : "\(images.count) selected",
                                  systemImage: "photo.on.rectangle")
                        }
                        if !images.isEmpty {
                            Button {
                                images = []; photoItems = []
                            } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                }
                .background(Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text("A custom `Layout` that arranges its subviews evenly around a ring, sizing "
                     + "each circle so neighbours just touch. Pick photos to fill the circles "
                     + "(they cycle if there are fewer photos than items); otherwise they show as "
                     + "colours. From Koshimizu-Takehito\u{2019}s my-toybox.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Radial Layout")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: photoItems) { _, items in
            Task {
                var loaded: [UIImage] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        loaded.append(image)
                    }
                }
                images = loaded
            }
        }
    }

    @ViewBuilder
    private func ringItem(_ i: Int) -> some View {
        if images.isEmpty {
            Circle().foregroundStyle(Color(hue: Double(i) / count, saturation: 0.55, brightness: 1))
        } else {
            Color.clear
                .overlay(Image(uiImage: images[i % images.count]).resizable().scaledToFill())
                .clipShape(Circle())
        }
    }
}

// MARK: - Wrapping flow layout

/// Lays subviews left-to-right, wrapping to a new row when the width runs out.
private struct WrapFlowLayout: Layout {
    var vSpacing: CGFloat = 8
    var hSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let proposalWidth = proposal.width ?? .zero
        var remainWidth = proposalWidth - hSpacing
        var currentHeight = CGFloat.zero
        var totalSize = CGSize.zero
        for subview in subviews {
            let size = subview.sizeThatFits(.init(width: proposalWidth - 2 * hSpacing, height: .infinity))
            if remainWidth - (size.width + hSpacing) < 0 {
                totalSize.height += currentHeight
                remainWidth = proposalWidth - hSpacing
                currentHeight = .zero
            }
            remainWidth -= size.width + hSpacing
            currentHeight = max(size.height + vSpacing, currentHeight)
        }
        totalSize.height += currentHeight + vSpacing
        totalSize.width = proposalWidth
        return totalSize
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        var offset = CGPoint(x: hSpacing, y: vSpacing)
        var remainWidth = bounds.width
        var currentHeight = CGFloat.zero
        for subview in subviews {
            let size = subview.sizeThatFits(.init(width: bounds.width - 2 * hSpacing, height: .infinity))
            if remainWidth - (size.width + hSpacing) < 0 {
                offset.y += currentHeight + vSpacing
                offset.x = hSpacing
                currentHeight = .zero
                remainWidth = bounds.width - hSpacing
            }
            let point = CGPoint(x: bounds.origin.x + offset.x, y: bounds.origin.y + offset.y)
            subview.place(at: point, proposal: .init(size))
            offset.x += size.width + hSpacing
            remainWidth -= size.width + hSpacing
            currentHeight = max(size.height, currentHeight)
        }
    }
}

struct FlowLayoutView: View {
    @State private var width: CGFloat = 240

    private let tags = ["Objective-C", "Swift", "SwiftUI", "Ruby", "Python", "JavaScript",
                        "Java", "C++", "C#", "Go", "Kotlin", "Rust", "Metal", "Combine"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    WrapFlowLayout(vSpacing: 8, hSpacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.body).fontWeight(.semibold).fontDesign(.monospaced)
                                .foregroundStyle(.white)
                                .padding(.vertical, 6).padding(.horizontal, 12)
                                .background(.black, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .frame(maxWidth: width)
                    .background(.pink.mix(with: .white, by: 0.5),
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.snappy, value: width)

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text("Width").frame(width: 90, alignment: .leading)
                        Slider(value: $width, in: 120...360)
                        Text("\(Int(width))")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                }
                .background(Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text("A custom `Layout` that flows tags left-to-right and wraps to a new row when "
                     + "the container runs out of width. Drag Width to watch the chips reflow. "
                     + "From my-toybox.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Flow Layout")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

#Preview("Radial") { NavigationStack { RadialLayoutView() } }
#Preview("Flow")   { NavigationStack { FlowLayoutView() } }
