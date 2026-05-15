import SwiftUI
import UIKit

// MARK: - UIActivityViewController wrapper

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - ShareSheetView

struct ShareSheetView: View {
    @State private var showCustomSheet = false
    @State private var customSharedItem = "Hello from Designer Buddy!"

    private let sampleText = "Check out Designer Buddy — a SwiftUI reference app."
    private let sampleURL = URL(string: "https://apple.com")!

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: ShareLink (SwiftUI native)
                VStack(spacing: 12) {
                    HStack {
                        Label("ShareLink (SwiftUI)", systemImage: "square.and.arrow.up")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(spacing: 10) {
                        ShareLink(item: sampleText) {
                            Label("Share Text", systemImage: "text.bubble")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        ShareLink(item: sampleURL, message: Text("Check this out:")) {
                            Label("Share URL", systemImage: "link")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        ShareLink(
                            item: sampleText,
                            subject: Text("Designer Buddy"),
                            message: Text(sampleText)
                        ) {
                            Label("Share with Subject & Message", systemImage: "envelope")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    infoRow(icon: "info.circle", text: "ShareLink is the SwiftUI-native way to trigger the system share sheet. Use it for text, URLs, or any Transferable item.")
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: UIActivityViewController (custom wrapper)
                VStack(spacing: 12) {
                    HStack {
                        Label("UIActivityViewController", systemImage: "gearshape.2")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom items or excluded activity types require the UIKit wrapper.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button {
                            showCustomSheet = true
                        } label: {
                            Label("Share via UIActivityViewController", systemImage: "square.and.arrow.up.on.square")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }

                    infoRow(icon: "exclamationmark.triangle", text: "UIActivityViewController lets you exclude specific activities (e.g., .airDrop, .mail) and pass multiple heterogeneous items.")
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: When to use which
                VStack(spacing: 12) {
                    HStack {
                        Label("Choosing an approach", systemImage: "arrow.left.arrow.right")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(spacing: 8) {
                        compareRow(title: "ShareLink", detail: "SwiftUI-native, simple, Transferable items", preferred: true)
                        compareRow(title: "UIActivityViewController", detail: "Multiple item types, excluded activities, custom UIActivity subclasses", preferred: false)
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("Share Sheet")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCustomSheet) {
            ActivityViewController(
                activityItems: [customSharedItem, sampleURL],
                applicationActivities: nil
            )
            .ignoresSafeArea()
        }
    }

    // MARK: Helpers

    @ViewBuilder
    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func compareRow(title: String, detail: String, preferred: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: preferred ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(preferred ? .green : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.medium)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack { ShareSheetView() }
}
