//
//  ContentView.swift
//  ScanMRZBasicSwiftUI
//

import SwiftUI
import DynamsoftMRZScannerBundle
import DynamsoftCaptureVisionBundle

/// Everything the result section shows, captured off the scan result before the SDK
/// releases its native image handles.
private struct ScannedDocument {
    let data: MRZData
    let portrait: UIImage?
}

/// Presents the built-in MRZ scanner and renders the result on this same screen.
///
/// The whole sample is this one view plus the `MRZScannerView` bridge. See the
/// ScanMRZSwiftUI sample for a fuller app: document images, per-field explanations
/// and permission recovery.
struct ContentView: View {

    /// Amber (#FFC107) marks a value that does not match its check digit.
    private static let warningAmber = Color(red: 1, green: 193 / 255, blue: 7 / 255)

    @State private var isScanning = false
    /// Canceled message or error string, shown in place of the fields.
    @State private var status = ""
    @State private var scanned: ScannedDocument?

    var body: some View {
        // Deliberately plain: results scroll above a scan button pinned below them.
        // Styling belongs in the ScanMRZSwiftUI sample, not here.
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !status.isEmpty {
                        Text(status)
                    }
                    if let scanned = scanned {
                        results(for: scanned)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }

            Button {
                isScanning = true
            } label: {
                Text("Scan an MRZ")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            .padding()
        }
        .fullScreenCover(isPresented: $isScanning) {
            MRZScannerView(onScannedResult: handle(result:))
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func results(for scanned: ScannedDocument) -> some View {
        let data = scanned.data

        // The portrait is returned by default, but is nil when none could be cropped.
        if let portrait = scanned.portrait {
            Image(uiImage: portrait)
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 128)
        }

        // Validation is per field, so a full name that joins two of them is flagged
        // when either half fails.
        let firstNameStatus = data.getFieldValidationStatus("firstName")
        let nameStatus = firstNameStatus == .failed
            ? firstNameStatus
            : data.getFieldValidationStatus("lastName")

        field("Full Name",
              "\(data.firstName) \(data.lastName)".trimmingCharacters(in: .whitespaces),
              nameStatus)
        field("Document Number", data.documentNumber,
              data.getFieldValidationStatus("documentNumber"))
        field("Nationality", data.nationality,
              data.getFieldValidationStatus("nationality"))
        field("Date of Birth", data.dateOfBirth,
              data.getFieldValidationStatus("dateOfBirth"))
        field("Date of Expiry", data.dateOfExpire,
              data.getFieldValidationStatus("dateOfExpire"))
        // The document type comes from the MRZ layout itself, so it has no check digit.
        field("Document Type", data.documentType)
        field("Raw MRZ Text", data.mrzText,
              data.getFieldValidationStatus("mrzText"), monospaced: true)
    }

    /// A caption and its value, or "N/A" when the parser extracted nothing. A value
    /// that failed its check digit is colored amber.
    private func field(_ caption: String,
                       _ value: String,
                       _ status: ValidationStatus = .none,
                       monospaced: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(caption)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value.isEmpty ? "N/A" : value)
                .font(monospaced ? .system(.footnote, design: .monospaced) : .headline)
                .foregroundColor(status == .failed ? Self.warningAmber : .primary)
        }
    }

    /// Renders one of the three result statuses the scanner can come back with.
    /// `onScannedResult` arrives off the main thread, so every state change hops first.
    private func handle(result: MRZScanResult) {
        switch result.resultStatus {
        case .finished:
            guard let data = result.data else { return }
            let document = ScannedDocument(
                data: data,
                portrait: try? result.getPortraitImage()?.toUIImage()
            )
            DispatchQueue.main.async {
                status = ""
                scanned = document
                isScanning = false
            }
        case .canceled:
            // The user closed the scanner. There is no data and nothing went wrong.
            DispatchQueue.main.async {
                status = "Scan canceled"
                scanned = nil
                isScanning = false
            }
        case .exception:
            // The scanner asks for camera access itself, so a denial lands here as a
            // readable error string — this sample needs no permission code of its own.
            let errorString = result.errorString ?? ""
            DispatchQueue.main.async {
                status = errorString
                scanned = nil
                isScanning = false
            }
        @unknown default:
            break
        }
    }
}

#Preview {
    ContentView()
}
