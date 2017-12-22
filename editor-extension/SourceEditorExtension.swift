import Foundation
import XcodeKit

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    func extensionDidFinishLaunching() {
        if !Runtime.shared.initialize() {
            print("Could not initialize quicktype JavaScript runtime")
        }
    }
}
