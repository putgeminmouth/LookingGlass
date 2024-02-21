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
    @State var aboutBoxWindowController: NSWindowController?

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
        .commands {
            CommandGroup(replacing: CommandGroupPlacement .appInfo) {
                Button("About LookingGlass") {
                    if aboutBoxWindowController == nil {
                        let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable,/* .resizable,*/ .titled]
                        let window = NSWindow()
                        window.styleMask = styleMask
                        window.title = "About: LookingGlass"
                        window.contentView = NSHostingView(rootView: AboutView())
                        aboutBoxWindowController = NSWindowController(window: window)
                    }

                    aboutBoxWindowController?.showWindow(aboutBoxWindowController?.window)
                    aboutBoxWindowController?.window?.orderFrontRegardless()
                    aboutBoxWindowController?.window?.center()
                }
            }
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .help) {
                Button("Help") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/putgeminmouth/LookingGlass")!)
                }
            }
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
