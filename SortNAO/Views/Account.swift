//
//  Account.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/16.
//

import SwiftUI
import WebKit

// https://saucenao.com/user.php

let accountPageURL = URL(string: "https://saucenao.com/user.php")!
let loginPageURL = URL(string: "https://saucenao.com/user.php?page=login")!
let logoutPageURL = URL(string: "https://saucenao.com/user.php?page=logout")!

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
            let processPageJS = """
// Tweak site width
const meta = document.createElement("meta");
meta.name = "viewport";
meta.content = "width=device-width, initial-scale=1, maximum-scale=1.0, user-scalable=0";
document.head.appendChild(meta);

// Tweak global font

const styleSheet = document.styleSheets[0]
styleSheet.insertRule("* { font-family: sans-serif; font-size: 1rem; }", styleSheet.cssRules.length)

// Remove purchase options

var settingsMenuItems = document.getElementsByClassName("settingsmenuitem")
Array.from(settingsMenuItems).forEach(settingsMenuItem => {
    let textContent = settingsMenuItem.textContent
    if (textContent === "upgrades" || textContent === "exit") {
        settingsMenuItem.remove()
    }
})

// Remove account creation option

var loginFormLinks = document.getElementsByTagName("a")
Array.from(loginFormLinks).forEach(loginFormLink => {
    let textContent = loginFormLink.textContent
    if (textContent.includes("Reset Password")) {
        while (loginFormLink.nextSibling) {
            loginFormLink.nextSibling.remove()
        }
    }
})

// Remove API information

var pageLinks = document.getElementsByTagName("p")
Array.from(pageLinks).forEach(pageLink => {
    let textContent = pageLink.textContent
    if (textContent.includes("Index Details:") ||
        textContent.includes("Example JSON Output:") ||
        textContent.includes("Example Script:")) {
        pageLink.remove()
    }
})

var pageDivs = document.getElementsByTagName("div")
Array.from(pageDivs).forEach(pageDiv => {
    let textContent = pageDiv.textContent
    if (textContent.includes("api is in beta")) {
        let form = pageDiv.querySelector("form")
        if (form) {
            while (form.nextSibling) {
                form.nextSibling.remove()
            }
        }
    }
})

// Tweak login form

var inputFormItems = document.getElementsByClassName("input-form")
Array.from(inputFormItems).forEach(formItem => {
    formItem.setAttribute("style", "margin-left: 20px !important;")
})

var inputItems = document.getElementsByTagName("input")
Array.from(inputItems).forEach(inputItem => {
    if (inputItem.type === "text" || inputItem.type === "password") {
        inputItem.size = "30"
    }
})

var googleRecaptchaItems = document.getElementsByClassName("g-recaptcha")
Array.from(googleRecaptchaItems).forEach(googleRecaptchaItem => {
    googleRecaptchaItem.style = ""
})

// Tweak sizes

var mainArea = document.getElementById("mainarea")
mainArea.setAttribute("style", `
    max-width: 100vw;
    min-width: 100vw;
`)

var leftMenuItem = document.getElementById("left")
leftMenuItem.setAttribute("style", "width: 100px !important;")

var middleAreaItem = document.getElementById("middle")
middleAreaItem.setAttribute("style", `
    display: flex;
    flex-direction: column;
    margin-left: 100px !important;
    text-align: left !important;
`)

// Remove redesign banner

document.getElementById("headerarea").remove()
"""

            func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                guard let webViewURL = webView.url else { return }
                let urlString = webViewURL.absoluteString
                webView.evaluateJavaScript(self.processPageJS) { _, _ in
                    switch urlString {
                    case accountPageURL.absoluteString:
                        webView.layer.opacity = 1.0
                    case loginPageURL.absoluteString, logoutPageURL.absoluteString:
                        webView.load(URLRequest(url: accountPageURL))
                    default:
                        if !urlString.starts(with: accountPageURL.absoluteString) {
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
