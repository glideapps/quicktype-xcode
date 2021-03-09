import Cocoa
import WebKit

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate {
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var webView: WKWebView!
    
    let repoUrl = URL(string: "https://github.com/quicktype/quicktype")!
    let issuesUrl = URL(string: "https://github.com/quicktype/quicktype-xcode/issues/new")!
    let aboutUrl = URL(string: "https://quicktype.io")!
    let appUrl = URL(string: "https://app.quicktype.io/#l=swift&context=xcode")!
    
    func showDialog() {
        let alert = NSAlert()
        alert.messageText = "quicktype's Xcode extension is ready to use"
        alert.informativeText = "Enable the extension in System Preferences → Extensions, then find \"Paste JSON as\" in Xcode's Editor menu."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Ok")
        alert.addButton(withTitle: "Open System Preferences")
        
        alert.beginSheetModal(for: window) {
            switch $0 {
            case .alertSecondButtonReturn:
                Analytics.trackEvent("open system preferences")
                NSWorkspace.shared.openFile("/System/Library/PreferencePanes/Extensions.prefPane")
                break;
            case .alertThirdButtonReturn:
                break;
            default:
                break;
            }
        }
    }
    
    @IBAction func openGitHub(_ sender: Any) {
        Analytics.trackEvent("view on GitHub")
        NSWorkspace.shared.open(repoUrl)
    }
    
    @IBAction func showAbout(_ sender: Any) {
        Analytics.trackEvent("about")
        NSWorkspace.shared.open(aboutUrl)
    }
    
    @IBAction func showHelp(_ sender: Any) {
        Analytics.trackEvent("report issue")
        NSWorkspace.shared.open(self.issuesUrl)
    }
    
    var isFirstRun: Bool {
        get { return !UserDefaults.standard.bool(forKey: "hasRunBefore")  }
        set(value) { UserDefaults.standard.set(!value, forKey: "hasRunBefore") }
    }
    
    func openExternalLink(_ navigationAction: WKNavigationAction) {
        if let url = navigationAction.request.url {
            Analytics.trackEvent("open link", withProperties: ["link": url.absoluteString])
            NSWorkspace.shared.open(url)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        func isExternal(_ url: URL) -> Bool {
            let s = url.absoluteString
            return s.starts(with: "http") && !s.starts(with: "https://app.quicktype.io")
        }

        if let url = navigationAction.request.url {
            if isExternal(url) {
                openExternalLink(navigationAction)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            openExternalLink(navigationAction)
        }
        return nil
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppCenter.start(withAppSecret: "dca3b9dd-3c61-4eae-93fe-84a1e5fc55b5", services:[
            Analytics.self,
            Crashes.self
        ])
        
        window.makeKeyAndOrderFront(self)
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.load(URLRequest(url: appUrl))
        
        if isFirstRun {
            showDialog()
            isFirstRun = false
        }
    }
}
