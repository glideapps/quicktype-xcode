import Foundation
import AppKit

import XcodeKit

typealias Invocation = XCSourceEditorCommandInvocation

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    func error(_ message: String, details: String = "No details") -> NSError {
        return NSError(domain: "quicktype", code: 1, userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString(message, comment: ""),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString(details, comment: "")
        ])
    }
    
    func getFirstSelection(_ invocation: Invocation) -> XCSourceTextRange? {
        for range in invocation.buffer.selections {
            guard let range = range as? XCSourceTextRange else {
                continue
            }
            return range
        }
        return nil
    }
    
    func cleanGeneratedLines(_ lines: [String], _ invocation: Invocation) -> [String] {
        var cleaned = lines
        
        func isImportCommentOrEmpty(line: String) -> Bool {
            if line.starts(with: "//") {
                return true
            }
            
            if line.starts(with: "import ") {
                return true
            }
            
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty
        }
        
        // Remove leading imports, comments, whitespace from start and end
        cleaned = Array(cleaned
            .drop(while: isImportCommentOrEmpty)
            .reversed().drop(while: isImportCommentOrEmpty).reversed()
        )
        
        return cleaned
    }
    
    func handleSuccess(lines: [String], _ invocation: Invocation, _ completionHandler: @escaping (Error?) -> Void) {
        let buffer = invocation.buffer
        let cleanLines = cleanGeneratedLines(lines, invocation)
        let selection = getFirstSelection(invocation) ?? XCSourceTextRange()
        
        let selectedIndices = selection.start.line...selection.end.line
        if selection.start.line != selection.end.line || selection.start.column != selection.end.column {
            buffer.lines.removeObjects(at: IndexSet(selectedIndices))
        }
        
        let insertedIndices = selection.start.line..<(selection.start.line + cleanLines.count)
        buffer.lines.insert(cleanLines, at: IndexSet(insertedIndices))
        
        // Clear any selections
        buffer.selections.removeAllObjects()
        let cursorPosition = XCSourceTextPosition(line: selection.start.line, column: 0)
        buffer.selections.add(XCSourceTextRange(start: cursorPosition, end: cursorPosition))
        
        completionHandler(nil)
    }
    
    func handleError(message: String, _ invocation: Invocation, _ completionHandler: @escaping (Error?) -> Void) {
        // Sometimes an error ruins our Runtime, so let's reinitialize it
        print("quicktype encountered an error: \(message)")
        if Runtime.shared.initialize() {
            print("quicktype runtime reinitialized")
        } else {
            print("quicktype runtime could not be reinitialized")
        }
        
        completionHandler(error("quicktype encountered an internal error", details: message))
    }
    
    func isValidJson(_ json: String) -> Bool {
        let objectData = """
            {
                "sample": \(json)
            }
        """.data(using: .utf8)!
        
        if let _ = try? JSONSerialization.jsonObject(with: objectData, options: []) as? [String: Any] {
            return true
        }
        return false
    }
    
    func perform(with invocation: Invocation, completionHandler: @escaping (Error?) -> Void) -> Void {
        let runtime = Runtime.shared
        
        if !runtime.isInitialized && !runtime.initialize() {
            completionHandler(error("Couldn't initialize type engine"))
            return
        }
        
        guard let json = NSPasteboard.general.string(forType: .string) else {
            completionHandler(error("Couldn't get JSON from clipboard"))
            return
        }
        
        if !isValidJson(json) {
            completionHandler(error("Clipboard does not contain valid JSON"))
            return
        }
        
        runtime.quicktype(json,
                          fail: { self.handleError(message: $0, invocation, completionHandler) },
                          success: { self.handleSuccess(lines: $0, invocation, completionHandler) })
    }
}
