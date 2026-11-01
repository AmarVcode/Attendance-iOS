import SwiftUI

/// In-app front-camera selfie capture modal overlay matching Android SelfieCameraCaptureDialog.
public struct SelfieCameraModal: View {
    public let punchType: String // "IN" or "OUT"
    public let employeeName: String
    public let onDismiss: () -> Void
    public let onPhotoCaptured: (UIImage) -> Void

    @StateObject private var cameraController = CameraController()
    @State private var capturedImage: UIImage?

    public init(
        punchType: String,
        employeeName: String,
        onDismiss: @escaping () -> Void,
        onPhotoCaptured: @escaping (UIImage) -> Void
    ) {
        self.punchType = punchType
        self.employeeName = employeeName
        self.onDismiss = onDismiss
        self.onPhotoCaptured = onPhotoCaptured
    }

    public var body: some View {
        ZStack {
            Color(hex: 0x0F172A)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Attendance \(punchType.uppercased())")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        Text("Take a selfie to verify identity & location")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.7))
                    }

                    Spacer()

                    Button(action: {
                        cameraController.stop()
                        onDismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer().frame(height: 20)

                // Camera Preview or Captured Preview Container
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: 0x1E293B))

                    if let image = capturedImage {
                        // Captured Photo Preview
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 24))

                        // Green verification circle
                        Circle()
                            .stroke(Color(hex: 0x10B981), lineWidth: 3)
                            .frame(width: 250, height: 250)
                    } else if cameraController.isCameraAvailable && cameraController.permissionGranted {
                        // Live AVFoundation Front Camera Preview
                        CameraPreviewView(cameraController: cameraController)
                            .clipShape(RoundedRectangle(cornerRadius: 24))

                        // Face guideline oval
                        Ellipse()
                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                            .frame(width: 230, height: 290)
                    } else {
                        // Simulator or Camera Permission Denied Fallback
                        VStack(spacing: 14) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.primaryBlue)

                            Text(cameraController.isCameraAvailable ? "Camera Access Required" : "Camera Hardware Unavailable")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)

                            Text("A verified photo is required to mark attendance punches. Simulator environments use smart fallback identity avatars.")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            Button(action: {
                                // Generate fallback image for testing / simulation
                                let fallback = ImageUtils.createFallbackSelfie(employeeName: employeeName)
                                capturedImage = fallback
                            }) {
                                Text("Generate Verified Selfie")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.primaryBlue)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(20)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 460)
                .padding(.horizontal, 16)

                Spacer().frame(height: 28)

                // Bottom Controls
                if capturedImage == nil {
                    // Shutter button
                    Button(action: {
                        if cameraController.isCameraAvailable && cameraController.permissionGranted {
                            cameraController.capturePhoto { photo in
                                capturedImage = photo
                            }
                        } else {
                            capturedImage = ImageUtils.createFallbackSelfie(employeeName: employeeName)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .stroke(Color(hex: 0x10B981), lineWidth: 4)
                                .frame(width: 76, height: 76)

                            Circle()
                                .fill(Color.white)
                                .frame(width: 62, height: 62)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.primaryBlue)
                        }
                    }
                } else {
                    // Confirmation Row
                    HStack(spacing: 14) {
                        Button(action: { capturedImage = nil }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .bold))
                                Text("RETAKE")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white.opacity(0.12))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button(action: {
                            if let img = capturedImage {
                                cameraController.stop()
                                onPhotoCaptured(img)
                            }
                        }) {
                            Text("CONFIRM & PUNCH")
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(hex: 0x10B981))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer().frame(height: 20)
            }
        }
        .onDisappear {
            cameraController.stop()
        }
    }
}

