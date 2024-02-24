import Foundation
import SwiftUI
import OSLog
import Combine

struct DisplayModeView: View {
    
    @Binding var displayModes: [DisplayMode]
    @Binding var mode: DisplayMode

    var body: some View {
        GroupBox {
            HStack(alignment: .top) {
                Grid(alignment: .leading) {
                    GridRow {
                        Text("Resolution")
                        HStack(spacing:0) {
                            TextField("", text: $mode.widthPixels.asString()).fixedSize().padding(0)
                            Text("x").padding(0)
                            TextField("", text: $mode.heightPixels.asString()).fixedSize().padding(0)
                            Text(" pixels")
                        }.gridColumnAlignment(.leading)
                    }
                    GridRow {
                        Text("Refresh rate")
                        HStack {
                            TextField("", text: $mode.refreshRateHz.asString()).fixedSize().padding(0)
                            Text(" hz")
                        }
                    }
                }
                Button {
                    if let index = displayModes.firstIndex(of: mode) {
                        displayModes.remove(at: index)
                    }
                    if displayModes.count == 0 {
                        displayModes.append(DisplayConfigurationView.defaultDisplayMode())
                    }
                } label: {
                    Image(systemName: "trash")
                }.buttonStyle(PlainButtonStyle())
                    .frame(alignment: .trailing)
            }
        }
    }
}

struct GlassConfigView: View {
    
    @Binding var glassConfigs: [GlassConfig]
    @Binding var glass: GlassConfig
    @Binding var virtualDisplayRegistry: VirtualDisplayRegistry
    @Binding var automaticUnregisterEnabled: Bool
    @Binding var automaticUnregisterDelayInSeconds: Double
    @Binding var automaticUnregisterTasks: [String: DispatchWorkItem]
    @State var isDeleteDialog: Bool = false

    func onRegisterToggle(_ glass: Binding<GlassConfig>) {
        if (~glass.registered) {
            guard (!virtualDisplayRegistry.isRegistered(~glass.id)) else { return }
            
            let display = VirtualDisplayManager.create(config: ~glass.displayConfig)
            glass.displayConfig.id.wrappedValue = display.displayID
            let registration = VirtualDisplayRegistration()
            registration.display = display
            virtualDisplayRegistry.register(~glass.id, registration)
            let workItem = DispatchWorkItem {
                GlassConfigView.cleanup(self, glass)
            }
            automaticUnregisterTasks[~glass.id] = workItem
            if (automaticUnregisterEnabled) {
                DispatchQueue.main.asyncAfter(deadline: .now() + automaticUnregisterDelayInSeconds, execute: workItem)
            }
        } else {
            GlassConfigView.cleanup(self, glass)
        }
    }

    func onActiveToggle(_ glass: Binding<GlassConfig>) {
        if (~glass.active) {
            guard let registration = virtualDisplayRegistry.find(~glass.id) else { return }
            guard registration.stream == nil else { return }
            guard nil != registration.display else { return }
            DisplayConfigurationView.logger.error("Active.true")
            
            weak var (window, controller) = VirtualDisplayManager.window()
            window?.title = glass.name.wrappedValue?.nonEmptyOrNil() ?? glass.displayConfig.name.wrappedValue?.nonEmptyOrNil() ?? String(~glass.displayConfig.id)
            window?.setContentSize(NSSize(width: Int(~glass.windowWidthPixels), height: Int(~glass.windowHeightPixels)))
            let stream = VirtualDisplayManager.stream(
                display: registration.display!,
                frameDelaySeconds: ~glass.renderDelaySeconds,
                outputWidth: ~glass.renderWidthPixels ?? ~glass.windowWidthPixels,
                outputHeight: ~glass.renderHeightPixels ?? ~glass.windowHeightPixels) { surface in
                    window?.contentView?.layer?.contents = surface
            }
            
            registration.window = window
            registration.controller = controller
            registration.stream = stream
            
            controller?.showWindow(window)
            window?.orderFrontRegardless()
        } else {
            guard let registration = virtualDisplayRegistry.find(~glass.id) else { return }
            DisplayConfigurationView.logger.error("Active.false")
            
            cleanupRegisteredStream(glassId: ~glass.id, registration: registration)
        }
    }

