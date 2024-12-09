import SwiftUI
import AVFoundation

struct QRCodeScannerView: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        <#code#>
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRCodeScannerView

        init(parent: QRCodeScannerView) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                found(code: stringValue)
            }
        }

        func found(code: String) {
            print("QR code Found: \(code)")
            parent.didFindCode(code)
        }
    }

    var didFindCode: (String) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("Couldn't access camera.")
            return viewController
        }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Error creating video input: \(error)")
            return viewController
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            print("Could not add video input.")
            return viewController
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            print("Failed to add metadata output.")
            return viewController
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        let bounds = viewController.view.bounds
        let height = bounds.height - 90
        let width = bounds.width

        
        previewLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)

        let titleLabel = UILabel()
        titleLabel.text = "EstacionaTEC"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .white
        titleLabel.frame = CGRect(x: 0, y: 40, width: viewController.view.frame.width, height: 50)
        viewController.view.addSubview(titleLabel)

        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }

        return viewController
    }

}
