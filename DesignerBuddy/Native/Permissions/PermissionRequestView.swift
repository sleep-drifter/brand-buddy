import SwiftUI
import AVFoundation
import Photos
import CoreLocation
import Contacts
import UserNotifications

// MARK: - Permission Status

enum PermStatus {
    case notDetermined, granted, denied

    var label: String {
        switch self {
        case .notDetermined: return "Not Asked"
        case .granted:       return "Granted"
        case .denied:        return "Denied"
        }
    }

    var color: Color {
        switch self {
        case .notDetermined: return .secondary
        case .granted:       return .green
        case .denied:        return .red
        }
    }
}

// MARK: - Permission Item Model

struct PermissionItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let iconColor: Color
}

// MARK: - Main View

struct PermissionRequestView: View {

    // Camera
    @State private var cameraStatus: PermStatus = .notDetermined
    // Microphone
    @State private var micStatus: PermStatus = .notDetermined
    // Photos
    @State private var photosStatus: PermStatus = .notDetermined
    // Location
    @State private var locationStatus: PermStatus = .notDetermined
    @State private var locationManager = CLLocationManager()
    // Contacts
    @State private var contactsStatus: PermStatus = .notDetermined
    // Notifications
    @State private var notificationsStatus: PermStatus = .notDetermined

    // Requesting flags (to show loading state)
    @State private var requesting: Set<String> = []

    var body: some View {
        List {
            Section {
                permRow(
                    name: "Camera",
                    icon: "camera.fill",
                    iconColor: .orange,
                    status: cameraStatus,
                    onRequest: requestCamera
                )
                permRow(
                    name: "Microphone",
                    icon: "mic.fill",
                    iconColor: .red,
                    status: micStatus,
                    onRequest: requestMicrophone
                )
                permRow(
                    name: "Photos",
                    icon: "photo.fill",
                    iconColor: .blue,
                    status: photosStatus,
                    onRequest: requestPhotos
                )
                permRow(
                    name: "Location",
                    icon: "location.fill",
                    iconColor: .cyan,
                    status: locationStatus,
                    onRequest: requestLocation
                )
                permRow(
                    name: "Contacts",
                    icon: "person.crop.circle.fill",
                    iconColor: .purple,
                    status: contactsStatus,
                    onRequest: requestContacts
                )
                permRow(
                    name: "Notifications",
                    icon: "bell.fill",
                    iconColor: .pink,
                    status: notificationsStatus,
                    onRequest: requestNotifications
                )
            } footer: {
                Text("Tap Request to prompt the system dialog. Once denied, the OS will not show the dialog again — use Settings to re-enable.")
                    .font(.caption)
            }

            Section("How to Read Statuses") {
                StatusLegendRow(color: .green,     label: "Granted",      detail: "User approved. APIs are available.")
                StatusLegendRow(color: .red,        label: "Denied",       detail: "User declined or restricted by MDM. Must go to Settings.")
                StatusLegendRow(color: .secondary, label: "Not Asked",    detail: "You haven't called the request API yet.")
            }
        }
        .navigationTitle("Permission Requests")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { refreshAll() }
    }

    // MARK: - Row Builder

    @ViewBuilder
    private func permRow(
        name: String,
        icon: String,
        iconColor: Color,
        status: PermStatus,
        onRequest: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                StatusBadge(status: status)
            }

            Spacer()

            Button("Request") {
                onRequest()
            }
            .font(.caption)
            .fontWeight(.semibold)
            .buttonStyle(.borderedProminent)
            .controlSize(.mini)
            .disabled(status == .granted || status == .denied || requesting.contains(name))
        }
        .padding(.vertical, 2)
    }

    // MARK: - Status Refresh

    private func refreshAll() {
        refreshCamera()
        refreshMicrophone()
        refreshPhotos()
        refreshLocation()
        refreshContacts()
        Task { await refreshNotifications() }
    }

    private func refreshCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:                     cameraStatus = .granted
        case .denied, .restricted:            cameraStatus = .denied
        case .notDetermined:                  cameraStatus = .notDetermined
        default:                     cameraStatus = .notDetermined
        }
    }

    private func refreshMicrophone() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:  micStatus = .granted
        case .denied:   micStatus = .denied
        default:        micStatus = .notDetermined
        }
    }

    private func refreshPhotos() {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:           photosStatus = .granted
        case .denied, .restricted:            photosStatus = .denied
        case .notDetermined:                  photosStatus = .notDetermined
        default:                     photosStatus = .notDetermined
        }
    }

    private func refreshLocation() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: locationStatus = .granted
        case .denied, .restricted:                    locationStatus = .denied
        case .notDetermined:                          locationStatus = .notDetermined
        default:                             locationStatus = .notDetermined
        }
    }

    private func refreshContacts() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:                     contactsStatus = .granted
        case .denied, .restricted:            contactsStatus = .denied
        case .notDetermined:                  contactsStatus = .notDetermined
        default:                     contactsStatus = .notDetermined
        }
    }

    @MainActor
    private func refreshNotifications() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: notificationsStatus = .granted
        case .denied:                               notificationsStatus = .denied
        case .notDetermined:                        notificationsStatus = .notDetermined
        default:                           notificationsStatus = .notDetermined
        }
    }

    // MARK: - Request Actions

    private func requestCamera() {
        Task { @MainActor in
            _ = await AVCaptureDevice.requestAccess(for: .video)
            refreshCamera()
        }
    }

    private func requestMicrophone() {
        Task { @MainActor in
            _ = await AVAudioApplication.requestRecordPermission()
            refreshMicrophone()
        }
    }

    private func requestPhotos() {
        Task { @MainActor in
            _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            refreshPhotos()
        }
    }

    private func requestLocation() {
        // CLLocationManager must be called on main thread; dialog appears automatically.
        locationManager.requestWhenInUseAuthorization()
        // Poll briefly since CLLocationManagerDelegate isn't wired here.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { refreshLocation() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { refreshLocation() }
    }

    private func requestContacts() {
        Task { @MainActor in
            let store = CNContactStore()
            _ = try? await store.requestAccess(for: .contacts)
            refreshContacts()
        }
    }

    private func requestNotifications() {
        Task { @MainActor in
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await refreshNotifications()
        }
    }
}

// MARK: - Supporting Views

struct StatusBadge: View {
    let status: PermStatus

    var body: some View {
        Text(status.label)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(status.color))
    }
}

struct StatusLegendRow: View {
    let color: Color
    let label: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PermissionRequestView()
    }
}
