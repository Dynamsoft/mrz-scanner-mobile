//
//  ResultView.swift
//  ScanMRZSwiftUI
//
//  SwiftUI port of the UIKit sample's ResultViewController.
//

import SwiftUI
import DynamsoftMRZScannerBundle
// ValidationStatus is declared by the Capture Vision bundle, not the MRZ bundle.
import DynamsoftCaptureVisionBundle

struct ResultView: View {

    let payload: ScanPayload
    let onRescan: () -> Void
    let onReturnHome: () -> Void

    /// Amber (#FFC107) used to color values whose MRZ check digit failed.
    private static let warningAmber = Color(red: 1.0, green: 193.0 / 255.0, blue: 7.0 / 255.0)
    private static let rowFontSize: CGFloat = 14

    @State private var isProcessedSelected = true
    @State private var showValidationInfo = false

    @State private var imageToSave: UIImage?
    @State private var showSaveConfirmation = false
    @State private var saveOutcome: SaveOutcome?

    // @State keeps the saver alive across re-renders; the save call does not retain it.
    @State private var imageSaver = ImageSaver()

    private var data: MRZData { payload.data }

    private var hasProcessed: Bool {
        payload.primaryDocumentImage != nil || payload.secondaryDocumentImage != nil
    }
    private var hasOriginal: Bool {
        payload.primaryOriginalImage != nil || payload.secondaryOriginalImage != nil
    }
    private var hasAnyImage: Bool { hasProcessed || hasOriginal }
    /// Tabs only when there are two sets to switch between; one set gets a plain header.
    private var showBothSegments: Bool { hasProcessed && hasOriginal }
    /// Obeys the switch only when there are two sets to choose between, else follows what exists.
    private var showingProcessed: Bool { showBothSegments ? isProcessedSelected : hasProcessed }

    /// Sex can be empty when the field wasn't parsed — `.capitalized` returns "" safely.
    private var genderText: String { data.sex.capitalized }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    if hasAnyImage {
                        if showBothSegments { segmentedControl } else { imagesHeader }
                        documentImages
                    }
                    section(title: "Personal Info", rows: personalInfoRows)
                    section(title: "Document Info", rows: documentInfoRows)
                    rawMRZSection
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .padding(.bottom, 24)
            .alert(saveOutcome?.title ?? "", isPresented: saveOutcomeBinding) {
                Button("OK", role: .cancel) { saveOutcome = nil }
            } message: {
                Text(saveOutcome?.message ?? "")
            }

