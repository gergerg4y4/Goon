import SwiftUI

@MainActor
final class LabStore: ObservableObject {
    @Published var results: [TestResult] = []
    @Published var running = false
    func run(_ section: String? = nil) {
        guard !running else { return }
        running = true
        if let section = section {
            results.removeAll { $0.section == section }
            results.append(contentsOf: LabTests.run(section))
        } else {
            results = LabTests.sections.flatMap { LabTests.run($0) }
        }
        running = false
    }
    var json: String {
        let report = TestReport(generatedAt: Date(), appVersion: "1.0", results: results)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return (try? encoder.encode(report)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }
    func exportURL() -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("JailbreakLab-results.json")
        do { try Data(json.utf8).write(to: url, options: .atomic); return url }
        catch { return nil }
    }
}

struct LabView: View {
    @EnvironmentObject var store: LabStore
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Device diagnostics for your own iPhone. Results do not imply jailbreak access.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button("Run All Tests") { store.run() }.font(.headline)
                        .disabled(store.running)
                }
                Section("Test sections") {
                    ForEach(LabTests.sections, id: \.self) { section in
                        NavigationLink {
                            SectionView(section: section)
                        } label: {
                            HStack {
                                Image(systemName: symbol(section)).frame(width: 30)
                                Text(section)
                                Spacer()
                                Text("\(store.results.filter { $0.section == section }.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Results") {
                    NavigationLink("View all results (\(store.results.count))") { ResultsView() }
                    if !store.results.isEmpty, let url = store.exportURL() {
                        ShareLink(item: url) { Label("Export JSON report", systemImage: "square.and.arrow.up") }
                    }
                }
            }
            .navigationTitle("JailbreakLab")
        }
    }
    func symbol(_ s: String) -> String {
        switch s {
        case "Device": return "iphone"
        case "Sandbox": return "folder.badge.gearshape"
        case "Entitlements": return "checkmark.shield"
        case "Memory": return "memorychip"
        default: return "terminal"
        }
    }
}

struct SectionView: View {
    @EnvironmentObject var store: LabStore
    let section: String
    var body: some View {
        List {
            Button("Run \(section) Tests") { store.run(section) }
            ForEach(store.results.filter { $0.section == section }) { r in ResultRow(result: r) }
        }.navigationTitle(section)
    }
}

struct ResultsView: View {
    @EnvironmentObject var store: LabStore
    var body: some View {
        List {
            ForEach(LabTests.sections, id: \.self) { section in
                Section(section) {
                    ForEach(store.results.filter { $0.section == section }) { r in ResultRow(result: r) }
                }
            }
            if !store.results.isEmpty, let url = store.exportURL() {
                ShareLink(item: url) { Label("Share JSON", systemImage: "square.and.arrow.up") }
            }
        }.navigationTitle("Test Results")
    }
}

struct ResultRow: View {
    let result: TestResult
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(result.name).font(.headline)
                Spacer()
                Text(result.status).font(.caption.bold())
                    .foregroundStyle(result.status == "PASS" ? .green : result.status == "FAIL" ? .red : .secondary)
            }
            Text(result.detail).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
        }.padding(.vertical, 3)
    }
}
