import Cocoa

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        MSAppCenter.start("dca3b9dd-3c61-4eae-93fe-84a1e5fc55b5", withServices:[
            MSAnalytics.self,
            MSCrashes.self
        ])
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
