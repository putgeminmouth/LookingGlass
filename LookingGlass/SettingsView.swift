import Foundation
import SwiftUI
import OSLog

struct GeneralSettingsView: View {
    @Binding var settings: AppSettings
    @Binding var automaticUnregisterEnabled: Bool
    @Binding var automaticUnregisterDelayInSeconds: Double

    var body: some View {
        GroupBox("Safety") {
            VStack(alignment: .leading) {
                HStack {
                    Toggle("Unregister virtual screens after a set amount of time.", isOn: $automaticUnregisterEnabled)
                    TextField("", value: $automaticUnregisterDelayInSeconds, format: .number)
                        .fixedSize()
                        .disabled(!automaticUnregisterEnabled)
                    Text("seconds")
                }
//                .fixedSize(horizontal: true, vertical: true)
//                Text("OK")
            }
//            .frame(maxWidth: 300)
        }
        .onAppear() {
        }
    }
}

struct SettingsView: View {
    static let logger = Logger(subsystem: "SettingsView", category: "")
    @Binding var settings: AppSettings
    @Binding var automaticUnregisterEnabled: Bool
    @Binding var automaticUnregisterDelayInSeconds: Double
    var body: some View {
        TabView {
            GeneralSettingsView(
                settings: $settings,
                automaticUnregisterEnabled: $automaticUnregisterEnabled,
                automaticUnregisterDelayInSeconds: $automaticUnregisterDelayInSeconds
            )
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
    }
}

