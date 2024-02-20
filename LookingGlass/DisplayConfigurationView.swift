import Foundation
import SwiftUI
import OSLog

extension [GlassConfig]: RawRepresentable {
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
            let data = try? JSONEncoder().encode(self),
            let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return string
    }
}

struct DisplayConfigurationView: View {
    static let logger = Logger(subsystem: "DisplayConfigurationView", category: "")
    
    static func defaultGlassConfig() -> GlassConfig {
        return GlassConfig(
            id: UUID().uuidString,
            name: "",
            displayConfig: defaultDisplayConfig(),
            registered: false,
            active: false,
            renderWidthPixels: nil,
            renderHeightPixels: nil,
            renderDelaySeconds: 0,
            windowWidthPixels: 800,
            windowHeightPixels: 450
        )
    }
    static func defaultDisplayMode() -> DisplayMode {
        return DisplayMode(
            widthPixels: 1920,
            heightPixels: 1024,
            refreshRateHz: 60
        )
    }
    static func defaultDisplayConfig() -> DisplayConfig {
        return DisplayConfig(
            id: UInt32(_truncatingBits: UInt(abs(UUID().hashValue))),
            name: "",
            productId: UInt32(truncatingIfNeeded: UUID().hashValue),
            vendorId: UInt32(truncatingIfNeeded: UUID().hashValue),
            serialNumber: UInt32(truncatingIfNeeded: UUID().hashValue),
            widthInMillimeters: 1800,
            heightInMillimeters: 1012,
            maxWidthPixels: 1920,
            maxHeightPixels: 1080,
            displayModes: [defaultDisplayMode()]
        )
    }
    
    func synchronizeOnScreenParameterChange() {
        DisplayConfigurationView.logger.debug("Synchronizing screens")
        // update existing
//        glassConfigs.indices.forEach { index in
//            let screenOpt = NSScreen.screens.first{ $0.displayId! == glassConfigs[index].displayConfig.id }
//            DisplayConfigurationView.logger.debug("Synchronizing screen gId=\(glassConfigs[index].id), gName=\(glassConfigs[index].name ?? ""), g.dName=\(glassConfigs[index].displayConfig.name ?? ""), sName=\(screenOpt?.localizedName ?? "")")
//            
//            if let screen = screenOpt {
//                glassConfigs[index].displayConfig.name = screen.localizedName
//            } else {
//                
//            }
//        }
        
        // add new
//        NSScreen.screens.forEach { screen in
//            guard (glassConfigs.first{ $0.displayConfig.id == screen.displayId } == nil) else { return }
//            guard let displayId = screen.displayId else { return }
//            DisplayConfigurationView.logger.debug("New screen sId=\(String(screen.displayId ?? 0)), sName=\(screen.localizedName ?? "")")
//
//            guard let displayConfig = describe(displayID: displayId) else { return }
//
//            let glassConfig = GlassConfig(
//                id: UUID().uuidString,
//                name: "",
//                displayConfig: displayConfig,
//                registered: false,
//                active: false,
//                windowWidthPixels: 640,
//                windowHeightPixels: 380
//            )
            
//            glassConfigs.append(glassConfig)
//        }
    }


    @Binding var virtualDisplayRegistry: VirtualDisplayRegistry
    @AppStorage("glassConfigs") var glassConfigs: [GlassConfig] = [
        defaultGlassConfig().copy {
            $0.displayConfig = defaultDisplayConfig().copy {
                $0.name = "New Display"
            }
        },
    ]
    @State var selection: GlassConfig?
    @Binding var automaticUnregisterEnabled: Bool
    @Binding var automaticUnregisterDelayInSeconds: Double

    @State var automaticUnregisterTasks: [String: DispatchWorkItem] = [String: DispatchWorkItem]()
    
    
    var body: some View {
        VStack {
            ScrollView  {
                VStack {
                    ForEach(glassConfigs.indices, id: \.self) { index in
                        GlassConfigView(
                            glassConfigs: $glassConfigs,
                            glass: $glassConfigs[index],
                            virtualDisplayRegistry: $virtualDisplayRegistry,
                            automaticUnregisterEnabled: $automaticUnregisterEnabled,
                            automaticUnregisterDelayInSeconds: $automaticUnregisterDelayInSeconds,
                            automaticUnregisterTasks: $automaticUnregisterTasks
                        )
                    }
                }
            }
            HStack {
                Spacer()
                Button {
                    let new = DisplayConfigurationView.defaultGlassConfig().copy {
                        $0.displayConfig = DisplayConfigurationView.defaultDisplayConfig().copy {
                            $0.name = "New Display"
                        }
                    }
                    glassConfigs.append(new)
                } label: {
                    Image(systemName: "plus")
                }.buttonStyle(PlainButtonStyle())
                    .frame(alignment: .trailing)
            }
            .padding(10)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification), perform: { _ in
            synchronizeOnScreenParameterChange()
        })
        .onAppear() {
            synchronizeOnScreenParameterChange()
        }
    }
}

