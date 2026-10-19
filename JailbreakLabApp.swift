import SwiftUI

@main
struct JailbreakLabApp: App {
    @StateObject private var store = LabStore()
    var body: some Scene {
        WindowGroup { LabView().environmentObject(store) }
    }
}