    func cleanupRegisteredDisplay(glassId: String, registration: VirtualDisplayRegistration) {
        if let error = registration.stream?.stop() {
            DisplayConfigurationView.logger.error("Error stopping display stream: \(error.rawValue)")
        }

        registration.display = nil
        virtualDisplayRegistry.unregister(glassId)
    }
    func cleanupRegisteredStream(glassId: String, registration: VirtualDisplayRegistration) {
        if let error = registration.stream?.stop() {
            DisplayConfigurationView.logger.error("Error stopping display stream: \(error.rawValue)")
        }

        registration.controller?.close()
        registration.window?.close()
        
        registration.window = nil
        registration.controller = nil
        registration.stream = nil
    }
    
    static func cleanup(_ view: GlassConfigView, _ glass: Binding<GlassConfig>) {
        guard let registration = view.virtualDisplayRegistry.find(~glass.id) else { return }
        view.cleanupRegisteredStream(glassId: ~glass.id, registration: registration)
        view.cleanupRegisteredDisplay(glassId: ~glass.id, registration: registration)

        view.automaticUnregisterTasks[~glass.id]?.cancel()
        view.automaticUnregisterTasks.removeValue(forKey: ~glass.id)

        glass.wrappedValue.registered = false
        glass.wrappedValue.active = false
    }

