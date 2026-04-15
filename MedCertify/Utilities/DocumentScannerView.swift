import SwiftUI
import VisionKit
import PDFKit

struct DocumentScannerView: UIViewControllerRepresentable {
    let onScanComplete: @MainActor (Data, String) -> Void
    let onCancel: @MainActor () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanComplete: onScanComplete, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScanComplete: @MainActor (Data, String) -> Void
        let onCancel: @MainActor () -> Void

        init(onScanComplete: @escaping @MainActor (Data, String) -> Void, onCancel: @escaping @MainActor () -> Void) {
            self.onScanComplete = onScanComplete
            self.onCancel = onCancel
        }

        nonisolated func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let pdfDocument = PDFDocument()

            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                if let pdfPage = PDFPage(image: image) {
                    pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
                }
            }

            let fileName = "Scan_\(Date().formatted(.dateTime.year().month().day().hour().minute()))"
            let pdfData = pdfDocument.dataRepresentation()
            let jpegData = scan.pageCount > 0 ? scan.imageOfPage(at: 0).jpegData(compressionQuality: 0.9) : nil

            guard let data = pdfData ?? jpegData else { return }

            Task { @MainActor in
                onScanComplete(data, fileName)
            }
        }

        nonisolated func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            Task { @MainActor in
                onCancel()
            }
        }

        nonisolated func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            Task { @MainActor in
                onCancel()
            }
        }
    }
}