            bottomButtons
        }
        .background(Color.black)
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Field validation warning", isPresented: $showValidationInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This value doesn't match its check digit. The document may be invalid or altered.")
        }
        .confirmationDialog("Save Image", isPresented: $showSaveConfirmation, titleVisibility: .visible) {
            Button("Save") { saveImage() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Would you like to save this image to your photos?")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            // No validation highlighting here: a compound line ("gender, age") tinted on one
            // field's status would imply both are invalid. The sections below do it per field.
            VStack(alignment: .leading, spacing: 4) {
                // Match UIKit's single-line default: a long name truncates rather than
                // wrapping and pushing the rest of the screen down.
                Text("\(data.firstName) \(data.lastName)".trimmingCharacters(in: .whitespaces))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(genderText), \(data.age) years old\nExpiry: \(data.dateOfExpire)")
                    .font(.system(size: 14))
                    .foregroundColor(Color(UIColor.lightGray))
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            portrait
        }
        .padding(.horizontal, 20)
    }

    private var portrait: some View {
        Group {
            // The portrait is returned by default, but is nil when none could be cropped —
            // a TD1/TD2 ID scanned MRZ-side only, for instance. Fall back to the placeholder.
            if let portraitImage = payload.portraitImage {
                Image(uiImage: portraitImage).resizable()
            } else {
                Image("user").resizable()
            }
        }
        .frame(width: 88, height: 100)
        .background(Color(UIColor.darkGray))
        .onLongPressGesture { promptSave(payload.portraitImage) }
    }

    // MARK: - Processed / Original

    /// Stands in for the tabs when only one set came back, styled like the sections below.
    private var imagesHeader: some View {
        Text(hasProcessed ? "Processed Image(s)" : "Original Image(s)")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
    }

    /// Only rendered when both sets exist, so both segments are always present here.
    private var segmentedControl: some View {
        HStack(spacing: 16) {
            segmentButton(title: "Processed", selected: showingProcessed) {
                isProcessedSelected = true
            }
            segmentButton(title: "Original", selected: !showingProcessed) {
                isProcessedSelected = false
            }
        }
        .frame(height: 30)
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    /// Both segments take the width of the wider title, sitting as a compact centered group.
    /// Measuring the widest title avoids both stretching to full width and hardcoding a number.
    private static let segmentWidth: CGFloat = {
        let font = UIFont.systemFont(ofSize: 14)
        return ceil(["Processed", "Original"]
            .map { ($0 as NSString).size(withAttributes: [.font: font]).width }
            .max() ?? 0)
    }()

    private func segmentButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 2) {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(selected ? .white : Color(UIColor.gray))
                    .frame(width: Self.segmentWidth)
            }
            Rectangle()
                .fill(selected ? Color.white : Color.clear)
                .frame(width: Self.segmentWidth, height: 2)
        }
        .frame(width: Self.segmentWidth)
    }

    private var documentImages: some View {
        HStack(spacing: 16) {
            documentImage(showingProcessed ? payload.primaryDocumentImage : payload.primaryOriginalImage)
            documentImage(showingProcessed ? payload.secondaryDocumentImage : payload.secondaryOriginalImage)
        }
        .frame(height: 160)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    @ViewBuilder
    private func documentImage(_ image: UIImage?) -> some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .onLongPressGesture { promptSave(image) }
        }
    }

    // MARK: - Info sections

    private var personalInfoRows: [InfoRow] {
        [
            InfoRow("Given Name",   data.firstName,      data.getFieldValidationStatus("firstName")),
            InfoRow("Surname",      data.lastName,       data.getFieldValidationStatus("lastName")),
            InfoRow("Date of Birth",data.dateOfBirth,    data.getFieldValidationStatus("dateOfBirth")),
            InfoRow("Gender",       genderText,          data.getFieldValidationStatus("sex")),
            InfoRow("Nationality",  data.nationalityRaw, data.getFieldValidationStatus("nationality")),
        ]
    }

    private var documentInfoRows: [InfoRow] {
        [
            // Doc Type is derived from codeType — not independently validated.
            InfoRow("Doc. Type",   data.documentType == "MRTD_TD3_PASSPORT" ? "Passport" : "ID", .none),
            InfoRow("Doc. Number", data.documentNumber, data.getFieldValidationStatus("documentNumber")),
            InfoRow("Expiry Date", data.dateOfExpire,   data.getFieldValidationStatus("dateOfExpire")),
        ]
    }

    private func section(title: String, rows: [InfoRow]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            VStack(spacing: 12) {
                ForEach(rows) { row in infoRowView(row) }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private func infoRowView(_ row: InfoRow) -> some View {
        let failed = row.status == .failed
        let display = row.value.isEmpty ? "N/A" : row.value
        // UIKit pins the label to exactly half the row width and starts the value 8pt past
        // it, so the halves butt together and the value carries the inset itself.
        return HStack(spacing: 0) {
            Text(row.label)
                .font(.system(size: Self.rowFontSize))
                .foregroundColor(Color(UIColor.lightGray))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            valueText(display, failed: failed)
                .font(.system(size: Self.rowFontSize))
                .foregroundColor(failed ? Self.warningAmber : .white)
                .lineLimit(1)
                .padding(.leading, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 20)
        .contentShape(Rectangle())
        .modifier(ValidationTap(active: failed) { showValidationInfo = true })
        .accessibilityLabel(failed ? "\(row.label), \(display), validation failed" : "\(row.label), \(display)")
    }

    private var rawMRZSection: some View {
        // Tappable too: a line-composite failure can flag the raw MRZ when no individual
        // field failed — corruption in a field without its own check digit, say.
        let status = data.getFieldValidationStatus("mrzText")
        let failed = status == .failed
        let display = data.mrzText.isEmpty ? "N/A" : data.mrzText
        return VStack(alignment: .leading, spacing: 12) {
            Text("Raw MRZ Text")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            valueText(display, failed: failed, fontSize: 12)
                .font(.system(size: 12))
                .foregroundColor(failed ? Self.warningAmber : Color(UIColor.lightGray))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .modifier(ValidationTap(active: failed) { showValidationInfo = true })
                .accessibilityLabel(failed ? "\(display), validation failed" : display)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    /// Renders a value, underlined and followed by an inline amber icon when validation failed.
    ///
    /// The icon is drawn at 1.0x the font size: SwiftUI has no attachment box to inset the
    /// glyph within, so UIKit's 1.2x would render a visibly larger circle here.
    private func valueText(_ text: String, failed: Bool, fontSize: CGFloat = ResultView.rowFontSize) -> Text {
        guard failed else { return Text(text) }
        // The separating spaces stay outside the underline, as in the UIKit sample.
        return Text(text).underline()
            + Text("  ")
            + Text(Image(systemName: "exclamationmark.circle.fill"))
                .font(.system(size: fontSize))
    }

    // MARK: - Bottom buttons

    private var bottomButtons: some View {
        HStack(spacing: 16) {
            Button(action: onRescan) {
                bottomLabel(icon: "rescan", title: "Re-scan", tint: .white)
                    .background(Color.white.opacity(0.2))
            }
            Button(action: onReturnHome) {
                bottomLabel(icon: "return", title: "Return home", tint: .black)
                    .background(Color.white)
            }
        }
        .frame(height: 48)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color.black)
    }

    private func bottomLabel(icon: String, title: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(icon).renderingMode(.template)
            Text(title).font(.system(size: 14))
        }
        .foregroundColor(tint)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Save to Photos

    private func promptSave(_ image: UIImage?) {
        guard let image else { return }
        imageToSave = image
        showSaveConfirmation = true
    }

    private var saveOutcomeBinding: Binding<Bool> {
        Binding(get: { saveOutcome != nil }, set: { if !$0 { saveOutcome = nil } })
    }

    private func saveImage() {
        guard let image = imageToSave else { return }
        imageSaver.onComplete = { error in
            if let error {
                saveOutcome = .failure(error.localizedDescription)
            } else {
                saveOutcome = .success
                // The UIKit sample auto-dismisses the confirmation after 1.5s.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if case .success = saveOutcome { saveOutcome = nil }
                }
            }
        }
        imageSaver.save(image)
    }
}

/// Result of a save-to-Photos attempt, driving a single alert.
enum SaveOutcome: Equatable {
    case success
    case failure(String)

    var title: String {
        switch self {
        case .success: return "Saved!"
        case .failure: return "Save Error"
        }
    }

    var message: String {
        switch self {
        case .success: return "The image has been saved to your library."
        case .failure(let description): return description
        }
    }
}

/// One label/value pair in the Personal Info or Document Info section.
struct InfoRow: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let status: ValidationStatus

    init(_ label: String, _ value: String, _ status: ValidationStatus) {
        self.label = label
        self.value = value
        self.status = status
    }
}

/// Attaches a tap handler only when the row actually failed validation, so passing rows
/// stay non-interactive exactly as in the UIKit sample.
private struct ValidationTap: ViewModifier {
    let active: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        if active {
            content.onTapGesture(perform: action)
        } else {
            content
        }
    }
}

/// `UIImageWriteToSavedPhotosAlbum` reports through an Objective-C selector, so it needs
/// an NSObject to call back into.
final class ImageSaver: NSObject {
    var onComplete: ((Error?) -> Void)?

    func save(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(
            image, self, #selector(didFinishSaving(_:didFinishSavingWithError:contextInfo:)), nil
        )
    }

    @objc private func didFinishSaving(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async { self.onComplete?(error) }
    }
}
