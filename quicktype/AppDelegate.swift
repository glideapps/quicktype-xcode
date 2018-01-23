import Cocoa

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let issuesUrl = URL(string: "https://github.com/quicktype/quicktype-xcode/issues/new")!
    
    func showDialog() -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = "Paste JSON a Code for Xcode activated"
        alert.informativeText = "Enable the extension in System Preferences → Extensions, then find \"Paste JSON as\" in Xcode's Editor menu."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Ok")
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Report Issue…")
        return alert.runModal()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        MSAppCenter.start("dca3b9dd-3c61-4eae-93fe-84a1e5fc55b5", withServices:[
            MSAnalytics.self,
            MSCrashes.self
        ])
        
        switch showDialog() {
        case .alertSecondButtonReturn:
            MSAnalytics.trackEvent("open system preferences")
            NSWorkspace.shared.openFile("/System/Library/PreferencePanes/Extensions.prefPane")
            break;
        case .alertThirdButtonReturn:
            MSAnalytics.trackEvent("report issue")
            NSWorkspace.shared.open(issuesUrl)
            break;
        default:
            break;
        }
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func showHelp(_ sender: Any) {
        NSWorkspace.shared.open(issuesUrl)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
