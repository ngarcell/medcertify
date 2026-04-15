import SwiftUI
import VisionKit
import PDFKit

/// VNDocumentCameraViewController wrapper for SwiftUI
struct DocumentScannerView: UIViewControllerRepresentable {
    var onScanComplete: (Data, String) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanComplete: onScanComplete, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScanComplete: (Data, String) -> Void
        let onCancel: () -> Void

        init(onScanComplete: @escaping (Data, String) -> Void, onCancel: @escaping () -> Void) {
            self.onScanComplete = onScanComplete
            self.onCancel = onCancel
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Combine all scanned pages into a single PDF
            let pdfDocument = PDFDocument()

            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                if let pdfPage = PDFPage(image: image) {
                    pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
                }
            }

            let fileName = "Scan_\(Date().formatted(.dateTime.year().month().day().hour().minute()))"

            if let pdfData = pdfDocument.dataRepresentation() {
                onScanComplete(pdfData, fileName)
            } else if let jpegData = scan.imageOfPage(at: 0).jpegData(compressionQuality: 0.9) {
                // Fallback: save first page as JPEG
                onScanComplete(jpegData, fileName)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document scanning failed: \(error)")
            onCancel()
        }
    }
}

