//
//  Account.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/16.
//

import SwiftUI
import WebKit

struct Account: View {
    var body: some View {
        WebView()
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .background {
                ProgressView()
            }
    }

    struct WebView: UIViewRepresentable {

        let webView = WKWebView()

        func makeUIView(context: Context) -> WKWebView {
            #if DEBUG
            webView.isInspectable = true
            #endif

            webView.navigationDelegate = context.coordinator
            webView.layer.opacity = 0.0
            webView.load(URLRequest(url: URL(string: "https://saucenao.com/user.php")!))
            return webView
        }

        func makeCoordinator() -> Coordinator { Coordinator() }
        func updateUIView(_ uiView: WKWebView, context: Context) { }

        // swiftlint:disable nesting
        class Coordinator: NSObject, WKNavigationDelegate {

            func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
                webView.layer.opacity = 0.0
            }

            func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                guard let webViewURL = webView.url else { return }
                let urlString = webViewURL.absoluteString
                webView.evaluateJavaScript(processPageJS) { _, _ in
                    switch urlString {
                    case loginPageURL.absoluteString, logoutPageURL.absoluteString:
                        webView.load(URLRequest(url: accountPageURL))
                    default:
                        if !urlString.starts(with: accountPageURL.absoluteString) &&
                            !urlString.starts(with: cloudflareChallengeURL.absoluteString) {
                            webView.load(URLRequest(url: accountPageURL))
                        } else {
                            webView.layer.opacity = 1.0
                        }
                    }
                }
            }
        }
        // swiftlint:enable nesting
    }

}
