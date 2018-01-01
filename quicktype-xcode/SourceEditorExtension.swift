import Foundation
import XcodeKit

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    func extensionDidFinishLaunching() {
        MSAppCenter.start("dca3b9dd-3c61-4eae-93fe-84a1e5fc55b5", withServices:[
            MSAnalytics.self,
            MSCrashes.self
        ])
        
        if !Runtime.shared.initialize() {
            print("Could not initialize quicktype JavaScript runtime")
        }
    }
}
