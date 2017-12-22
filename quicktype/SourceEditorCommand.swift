import Foundation
import XcodeKit

import AppKit

import JavaScriptCore

// browserify dist/index.js -s quicktype -o /Users/david/Developer/quicktype/quicktype.js
class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    func quicktype(_ json: String, success: @escaping ([String]) -> Void) {
        let jsUrl = Bundle.main.url(forResource: "quicktype", withExtension: "js")!
        let data = try! Data(contentsOf: jsUrl)
        let js = String(data: data, encoding: .utf8)!
        
        let context = JSContext()!
        context.exceptionHandler = { context, exception in
            print("JS Error: \(exception?.description ?? "unknown error")")
        }
        
        context.evaluateScript("""
            var window = {};
            var setTimeout = function(f) { f(); };
            var clearTimeout = function() {};
            var console = {};
        """)
        
        context.evaluateScript(js)
       
        let consoleLog: @convention(block) (Any) -> Void = { x in
            print(x)
        }
        context.objectForKeyedSubscript("console").setObject(consoleLog, forKeyedSubscript: "log" as NSString)
        
        let resolve: @convention(block) ([String]) -> Void = { lines in
            success(lines)
        }
        context.setObject(resolve, forKeyedSubscript: "resolve" as NSString)
        
        context.evaluateScript("""
            function swifttype(json) {
                window.quicktype.quicktype({
                  lang: "swift",
                  sources: [{
                    name: "TopLevel",
                    samples: [json]
                  }]
                }).then(function(result) {
                  resolve(result.lines);
                }).catch(function(e) {
                  resolve(["// " + e.toString()]);
                });
            }
        """)
        
        let swifttype = context.objectForKeyedSubscript("swifttype")!
        swifttype.call(withArguments: [json])
    }
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        let json = NSPasteboard.general.string(forType: .string)!
        quicktype(json) { lines in
            invocation.buffer.lines.addObjects(from: lines)
            completionHandler(nil)
        }
    }
}
