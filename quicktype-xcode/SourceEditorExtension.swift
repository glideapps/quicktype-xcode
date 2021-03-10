import Foundation
import XcodeKit

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    func extensionDidFinishLaunching() {
        AppCenter.start(withAppSecret: "dca3b9dd-3c61-4eae-93fe-84a1e5fc55b5", services: [ Analytics.self,Crashes.self ])
        
        Analytics.trackEvent("extensionDidFinishLaunching")
        
        if !Runtime.shared.initialize() {
            print("Could not initialize quicktype JavaScript runtime")
        }
    }
}
