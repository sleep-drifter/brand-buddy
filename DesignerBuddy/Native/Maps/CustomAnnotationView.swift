import SwiftUI
import MapKit

struct CustomAnnotationView: View {
    let landmark: MapLandmark
    let onTap: () -> Void

    var body: some View {
        Button(landmark.name, action: onTap)
            .buttonStyle(AnnotationButtonStyle(landmark: landmark))
    }
}

private struct AnnotationButtonStyle: ButtonStyle {
    let landmark: MapLandmark

    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(landmark.color)
                    .frame(width: 36, height: 36)
                    .shadow(color: landmark.color.opacity(0.4), radius: 4, y: 2)

                Image(systemName: "mappin.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }

            Text(landmark.name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.regularMaterial, in: Capsule())
                .lineLimit(1)
                .accessibilityHidden(true) // name already provided as button label
        }
        .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

#Preview {
    CustomAnnotationView(
        landmark: MapLandmark(
            name: "Golden Gate Bridge",
            subtitle: "Iconic suspension bridge",
            coordinate: .init(latitude: 37.8199, longitude: -122.4783),
            color: .orange
        ),
        onTap: {}
    )
    .padding()
}
