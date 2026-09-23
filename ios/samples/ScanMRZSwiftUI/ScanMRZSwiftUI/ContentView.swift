//
//  ContentView.swift
//  ScanMRZSwiftUI
//

import SwiftUI
import DynamsoftMRZScannerBundle

/// Everything the result screen needs, lifted off the scan result as plain UIImages so
/// the route carries no SDK types.
///
/// This rides *inside* the navigation route rather than in separate `@State`: `NavigationStack`
/// can evaluate the destination before companion state lands, rendering an empty first push.
struct ScanPayload: Hashable, Identifiable {
    let id = UUID()
    let data: MRZData
    let portraitImage: UIImage?
    let primaryDocumentImage: UIImage?
    let primaryOriginalImage: UIImage?
    let secondaryDocumentImage: UIImage?
    let secondaryOriginalImage: UIImage?

    // Identity is the payload's own id — hashing the images themselves would be both
    // expensive and meaningless for navigation.
    static func == (lhs: ScanPayload, rhs: ScanPayload) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Screens pushed on top of home.
enum Route: Hashable {
    case scanner
    case result(ScanPayload)
}

struct ContentView: View {

    @State private var path: [Route] = []
    /// Cancellation / error text shown in the middle of the home screen.
    @State private var message: String = ""
    /// A user-denied camera permission is the one failure the user can resolve in
    /// Settings, so only that message gets a route there.
    @State private var showSettingsAction: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text(message)
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    if showSettingsAction {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Open Settings")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 180, height: 44)
                                .background(Color.black)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 30)

                VStack {
                    Spacer()
                    Button {
                        message = ""
                        showSettingsAction = false
                        path.append(.scanner)
                    } label: {
                        Text("Scan an MRZ")
                            .foregroundColor(.white)
                            .frame(width: 150, height: 50)
                            .background(Color.black)
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 10)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .scanner:
                    // The scanner draws its own close/torch controls, so it takes the
                    // whole screen with the navigation bar hidden — matching the UIKit
                    // sample, which hides the bar while the scanner is pushed.
                    MRZScannerView(onScannedResult: handle(result:))
                        .ignoresSafeArea()
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationBarBackButtonHidden(true)
                case .result(let payload):
                    ResultView(
                        payload: payload,
                        onRescan: { if !path.isEmpty { path.removeLast() } },
                        onReturnHome: { path.removeAll() }
                    )
                }
            }
        }
    }

    /// `onScannedResult` arrives off the main thread. Build the payload here, before the
    /// hop — with `returnOriginalImage` on, converting full frames on main stalls the UI.
    private func handle(result: MRZScanResult) {
        let payload = result.data.map {
            ScanPayload(
                data: $0,
                portraitImage: try? result.getPortraitImage()?.toUIImage(),
                primaryDocumentImage: try? result.getDocumentImage(.mrz)?.toUIImage(),
                primaryOriginalImage: try? result.getOriginalImage(.mrz)?.toUIImage(),
                secondaryDocumentImage: try? result.getDocumentImage(.opposite)?.toUIImage(),
                secondaryOriginalImage: try? result.getOriginalImage(.opposite)?.toUIImage()
            )
        }
        DispatchQueue.main.async { apply(result, payload) }
    }

    /// Handles the three statuses a scan can end in. A finished scan pushes the result
    /// screen on top of the scanner, so "Re-scan" is a plain pop; the others unwind home.
    private func apply(_ result: MRZScanResult, _ payload: ScanPayload?) {
        switch result.resultStatus {
        case .finished:
            guard let payload else {
                // Nothing to show, so don't strand the user on the scanner.
                report("Scan returned no data")
                return
            }
            path.append(.result(payload))
        case .canceled:
            // The user closed the scanner. There is no data and nothing went wrong.
            report("Scan canceled")
        case .exception:
            report(result.errorString ?? "")
            // Offer Settings only for a user-denied permission. A camera withheld by
            // policy reports cameraPermissionRestricted instead, and in that state the
            // per-app camera toggle is absent from Settings — so sending the user there
            // would be a dead end.
            showSettingsAction = result.errorCode == ErrorCode.cameraPermissionDenied.rawValue
        @unknown default:
            break
        }
    }

    /// Leaves `message` on the home screen and unwinds to it from the scanner.
    private func report(_ text: String) {
        message = text
        path.removeAll()
    }
}

#Preview {
    ContentView()
}
