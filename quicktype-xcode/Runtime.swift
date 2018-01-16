import Foundation
import JavaScriptCore

enum Language: String {
    case swift, java, cpp, objc
}

fileprivate let languageUTIs: [CFString: Language] = [
    kUTTypeSwiftSource: .swift,
    kUTTypeObjectiveCSource: .objc,
    kUTTypeCHeader: .objc,
    kUTTypeJavaSource: .java,
    kUTTypeCPlusPlusSource: .cpp,
    kUTTypeObjectiveCPlusPlusSource: .objc,
    "com.apple.dt.playground" as CFString: .swift
]

func languageFor(contentUTI: CFString) -> Language? {
    for (uti, language) in languageUTIs {
        if UTTypeConformsTo(contentUTI as CFString, uti) {
            return language
        }
    }
    return nil
}

class Runtime {
    public static let shared = Runtime()
    
    var context: JSContext!
    
    let preface = [
        "Generated with quicktype",
        "For more options, try https://app.quicktype.io"
    ]
    
    private init() {
    }
    
    var isInitialized: Bool {
        return nil != context
    }
    
    var _quicktypeJavaScript: String?
    var quicktypeJavaScript: String? {
        if nil == _quicktypeJavaScript {
            guard let javascriptPath = Bundle.main.url(forResource: "quicktype", withExtension: "js") else { return nil }
            guard let data = try? Data(contentsOf: javascriptPath) else { return nil }
            _quicktypeJavaScript = String(data: data, encoding: .utf8)
        }
        
        return _quicktypeJavaScript
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
        
        guard let javascript = quicktypeJavaScript else { return false }
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
    
    func quicktype(_ json: String, language: Language, justTypes: Bool, fail: @escaping (String) -> Void, success: @escaping ([String]) -> Void) {
        resolve { lines in success(lines) }
        reject { errorMessage in fail(errorMessage) }
        
        let comments = preface.map { "\"\($0)\"" }.joined(separator: ",")
        
        context.evaluateScript("""
            function swifttype(json) {
                window.quicktype.quicktype({
                  lang: "\(language.rawValue)",
                  sources: [{
                    name: "TopLevel",
                    samples: [json]
                  }],
                  leadingComments: [\(comments)],
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
