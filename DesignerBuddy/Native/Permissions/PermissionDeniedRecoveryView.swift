import SwiftUI
import AVFoundation
import Photos
import CoreLocation

// MARK: - Supporting Types

enum RecoveryPermType: String, CaseIterable, Identifiable {
    case camera   = "Camera"
    case photos   = "Photos"
    case location = "Location"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .camera:   return "camera.fill"
        case .photos:   return "photo.fill"
        case .location: return "location.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .camera:   return .orange
        case .photos:   return .blue
        case .location: return .cyan
        }
    }

    var requestTitle: String {
        switch self {
        case .camera:   return "Allow Camera Access"
        case .photos:   return "Allow Photos Access"
        case .location: return "Allow Location Access"
        }
    }

    var requestBody: String {
        switch self {
        case .camera:
            return "Camera access lets you scan documents directly from the app."
        case .photos:
            return "Photos access lets you pick images from your library to attach to reports."
        case .location:
            return "Location access lets the app show nearby resources on the map."
        }
    }

    var deniedTitle: String {
        switch self {
        case .camera:   return "Camera Access Required"
        case .photos:   return "Photos Access Required"
        case .location: return "Location Access Required"
        }
    }

    var settingsPath: String {
        switch self {
        case .camera:
            return "Settings → Privacy & Security → Camera → turn on Designer Buddy"
        case .photos:
            return "Settings → Privacy & Security → Photos → Designer Buddy → set to All Photos or Selected Photos"
        case .location:
            return "Settings → Privacy & Security → Location Services → Designer Buddy → set to While Using"
        }
    }
}

enum PermissionStage {
    case notDetermined, denied, granted
}

// MARK: - Main View

struct PermissionDeniedRecoveryView: View {

    @State private var selectedType: RecoveryPermType = .camera
    @State private var stage: PermissionStage = .notDetermined
    @State private var locationManager = CLLocationManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Segmented picker
                Picker("Permission Type", selection: $selectedType) {
                    ForEach(RecoveryPermType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedType) { _, _ in
                    stage = .notDetermined
                }

                // Stage card
                Group {
                    switch stage {
                    case .notDetermined:
                        FirstAskCard(type: selectedType, stage: $stage, locationManager: $locationManager)
                    case .denied:
                        DeniedRecoveryCard(type: selectedType, stage: $stage)
                    case .granted:
                        GrantedCard(type: selectedType)
                    }
                }
                .padding(.horizontal)

                // Design notes
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        DesignNoteRow(
                            icon: "xmark.circle.fill",
                            iconColor: .red,
                            text: "You cannot re-request after denial. The OS gates the system dialog — it only appears once per permission type. Calling the request API again does nothing."
                        )
                        DesignNoteRow(
                            icon: "hand.raised.fill",
                            iconColor: .orange,
                            text: "\"Open Settings\" is not your primary CTA. Don't make it feel like a demand. Pair it with a \"Not Now\" escape route so users feel in control."
                        )
                        DesignNoteRow(
                            icon: "text.bubble.fill",
                            iconColor: .blue,
                            text: "Say \"Go to Settings\" not \"Enable in Settings\". The user changes a toggle — don't imply the app is doing it for them."
                        )
                        DesignNoteRow(
                            icon: "mappin.circle.fill",
                            iconColor: .purple,
                            text: "Copy the exact Settings path in your recovery message so users don't have to hunt. Paths differ per permission type — don't use a generic fallback."
                        )
                        DesignNoteRow(
                            icon: "bell.fill",
                            iconColor: .cyan,
                            text: "Listen for UIApplication.didBecomeActiveNotification to re-check status when the user returns from Settings — update your UI immediately without requiring a manual refresh."
                        )
                    }
                    .padding(.top, 8)
                } label: {
                    Label("Design Notes", systemImage: "lightbulb")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.top, 16)
        }
        .navigationTitle("Permission Denied Recovery")
        .navigationBarTitleDisplayMode(.large)
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        ) { _ in
            checkCurrentStatus()
        }
    }

    // Re-check status when returning from Settings
    private func checkCurrentStatus() {
        switch selectedType {
        case .camera:
            let s = AVCaptureDevice.authorizationStatus(for: .video)
            if s == .authorized { stage = .granted }
            else if s == .denied || s == .restricted { stage = .denied }
        case .photos:
            let s = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            if s == .authorized || s == .limited { stage = .granted }
            else if s == .denied || s == .restricted { stage = .denied }
        case .location:
            let s = locationManager.authorizationStatus
            if s == .authorizedWhenInUse || s == .authorizedAlways { stage = .granted }
            else if s == .denied || s == .restricted { stage = .denied }
        }
    }
}

// MARK: - First Ask Card

struct FirstAskCard: View {
    let type: RecoveryPermType
    @Binding var stage: PermissionStage
    @Binding var locationManager: CLLocationManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: type.icon)
                .font(.system(size: 52))
                .foregroundStyle(type.iconColor)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Text(type.requestTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(type.requestBody)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                Button {
                    requestPermission()
                } label: {
                    Text("Allow Access")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    stage = .denied
                } label: {
                    Text("Simulate Denied")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text("The \"Simulate Denied\" button lets you preview the recovery card without going through a real system dialog.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }

    private func requestPermission() {
        switch type {
        case .camera:
            Task { @MainActor in
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                stage = granted ? .granted : .denied
            }
        case .photos:
            Task { @MainActor in
                let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
                stage = (status == .authorized || status == .limited) ? .granted : .denied
            }
        case .location:
            locationManager.requestWhenInUseAuthorization()
            // Poll for result — delegate-based API
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                let s = locationManager.authorizationStatus
                if s == .authorizedWhenInUse || s == .authorizedAlways { stage = .granted }
                else if s == .denied || s == .restricted { stage = .denied }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                let s = locationManager.authorizationStatus
                if s == .authorizedWhenInUse || s == .authorizedAlways { stage = .granted }
                else if s == .denied || s == .restricted { stage = .denied }
            }
        }
    }
}

// MARK: - Denied Recovery Card

struct DeniedRecoveryCard: View {
    let type: RecoveryPermType
    @Binding var stage: PermissionStage

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.red.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "lock.slash.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.red)
            }
            .padding(.top, 8)

            VStack(spacing: 8) {
                Text(type.deniedTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text((try? AttributedString(markdown: "To enable, go to **\(type.settingsPath)**")) ?? AttributedString("To enable, go to \(type.settingsPath)"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Go to Settings", systemImage: "gear")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    stage = .notDetermined
                } label: {
                    Text("Not Now")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .font(.subheadline)
            }

            Text("If the user returns from Settings with access granted, your app will be notified via UIApplication.didBecomeActiveNotification.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }
}

// MARK: - Granted Card

struct GrantedCard: View {
    let type: RecoveryPermType

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.green)
            }
            .padding(.top, 8)

            Text("Access Granted")
                .font(.title3)
                .fontWeight(.bold)

            Text("\(type.rawValue) permission is now active. Your app can use the \(type.rawValue.lowercased()) APIs immediately — no restart required.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }
}

// MARK: - Design Note Row

struct DesignNoteRow: View {
    let icon: String
    let iconColor: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)
                .frame(width: 18, alignment: .center)
                .padding(.top, 2)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        PermissionDeniedRecoveryView()
    }
}
