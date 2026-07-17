//  RadialLayoutDemoView.swift
//  RadialLayout
//
//  The full "Radial Layout" playground screen from DesignerBuddy: a live
//  radial arrangement with sliders for item count, size, and start angle,
//  an optional centre item, shape switching, tap-to-focus, and photo fills.
//
//  Drop it into a NavigationStack, or use it as a reference for driving
//  RadialRingLayout / RadialRing from your own UI.

import PhotosUI
import SwiftUI
import UIKit

private enum RingShape: String, CaseIterable, Identifiable {
    case circle = "Circle", rounded = "Rounded"
    var id: String { rawValue }
}

@available(iOS 17.0, *)
public struct RadialLayoutDemoView: View {
    @State private var count: Double = 12
    @State private var itemScale: Double = 1.0
    @State private var startAngle: Double = 0        // degrees
    @State private var centerItem = false
    @State private var centerGap: Double = 0.15
    @State private var shape: RingShape = .circle
    @State private var centerShape: RingShape = .circle
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var focused: Int?

    public init() {}

    private func shapeFor(_ s: RingShape) -> AnyShape {
        switch s {
        case .circle:  return AnyShape(Circle())
        case .rounded: return AnyShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private func isCenter(_ i: Int) -> Bool { centerItem && i == 0 }
    private func shape(for i: Int) -> AnyShape { shapeFor(isCenter(i) ? centerShape : shape) }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ring
                controls
                caption
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

    private var ring: some View {
        RadialRingLayout(itemScale: CGFloat(itemScale),
                         startAngle: .degrees(startAngle),
                         centerItem: centerItem,
                         centerScale: CGFloat(1.3 - centerGap * 0.9)) {
            if centerItem {
                // Ring items first, centre item last so it renders on top.
                ForEach(1..<Int(count), id: \.self) { i in itemView(i) }
                itemView(0)
            } else {
                ForEach(0..<Int(count), id: \.self) { i in itemView(i) }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.black, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay { focusOverlay }
        .animation(.snappy, value: count)
        .animation(.snappy, value: itemScale)
        .animation(.snappy, value: startAngle)
        .animation(.snappy, value: centerItem)
        .animation(.snappy, value: centerGap)
    }

    private func itemView(_ i: Int) -> some View {
        shapeView(for: i)
            .contentShape(shape(for: i))
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { focused = i }
            }
    }

    @ViewBuilder
    private func shapeView(for i: Int) -> some View {
        let s = shape(for: i)
        if images.isEmpty {
            s.fill(Color(hue: Double(i) / max(count, 1), saturation: 0.55, brightness: 1))
        } else {
            Color.clear
                .overlay(Image(uiImage: images[i % images.count]).resizable().scaledToFill())
                .clipShape(s)
        }
    }

    @ViewBuilder
    private var focusOverlay: some View {
        if let f = focused, f < Int(count) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                shapeView(for: f)
                    .frame(width: 200, height: 200)
                    .shadow(radius: 20)
                    .transition(.scale.combined(with: .opacity))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { focused = nil }
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            sliderRow("Items", $count, 1...24, step: 1, text: "\(Int(count))")
            divider
            sliderRow("Item Size", $itemScale, 0.4...1.0, text: String(format: "%.0f%%", itemScale * 100))
            divider
            sliderRow("Start Angle", $startAngle, 0...360, text: "\(Int(startAngle))°")
            divider
            row {
                Toggle("Center Item", isOn: $centerItem)
            }
            if centerItem {
                divider
                sliderRow("Center Gap", $centerGap, 0...1, text: "\(Int(centerGap * 100))%")
                divider
                shapePicker("Center Shape", $centerShape)
            }
            divider
            shapePicker("Ring Shape", $shape)
            divider
            row {
                HStack {
                    Text("Photos").frame(width: 96, alignment: .leading)
                    Spacer()
                    PhotosPicker(selection: $photoItems, matching: .images) {
                        Label(images.isEmpty ? "Choose Photos" : "\(images.count) selected",
                              systemImage: "photo.on.rectangle")
                    }
                    if !images.isEmpty {
                        Button { images = []; photoItems = [] } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var caption: some View {
        Text("A custom `Layout` arranging subviews around a ring. Adjust item size for gaps, "
             + "the start angle, pull one item to the centre, switch shape, and tap any item to "
             + "pop it up close. Add photos to fill the shapes (they cycle). From my-toybox.")
            .font(.footnote).foregroundStyle(.secondary)
            .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
    }

    private func sliderRow(_ label: String, _ value: Binding<Double>,
                           _ range: ClosedRange<Double>, step: Double = 0, text: String) -> some View {
        row {
            HStack(spacing: 12) {
                Text(label).frame(width: 96, alignment: .leading)
                if step > 0 {
                    Slider(value: value, in: range, step: step)
                } else {
                    Slider(value: value, in: range)
                }
                Text(text).font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary).frame(width: 44, alignment: .trailing)
            }
        }
    }

    private func shapePicker(_ label: String, _ selection: Binding<RingShape>) -> some View {
        row {
            HStack {
                Text(label).frame(width: 110, alignment: .leading)
                Spacer()
                Picker(label, selection: selection) {
                    ForEach(RingShape.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).frame(width: 170)
            }
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content().padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View { Divider().padding(.leading, 16) }
}

#Preview("Radial demo") {
    if #available(iOS 17.0, *) {
        return AnyView(NavigationStack { RadialLayoutDemoView() })
    } else {
        return AnyView(EmptyView())
    }
}