    var body: some View {
        if let index = glassConfigs.firstIndex{$0 == glass} {
            let groupDisplay: String = [
                glass.name,
                glass.displayConfig.name,
                glass.id.map{String($0)}.first
            ].flatMap { $0?.trimmingCharacters(in: .whitespaces) }.first ?? ""
            
            GroupBox("\(groupDisplay)") {
                HStack(alignment: .top) {
                    Toggle("Register", isOn: $glass.registered)
                        .toggleStyle(.switch)
                        .onChange(of: glass.registered) {
                            onRegisterToggle($glass)
                        }
                        .onAppear() {
                            if (glass.registered) {
                                onRegisterToggle($glass)

                                if (glass.active) {
                                    onActiveToggle($glass)
                                }
                            }
                        }
                    
                    Toggle("Active", isOn: $glass.active)
                        .toggleStyle(.switch)
                        .disabled(!(glass.registered))
                        .onChange(of: glass.active) {
                            onActiveToggle($glass)
                        }
                    Spacer()
                    Button {
                        isDeleteDialog = true
                    } label: {
                        Image(systemName: "trash")
                    }.buttonStyle(PlainButtonStyle())
                        .frame(alignment: .trailing)
                }
                VStack(alignment: .leading) {
                    Text("Config")
                    Grid(alignment: .trailing) {
//                        GridRow {
//                            Text("ID")
//                            TextField("", text: Binding.constant($glass.wrappedValue.id))
//                        }
                        GridRow {
                            Text("Name")
                            TextField(glass.displayConfig.name ?? "", text: $glassConfigs[index].name ?? "")
                        }
                        GridRow(alignment: .top) {
                            Text("Render size")
                            HStack(spacing:0) {
                                TextField(String(glass.windowWidthPixels),
                                          text: $glass.renderWidthPixels.asString(
                                            format: {$0.map{String($0)} ?? ""},
                                            parse: {UInt32($0)}
                                          ))
                                .fixedSize().padding(0)
                                Text("x").padding(0)
                                TextField(String(glass.windowHeightPixels),
                                          text: $glass.renderHeightPixels.asString(
                                            format: {$0.map{String($0)} ?? ""},
                                            parse: {UInt32($0)}
                                          ))
                                .fixedSize().padding(0)
                                Text(" pixels").padding(0)
                            }.gridColumnAlignment(.leading)
                        }
                        GridRow(alignment: .top) {
                            Text("Render delay")
                            HStack(spacing:0) {
                                TextField("", text: $glass.renderDelaySeconds.asString())
                                    .fixedSize().padding(0)
                                
                                Text(" seconds")
                            }
                        }
                        GridRow(alignment: .top) {
                            Text("Window size")
                            HStack(spacing:0) {
                                TextField("", text: $glass.windowWidthPixels.asString()).fixedSize().padding(0)
                                Text("x").padding(0)
                                TextField("", text: $glass.windowHeightPixels.asString()).fixedSize().padding(0)
                                Text(" pixels")
                            }.gridColumnAlignment(.leading)
                        }
                    }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                }
                VStack(alignment: .leading) {
                    Text("Display")
                    Grid(alignment: .trailing) {
//                        GridRow {
//                            Text("ID")
//                            TextField("", text: Binding.constant(String(glass.displayConfig.id)))
//                        }
                        GridRow {
                            Text("Name")
                            TextField("", text: $glass.displayConfig.name ?? "")
                        }
                        GridRow {
                            Text("Product Id")
                            TextField("", text: $glass.displayConfig.productId.asString())
                        }
                        GridRow {
                            Text("Vendor Id")
                            TextField("", text: $glass.displayConfig.vendorId.asString())
                        }
                        GridRow {
                            Text("Serial Number")
                            TextField("", text: $glass.displayConfig.serialNumber.asString())
                        }
                        GridRow(alignment: .top) {
                            Text("Max resolution")
                            HStack(spacing:0) {
                                TextField("", text: $glass.displayConfig.maxWidthPixels.asString()).fixedSize().padding(0)
                                Text("x").padding(0)
                                TextField("", text: $glass.displayConfig.maxHeightPixels.asString()).fixedSize().padding(0)
                                Text(" pixels")
                            }.gridColumnAlignment(.leading)
                        }
                        GridRow(alignment: .top) {
                            Text("Phsyical size")
                            HStack(spacing:0) {
                                TextField("", text: $glass.displayConfig.widthInMillimeters.asString()).fixedSize().padding(0)
                                Text("x").padding(0)
                                TextField("", text: $glass.displayConfig.heightInMillimeters.asString()).fixedSize().padding(0)
                                Text(" millimeters")
                            }.gridColumnAlignment(.leading)
                        }
                        GridRow(alignment: .top) {
                            Text("Modes")
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    ForEach($glass.displayConfig.displayModes.indices, id: \.self) { index in
                                        DisplayModeView(
                                            displayModes: $glass.displayConfig.displayModes,
                                            mode: $glass.displayConfig.displayModes[index]
                                        )
                                    }
                                }
                                Spacer()
                                Button {
                                    let new = DisplayConfigurationView.defaultDisplayMode()
                                    glass.displayConfig.displayModes.append(new)
                                } label: {
                                    Image(systemName: "plus.app")
                                }.buttonStyle(PlainButtonStyle())
                                    .padding(0)
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                }
            }.padding(5)
                .confirmationDialog(
                    "Are you sure you want to delete?",
                    isPresented: $isDeleteDialog
                ) {
                    Button {
                        if let index = glassConfigs.firstIndex(of: glass) {
                            GlassConfigView.cleanup(self, $glass)
                            glassConfigs.remove(at: index)
                        }
                        if glassConfigs.count == 0 {
                            glassConfigs.append(
                                DisplayConfigurationView.defaultGlassConfig().copy {
                                    $0.displayConfig = DisplayConfigurationView.defaultDisplayConfig().copy {
                                        $0.name = "New Display"
                                    }
                                }
                            )
                        }
                    } label: {
                        Text("Delete")
                    }
                    Button("Cancel", role: .cancel) {
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: virtualDisplayRegistry.find(glass.id)?.window)) { notif in
                    glass.active = false
                    if let registration = virtualDisplayRegistry.find(glass.id) {
                        cleanupRegisteredStream(glassId: glass.id, registration: registration)
                    }
                }
        }
    }
}
