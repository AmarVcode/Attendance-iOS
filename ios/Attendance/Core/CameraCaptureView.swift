import SwiftUI
import AVFoundation
import UIKit

/// High-performance AVFoundation front-camera controller with photo capture and fallback generation.
public final class CameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    public let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage) -> Void)?

    @Published public private(set) var isReady: Bool = false
    @Published public private(set) var isCameraAvailable: Bool = true
    @Published public private(set) var permissionGranted: Bool = false

    public override init() {
        super.init()
        checkPermissions()
    }

    public func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.permissionGranted = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        default:
            self.permissionGranted = false
            self.isCameraAvailable = false
        }
    }

    private func setupCamera() {
        guard !captureSession.isRunning else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo

            // Front camera discovery
            let discovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .front
            )

            guard let frontCamera = discovery.devices.first ?? AVCaptureDevice.default(for: .video) else {
                DispatchQueue.main.async {
                    self.isCameraAvailable = false
                }
                self.captureSession.commitConfiguration()
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: frontCamera)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                }

                if self.captureSession.canAddOutput(self.photoOutput) {
                    self.captureSession.addOutput(self.photoOutput)
                }

                self.captureSession.commitConfiguration()
                self.captureSession.startRunning()

                DispatchQueue.main.async {
                    self.isReady = true
                    self.isCameraAvailable = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isCameraAvailable = false
                }
                self.captureSession.commitConfiguration()
            }
        }
    }

    public func capturePhoto(completion: @escaping (UIImage) -> Void) {
        self.captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    public func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let originalImage = UIImage(data: data) else {
            return
        }

        // Mirror horizontally so the captured photo matches the live selfie preview
        let mirrored = originalImage.withHorizontallyFlippedOrientation()
        let scaled = ImageUtils.downscaleImage(mirrored, maxDimension: AppConfig.maxImageDimension)
        captureCompletion?(scaled)
    }
}

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer
public struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject public var cameraController: CameraController

    public init(cameraController: CameraController) {
        self.cameraController = cameraController
    }

    public func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = cameraController.captureSession
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    public func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    public class PreviewUIView: UIView {
        public override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }

        public var previewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
}

/// Image compression, scaling, and placeholder utilities matching ImageUtils.kt
public enum ImageUtils {
    public static func downscaleImage(_ image: UIImage, maxDimension: CGFloat = 1080) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let aspectRatio = size.width / size.height
        let newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    public static func saveImageToDocuments(_ image: UIImage, prefix: String = "punch") -> URL? {
        guard let data = image.jpegData(compressionQuality: AppConfig.jpegCompressionQuality) else {
            return nil
        }
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let selfiesDir = documents.appendingPathComponent("selfies", isDirectory: true)

        if !fileManager.fileExists(atPath: selfiesDir.path) {
            try? fileManager.createDirectory(at: selfiesDir, withIntermediateDirectories: true)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss_SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let filename = "\(prefix)_\(formatter.string(from: Date())).jpg"
        let fileURL = selfiesDir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }

    public static func createFallbackSelfie(employeeName: String) -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Slate Navy Background
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 1.0).setFill()
            context.fill(rect)

            // Employee Initials
            let initials = String(employeeName.trimmingCharacters(in: .whitespaces).prefix(2)).uppercased()
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 64, weight: .bold),
                .foregroundColor: UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 1.0)
            ]
            let titleSize = initials.size(withAttributes: titleAttrs)
            let titleRect = CGRect(x: (size.width - titleSize.width) / 2, y: 150, width: titleSize.width, height: titleSize.height)
            initials.draw(in: titleRect, withAttributes: titleAttrs)

            // Timestamp
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let timeStr = formatter.string(from: Date())
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .medium),
                .foregroundColor: UIColor.white
            ]
            let subSize = timeStr.size(withAttributes: subAttrs)
            let subRect = CGRect(x: (size.width - subSize.width) / 2, y: 240, width: subSize.width, height: subSize.height)
            timeStr.draw(in: subRect, withAttributes: subAttrs)
        }
    }
}

