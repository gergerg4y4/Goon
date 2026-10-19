import Foundation
import UIKit
import Darwin
import MachO
import Security

struct TestResult: Codable, Identifiable {
    var id = UUID()
    let section: String
    let name: String
    let status: String
    let detail: String
    let timestamp: Date
}

struct TestReport: Codable {
    let generatedAt: Date
    let appVersion: String
    let results: [TestResult]
}

enum LabTests {
    static let sections = ["Device", "Sandbox", "Entitlements", "Memory", "Runtime"]
    static func result(_ section: String, _ name: String, _ status: String, _ detail: String) -> TestResult {
        TestResult(section: section, name: name, status: status, detail: detail, timestamp: Date())
    }
    static func sysctlString(_ key: String) -> String {
        var size: size_t = 0
        guard sysctlbyname(key, nil, &size, nil, 0) == 0, size > 0 else { return "Unavailable" }
        var data = [CChar](repeating: 0, count: size)
        guard sysctlbyname(key, &data, &size, nil, 0) == 0 else { return "Unavailable" }
        return data.withUnsafeBufferPointer { ptr in
            guard let base = ptr.baseAddress else { return "Unavailable" }
            return String(cString: base)
        }
    }
    static func run(_ section: String) -> [TestResult] {
        switch section {
        case "Device": return device()
        case "Sandbox": return sandbox()
        case "Entitlements": return entitlements()
        case "Memory": return memory()
        case "Runtime": return runtime()
        default: return []
        }
    }
    static func device() -> [TestResult] {
        let d = UIDevice.current
        return [
            result("Device", "iOS version", "INFO", "\(d.systemName) \(d.systemVersion)"),
            result("Device", "Hardware identifier", "INFO", sysctlString("hw.machine")),
            result("Device", "Kernel release", "INFO", sysctlString("kern.osrelease")),
            result("Device", "Kernel version", "INFO", sysctlString("kern.version")),
            result("Device", "OS build", "INFO", sysctlString("kern.osversion")),
            result("Device", "CPU architecture", "INFO", "arm64 (iOS device target)")
        ]
    }
    static func sandbox() -> [TestResult] {
        var results: [TestResult] = []
        let fm = FileManager.default
        let base = fm.temporaryDirectory.appendingPathComponent("lab-\(UUID().uuidString)")
        do {
            try Data("JailbreakLab test".utf8).write(to: base)
            let data = try Data(contentsOf: base)
            try fm.removeItem(at: base)
            results.append(result("Sandbox", "App temporary storage", data == Data("JailbreakLab test".utf8) ? "PASS" : "FAIL", "Created, read and removed a temporary file"))
        } catch { results.append(result("Sandbox", "App temporary storage", "FAIL", error.localizedDescription)) }
        let outside = "/private/var/mobile/Library/Preferences"
        let accessible = fm.isReadableFile(atPath: outside)
        results.append(result("Sandbox", "Other app/system directory", "INFO", "Readable according to FileManager: \(accessible). This is not a sandbox escape test."))
        if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            results.append(result("Sandbox", "Documents directory", "INFO", docs.path))
        }
        return results
    }
    static func entitlements() -> [TestResult] {
        var results: [TestResult] = []
        guard let task = SecTaskCreateFromSelf(nil) else {
            return [result("Entitlements", "Own task entitlements", "INFO", "SecTask unavailable")]
        }
        let keys = ["application-identifier", "get-task-allow", "com.apple.developer.team-identifier", "com.apple.security.application-groups", "com.apple.developer.associated-domains"]
        for key in keys {
            let value = SecTaskCopyValueForEntitlement(task, key as CFString, nil)
            let detail = value.map { String(describing: $0) } ?? "Not present or not readable"
            results.append(result("Entitlements", key, "INFO", detail))
        }
        return results
    }
    static func memory() -> [TestResult] {
        let page = Int(getpagesize())
        let flags = MAP_PRIVATE | MAP_ANON
        let ptr = mmap(nil, page, PROT_READ | PROT_WRITE, flags, -1, 0)
        guard ptr != MAP_FAILED, let p = ptr else {
            return [result("Memory", "Anonymous memory allocation", "FAIL", "mmap failed, errno \(errno)")]
        }
        defer { munmap(p, page) }
        p.storeBytes(of: UInt8(0x5A), as: UInt8.self)
        let readBack = p.load(as: UInt8.self)
        let protectResult = mprotect(p, page, PROT_READ)
        return [
            result("Memory", "RW page allocation", readBack == 0x5A ? "PASS" : "FAIL", "Allocated \(page) bytes and verified read/write"),
            result("Memory", "RW to R transition", protectResult == 0 ? "PASS" : "FAIL", protectResult == 0 ? "mprotect allowed read-only protection" : "mprotect failed, errno \(errno)"),
            result("Memory", "Executable memory", "INFO", "Not attempted. This app does not bypass code signing or test executable mappings.")
        ]
    }
    static func runtime() -> [TestResult] {
        let executable = Bundle.main.executablePath ?? "Unavailable"
        let bundle = Bundle.main.bundleIdentifier ?? "Unavailable"
        let debug = isDebuggerAttached()
        return [
            result("Runtime", "Process ID", "INFO", String(getpid())),
            result("Runtime", "User / group ID", "INFO", "uid=\(getuid()), gid=\(getgid())"),
            result("Runtime", "Executable path", "INFO", executable),
            result("Runtime", "Bundle identifier", "INFO", bundle),
            result("Runtime", "Debugger attached", "INFO", debug ? "Yes" : "No")
        ]
    }
    static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        let rc = name.withUnsafeMutableBufferPointer { ptr in
            sysctl(ptr.baseAddress, u_int(ptr.count), &info, &size, nil, 0)
        }
        return rc == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
    }
}
