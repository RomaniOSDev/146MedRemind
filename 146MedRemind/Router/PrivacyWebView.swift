//
//  PrivacyWebView.swift
//  146MedRemind
//

import SwiftUI
import WebKit

struct MedEmbeddedBrowserScreen: View {
    let urlString: String
    var onFailure: () -> Void
    var onSuccess: (() -> Void)? = nil

    @State private var webView: WKWebView = WKWebView()
    @State private var canGoBack: Bool = false
    @State private var isLoading: Bool = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        webView.goBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(canGoBack ? .white : .gray)
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                    }
                    .disabled(!canGoBack)

                    Spacer()

                    Button(action: {
                        webView.reload()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                    }
                }
                .frame(height: 60)
                .background(Color.black)

                MedWKHostRepresentable(
                    webView: webView,
                    urlString: urlString,
                    canGoBack: $canGoBack,
                    isLoading: $isLoading,
                    onFailure: onFailure,
                    onSuccess: onSuccess
                )
            }
            .ignoresSafeArea()
            .statusBar(hidden: true)

            if isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2.0)
                }
            }
        }
    }
}

struct MedWKHostRepresentable: UIViewRepresentable {
    let webView: WKWebView
    let urlString: String
    @Binding var canGoBack: Bool
    @Binding var isLoading: Bool
    var onFailure: () -> Void
    var onSuccess: (() -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.backgroundColor = .black
        webView.isOpaque = false

        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        webView.allowsBackForwardNavigationGestures = true

        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> NavigationBridge {
        NavigationBridge(parent: self)
    }

    final class NavigationBridge: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: MedWKHostRepresentable
        private var failureCalled = false

        init(parent: MedWKHostRepresentable) {
            self.parent = parent
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            if let httpResponse = navigationResponse.response as? HTTPURLResponse {
                if MedRouteSessionStore.shared.persistedDestinationRaw == nil && !failureCalled {
                    if (400...599).contains(httpResponse.statusCode) {
                        failureCalled = true
                        MedRouteSessionStore.shared.nativeShellPresentedFlag = true
                        decisionHandler(.cancel)

                        DispatchQueue.main.async {
                            self.parent.onFailure()
                        }
                        return
                    }
                }
            }
            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if let url = navigationAction.request.url {
                if let scheme = url.scheme, MedRouteCipher.ExternalScheme.outboundSet.contains(scheme) {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.canGoBack = webView.canGoBack
            parent.isLoading = false

            if MedRouteSessionStore.shared.persistedDestinationRaw == nil {
                if let currentUrl = webView.url?.absoluteString {
                    MedRouteSessionStore.shared.persistedDestinationRaw = currentUrl
                    MedRouteSessionStore.shared.remoteDocumentReadyFlag = true
                    DispatchQueue.main.async {
                        self.parent.onSuccess?()
                    }
                }
            } else {
                MedRouteSessionStore.shared.remoteDocumentReadyFlag = true
                DispatchQueue.main.async {
                    self.parent.onSuccess?()
                }
            }
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            parent.isLoading = false

            if MedRouteSessionStore.shared.persistedDestinationRaw == nil && !failureCalled {
                failureCalled = true

                MedRouteSessionStore.shared.nativeShellPresentedFlag = true
                DispatchQueue.main.async {
                    self.parent.onFailure()
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}
