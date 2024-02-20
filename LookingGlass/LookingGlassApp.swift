//
//  LookingGlassApp.swift
//  LookingGlass
//
//  Created by d on 2024-02-04.
//

import SwiftUI

extension AppSettings: RawRepresentable {
    public init?(rawValue: String) {
        guard
            let data = rawValue.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(Self.self, from: data)
        else {
            return nil
        }
        self = decoded
    }
    
    public var rawValue: String {
        guard
            let data = try? JSONEncoder().encode([
                "automaticUnregisterDelayInSeconds": self.automaticUnregisterDelayInSeconds
            ]),
            let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return string
    }
}

@main
struct LookingGlassApp: App {
    @State var virtualDisplayRegistry = VirtualDisplayRegistry()

    @AppStorage("settings") var settings = AppSettings()
    
    @AppStorage("automaticUnregisterEnabled") var automaticUnregisterEnabled: Bool = true
    @AppStorage("automaticUnregisterDelayInSeconds") var automaticUnregisterDelayInSeconds: Double = 5 * 60
//    @State var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            DisplayConfigurationView(
                virtualDisplayRegistry: $virtualDisplayRegistry,
                automaticUnregisterEnabled: $automaticUnregisterEnabled,
                automaticUnregisterDelayInSeconds: $automaticUnregisterDelayInSeconds
            )
        }
        Settings {
            SettingsView(
                settings: $settings,
                automaticUnregisterEnabled: $automaticUnregisterEnabled,
                automaticUnregisterDelayInSeconds: $automaticUnregisterDelayInSeconds
            )
        }
    }
}
