
import Foundation
import AppKit

import XcodeKit

import AppCenterAnalytics

typealias Invocation = XCSourceEditorCommandInvocation

// Commands correspond to definitions in Info.plist
enum Command: String {
    case pasteJSONAsCode = "PasteJSONAsCode"
    case pasteJSONAsObjCHeader = "PasteJSONAsObjCHeader"
    case pasteJSONAsObjCImplementation = "PasteJSONAsObjCImplementation"
}

// "io.quicktype.quicktype-xcode.X" -> Command(rawValue: "X")
func command(identifier: String) -> Command? {
    guard let component = identifier.split(separator: ".").last else {
        return nil
    }
    return Command(rawValue: String(component))
}

let commandOptions: [Language: [String: Any]] = [
    .objc: [
        // Objective-C is not ideal yet, so extra comments are useful
        "extra-comments": true
    ],
    .objcHeader: ["features": "interface"],
    .swift: ["initializers": true]
]

class PasteJSONCommand: NSObject, XCSourceEditorCommand {
    func error(_ message: String, details: String = "No details") -> NSError {
        return NSError(domain: "quicktype", code: 1, userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString(message, comment: ""),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString(details, comment: "")
            ])
    }
    
    func getFirstSelection(_ buffer: XCSourceTextBuffer) -> XCSourceTextRange? {
        for range in buffer.selections {
            guard let range = range as? XCSourceTextRange else {
                continue
            }
            return range
        }
        return nil
    }
    
    func isBlank(_ line: String) -> Bool {
        return line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func isComment(_ line: String) -> Bool {
        return line.starts(with: "//")
    }
    
    func isImport(_ line: String) -> Bool {
        // TODO we should split this functionality by current source language
        return ["import ", "#include ", "#import "].firstIndex { line.starts(with: $0) } != nil
    }
    
    func trimStart(_ lines: [String]) -> [String] {
        // Remove leading imports, comments, whitespace from start and end
        return Array(lines.drop(while: { line in
            return isComment(line) || isBlank(line) || isImport(line)
        }))
    }
    
    func trimEnd(_ lines: [String]) -> [String] {
        return Array(lines
            .reversed()
            .drop { isBlank($0) || isComment($0) }
            .reversed()
        )
    }
    
    func insertingAfterCode(_ buffer: XCSourceTextBuffer, _ selection: XCSourceTextRange) -> Bool {
        for i in 0..<selection.start.line {
            let line = buffer.lines[i] as! String
            if isBlank(line) || isComment(line) {
                continue
            }
            return true
        }
        return false
    }
    
    func inferTopLevelNameFromBuffer(_ buffer: XCSourceTextBuffer) -> String {
        // By default, new Objective-C files start like this:
        
        //
        //  QTFileName.h
        
        // So we simply look at the second line of the buffer to attempt to
        // guess the filename, so we can provide a better class prefix and top-level name
        
        let lines = buffer.lines as! [String]
        let selection = getFirstSelection(buffer) ?? XCSourceTextRange()
        if lines.count > 1 {
            let line = lines[1] as String
            if let _ = line.range(of: "//  (.+).(\\w+)", options: .regularExpression, range: nil, locale: nil) {
                let topLevel = String(line.dropFirst(4).prefix { $0 != "." })
                
                // There must be no other occurrences outside of the selection
                var matches = 0
                for (index, element) in lines.enumerated() {
                    if isImport(element) { continue }
                    
                    let outsideSelection = index < selection.start.line || index > selection.end.line
                    if outsideSelection && element.range(of: topLevel) != nil {
                        matches += 1
                    }
                }
                if matches == 1 {
                    return topLevel
                }
            }
        }
        return "TopLevel"
    }
    
    func classPrefixFromClass(_ name: String) -> String? {
        func isUppercase(_ c: Character) -> Bool {
            for scalar in c.unicodeScalars {
                if !CharacterSet.uppercaseLetters.contains(scalar) {
                    return false
                }
            }
            return true
        }
        let prefix = name.prefix { isUppercase($0) }.dropLast()
        return prefix.isEmpty ? nil : String(prefix)
    }
    
    func handleSuccess(lines: [String], _ invocation: Invocation, _ completionHandler: @escaping (Error?) -> Void) {
        let buffer = invocation.buffer
        let selection = getFirstSelection(invocation.buffer) ?? XCSourceTextRange()
        
        // If we're pasting in the middle of anything, we omit imports
        let cleanLines = insertingAfterCode(buffer, selection)
         ? trimEnd(trimStart(lines))
         : trimEnd(lines)
        
        let selectionEmpty =
            selection.start.line == selection.end.line &&
                selection.start.column == selection.end.column
        
        if !selectionEmpty {
            let selectedIndices = selection.end.line == buffer.lines.count
                ? selection.start.line...(selection.end.line - 1)
                : selection.start.line...selection.end.line
            
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
        
        let displayMessage = message.contains("cannot parse input")
            ? "Clipboard does not contain valid JSON"
            : "quicktype encountered an internal error"
        
        completionHandler(error(displayMessage, details: message))
    }
    
    func getTarget(_ command: Command, _ invocation: Invocation) -> (language: Language, options: [String: Any])? {
        switch command {
        case .pasteJSONAsObjCHeader:
            return (.objc, ["features": "interface"])
        case .pasteJSONAsObjCImplementation:
            return (.objc, ["features": "implementation"])
        default:
            if let language = languageFor(contentUTI: invocation.buffer.contentUTI as CFString) {
                return(language, commandOptions[language] ?? [:])
            }
        }
        return nil
    }
    
    func perform(with invocation: Invocation, completionHandler: @escaping (Error?) -> Void) -> Void {
        guard let command = command(identifier: invocation.commandIdentifier) else {
            completionHandler(error("Unrecognized command"))
            return
        }
        
        guard let (language, options) = getTarget(command, invocation) else {
            completionHandler(error("Cannot generate code for \(invocation.buffer.contentUTI)"))
            return
        }
        
        Analytics.trackEvent("perform", withProperties: [
            "command": invocation.commandIdentifier,
            "language": language.rawValue
        ])
        
        let runtime = Runtime.shared
        
        if !runtime.isInitialized && !runtime.initialize() {
            completionHandler(error("Couldn't initialize type engine"))
            return
        }
        
        guard let json = NSPasteboard.general.string(forType: .string) else {
            completionHandler(error("Couldn't get JSON from clipboard"))
            return
        }
        
        var finalOptions = options
        let topLevel = inferTopLevelNameFromBuffer(invocation.buffer)
        // For Objective-C, we try to infer the class prefix
        if language == .objc {
            if let classPrefix = classPrefixFromClass(topLevel) {
                finalOptions = options.merging(["class-prefix": classPrefix], uniquingKeysWith: { $1 })
            }
        }
        
        runtime.quicktype(json,
                          topLevel: topLevel,
                          language: language,
                          options: finalOptions,
                          fail: { self.handleError(message: $0, invocation, completionHandler) },
                          success: { self.handleSuccess(lines: $0, invocation, completionHandler) })
    }
}
