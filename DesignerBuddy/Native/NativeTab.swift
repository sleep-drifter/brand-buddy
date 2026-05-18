import SwiftUI

struct NativeTab: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Permissions") {
                    NavigationLink {
                        PermissionRequestView()
                    } label: {
                        Label("Permission Requests", systemImage: "lock.shield")
                    }
                    NavigationLink {
                        PermissionDeniedRecoveryView()
                    } label: {
                        Label("Permission Denied Recovery", systemImage: "exclamationmark.lock")
                    }
                    NavigationLink {
                        PushPermissionView()
                    } label: {
                        Label("Push Notifications", systemImage: "bell.badge")
                    }
                }

                Section("Camera") {
                    NavigationLink {
                        CameraConfigListView()
                    } label: {
                        Label("Camera", systemImage: "camera")
                    }
                }

                Section("Photo Library") {
                    NavigationLink {
                        PhotoPickerView()
                    } label: {
                        Label("Photo Picker", systemImage: "photo.on.rectangle.angled")
                    }
                    NavigationLink {
                        PhotoLibraryPatternsView()
                    } label: {
                        Label("Photo Library Patterns", systemImage: "photo.stack")
                    }
                }

                Section("Audio") {
                    NavigationLink {
                        AudioRecordingView()
                    } label: {
                        Label("Audio Recording", systemImage: "mic.fill")
                    }
                    NavigationLink {
                        AudioWaveformView()
                    } label: {
                        Label("Waveform Visualization", systemImage: "waveform")
                    }
                    NavigationLink {
                        AudioPlaybackPatternsView()
                    } label: {
                        Label("Playback UI Patterns", systemImage: "play.circle")
                    }
                }

                Section("Maps") {
                    NavigationLink {
                        MapBasicsView()
                    } label: {
                        Label("Map Basics", systemImage: "map")
                    }
                    NavigationLink {
                        MapAnnotationsView()
                    } label: {
                        Label("Map Annotations", systemImage: "mappin.and.ellipse")
                    }
                    NavigationLink {
                        MapOverlaysView()
                    } label: {
                        Label("Map Overlays", systemImage: "map.circle")
                    }
                }
            }
            .navigationTitle("Native")
        }
    }
}

#Preview {
    NativeTab()
}
