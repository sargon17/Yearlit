import Foundation

struct HTTP {
    static func log(_ message: String) {
        #if DEBUG
            print("[HTTP] \(message)")
        #endif
    }
}
