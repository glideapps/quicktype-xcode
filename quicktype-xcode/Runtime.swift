import Foundation
import JavaScriptCore

class Runtime {
    public static let shared = Runtime()
    
    var context: JSContext!
    
    private init() {
    }
    
    var isInitialized: Bool {
        return nil != context
    }
    
    func initialize() -> Bool {
        guard let context = JSContext() else { return false }
        
        context.exceptionHandler = { context, exception in
            print("JS Error: \(exception?.description ?? "unknown error")")
        }
        
        context.evaluateScript("""
            var window = {};
            var setTimeout = function(f) { f(); };
            var clearTimeout = function() {};
            var console = {};
        """)
        
        let consoleLog: @convention(block) (Any) -> Void = { print($0) }
        context.objectForKeyedSubscript("console").setObject(consoleLog, forKeyedSubscript: "log" as NSString)
        
        guard let javascriptPath = Bundle.main.url(forResource: "quicktype", withExtension: "js") else { return false }
        guard let data = try? Data(contentsOf: javascriptPath) else { return false }
        guard let javascript = String(data: data, encoding: .utf8) else { return false }
        
        context.evaluateScript(javascript)
        
        self.context = context
        
        return true
    }
    
    private func resolve(resolve: @escaping ([String]) -> Void) {
        let resolveBlock: @convention(block) ([String]) -> Void = { resolve($0) }
        context.setObject(resolveBlock, forKeyedSubscript: "resolve" as NSString)
    }
    
    private func reject(reject: @escaping (String) -> Void) {
        let rejectBlock: @convention(block) (String) -> Void = { reject($0) }
        context.setObject(rejectBlock, forKeyedSubscript: "reject" as NSString)
    }
    
    func quicktype(_ json: String, justTypes: Bool, fail: @escaping (String) -> Void, success: @escaping ([String]) -> Void) {
        resolve { lines in success(lines) }
        reject { errorMessage in fail(errorMessage) }
        
        context.evaluateScript("""
            function swifttype(json) {
                window.quicktype.quicktype({
                  lang: "swift",
                  sources: [{
                    name: "TopLevel",
                    samples: [json]
                  }],
                  rendererOptions: {
                    "just-types": \(justTypes ? "true" : "false")
                  }
                }).then(function(result) {
                  resolve(result.lines);
                }).catch(function(e) {
                  reject(e.toString());
                });
            }
        """)
        
        let swifttype = context.objectForKeyedSubscript("swifttype")!
        swifttype.call(withArguments: [json])
    }
}
