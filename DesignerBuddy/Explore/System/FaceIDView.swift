import SwiftUI
import LocalAuthentication

// MARK: - FaceIDView

struct FaceIDView: View {
    @State private var authState: AuthState = .idle
    @State private var showFallbackAlert = false
    @State private var passcode = ""
    @State private var showPasscodeEntry = false

    enum AuthState {
        case idle, authenticating, success, failure(String)

        var icon: String {
            switch self {
            case .idle:             return "faceid"
            case .authenticating:  return "ellipsis.circle"
            case .success:         return "checkmark.shield.fill"
            case .failure:         return "xmark.shield.fill"
            }
        }

        var color: Color {
            switch self {
            case .idle:             return .secondary
            case .authenticating:  return .blue
            case .success:         return .green
            case .failure:         return .red
            }
        }

        var label: String {
            switch self {
            case .idle:                    return "Not authenticated"
            case .authenticating:         return "Authenticating…"
            case .success:                return "Authenticated"
            case .failure(let message):   return message
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: Status indicator
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(authState.color.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: authState.icon)
                            .font(.system(size: 36))
                            .foregroundStyle(authState.color)
                            .symbolEffect(.pulse, isActive: authState == .authenticating)
                    }
                    Text(authState.label)
                        .font(.subheadline)
                        .foregroundStyle(authState.color)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: Evaluate policy
                VStack(spacing: 12) {
                    HStack {
                        Label("LAPolicy Evaluation", systemImage: "lock.shield")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(spacing: 10) {
                        Button {
                            authenticate(policy: .deviceOwnerAuthenticationWithBiometrics)
                        } label: {
                            Label("Biometrics Only (Face ID / Touch ID)", systemImage: "faceid")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            authenticate(policy: .deviceOwnerAuthentication)
                        } label: {
                            Label("Biometrics + Passcode Fallback", systemImage: "key.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    infoRow(icon: "info.circle", text: "On the simulator, use Features > Face ID / Touch ID > Enrolled to enable simulated biometrics, then Matching/Non-matching Face to trigger success or failure.")
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: Custom passcode fallback
                VStack(spacing: 12) {
                    HStack {
                        Label("Custom Passcode Fallback UI", systemImage: "rectangle.and.pencil.and.ellipsis")
                            .font(.headline)
                        Spacer()
                    }

                    Text("When using `.deviceOwnerAuthenticationWithBiometrics`, you can supply a custom fallback button title via `LAContext.localizedFallbackTitle`. Tapping it calls your own UI.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        showPasscodeEntry = true
                    } label: {
                        Label("Show Custom Passcode Entry", systemImage: "textformat.123")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: Error reference
                VStack(spacing: 12) {
                    HStack {
                        Label("LAError Reference", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(spacing: 6) {
                        errorRow(code: "authenticationFailed", detail: "Biometry doesn't match enrolled data")
                        errorRow(code: "userCancel",           detail: "User tapped Cancel")
                        errorRow(code: "userFallback",         detail: "User tapped the fallback button")
                        errorRow(code: "biometryNotAvailable", detail: "Hardware not present or disabled")
                        errorRow(code: "biometryNotEnrolled",  detail: "No Face ID / Touch ID set up")
                        errorRow(code: "biometryLockout",      detail: "Too many failures; passcode required")
                        errorRow(code: "systemCancel",         detail: "System interrupted (e.g., phone call)")
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("Face ID / Touch ID")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPasscodeEntry) {
            PasscodeEntryView(onSuccess: {
                showPasscodeEntry = false
                authState = .success
            }, onCancel: {
                showPasscodeEntry = false
            })
        }
    }

    // MARK: Auth logic

    private func authenticate(policy: LAPolicy) {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        var error: NSError?

        guard context.canEvaluatePolicy(policy, error: &error) else {
            let msg = error?.localizedDescription ?? "Biometrics unavailable"
            authState = .failure(msg)
            return
        }

        authState = .authenticating

        let reason = "Authenticate to access protected content."
        context.evaluatePolicy(policy, localizedReason: reason) { success, evalError in
            DispatchQueue.main.async {
                if success {
                    authState = .success
                } else if let err = evalError as? LAError {
                    switch err.code {
                    case .userFallback:
                        authState = .idle
                        showPasscodeEntry = true
                    case .userCancel, .systemCancel, .appCancel:
                        authState = .idle
                    case .biometryNotAvailable:
                        authState = .failure("Biometrics not available on this device")
                    case .biometryNotEnrolled:
                        authState = .failure("No Face ID / Touch ID enrolled — set up in Settings")
                    case .biometryLockout:
                        authState = .failure("Biometrics locked out after too many failures — use passcode")
                    case .authenticationFailed:
                        authState = .failure("Authentication failed — biometry did not match")
                    default:
                        authState = .failure(err.localizedDescription)
                    }
                } else {
                    authState = .failure("Unknown error")
                }
            }
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
    private func errorRow(code: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(code)
                .font(.caption.monospaced())
                .foregroundStyle(.orange)
                .fixedSize()
            Spacer()
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Custom passcode fallback

private struct PasscodeEntryView: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var passcode = ""
    @State private var errorMessage = ""
    private let correctPasscode = "1234"

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Enter Passcode")
                    .font(.title2.bold())

                Text("Demo passcode is \(correctPasscode)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SecureField("Passcode", text: $passcode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(maxWidth: 200)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button("Unlock") {
                    if passcode == correctPasscode {
                        onSuccess()
                    } else {
                        errorMessage = "Incorrect passcode"
                        passcode = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(passcode.isEmpty)

                Spacer()
            }
            .padding(32)
            .navigationTitle("Passcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

extension FaceIDView.AuthState: Equatable {
    static func == (lhs: FaceIDView.AuthState, rhs: FaceIDView.AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.authenticating, .authenticating), (.success, .success):
            return true
        case (.failure(let a), .failure(let b)):
            return a == b
        default:
            return false
        }
    }
}

#Preview {
    NavigationStack { FaceIDView() }
}
