import SwiftUI
import Cocoa
import Foundation
import Quartz
import CoreGraphics
import CoreVideo
import IOSurface
import Metal
import MetalKit
import ScreenCaptureKit
import OSLog

import Foundation

class VirtualDisplayRegistry {
    var registry: [String: VirtualDisplayRegistration] = [:]
    func register(_ k: String, _ v: VirtualDisplayRegistration) {
        registry[k] = v
    }
    func unregister(_ k: String) {
        registry.removeValue(forKey: k)
    }
    func isRegistered(_ k: String) -> Bool {
        return registry[k] != nil
    }
    func find(_ k: String) -> VirtualDisplayRegistration? {
        registry[k]
    }
}

class VirtualDisplayRegistration {
    var window: NSWindow?
    // NSWindow.windowController is a weak ref
    var controller: NSWindowController?
    
    var display: CGVirtualDisplay?
    var stream: CGDisplayStream?
}

class VirtualDisplayManager {
    static let logger = Logger(subsystem: "VirtualDisplayManager", category: "")
    
    static func create(config: DisplayConfig) -> CGVirtualDisplay {
        let desc = CGVirtualDisplayDescriptor()
        desc.setDispatchQueue(DispatchQueue.main)
        desc.terminationHandler = { a, b in
            logger.info("VirtualDisplay terminated: \(String(describing: a)), \(String(describing: b))")
        }
        desc.name = config.name ?? ""
        desc.maxPixelsWide = config.maxWidthPixels
        desc.maxPixelsHigh = config.maxHeightPixels
        desc.sizeInMillimeters = CGSize(width: CGFloat(integerLiteral: Int(config.widthInMillimeters)), height: CGFloat(integerLiteral: Int(config.heightInMillimeters)))
        desc.productID = config.productId
        desc.vendorID = config.vendorId
        desc.serialNum = config.serialNumber

        let settings = CGVirtualDisplaySettings()
        settings.hiDPI = 2
        settings.modes = config.displayModes.map {
            CGVirtualDisplayMode(
                width: $0.widthPixels,
                height: $0.heightPixels,
                refreshRate: $0.refreshRateHz
            )
        }

        let display = CGVirtualDisplay(descriptor: desc)
        display.apply(settings)
        return display
    }
    
    static func stream(
        display: CGVirtualDisplay,
        frameDelaySeconds: Float32?,
        outputWidth: UInt32,
        outputHeight: UInt32,
        handler: @escaping (IOSurface) -> Void) -> CGDisplayStream?
    {
        var properties = [CFString: Any]()
        if let frameDelaySeconds = frameDelaySeconds {
            properties[CGDisplayStream.minimumFrameTime] = frameDelaySeconds
        }
        guard let stream = CGDisplayStream(
            dispatchQueueDisplay: display.displayID,
            outputWidth: Int(truncatingIfNeeded: outputWidth),
            outputHeight: Int(truncatingIfNeeded: outputHeight),
            pixelFormat: 1111970369, // BGRA
            properties: properties as CFDictionary,
            queue: .main,
            handler: { frameStatus, displayTime, frameSurface, updateRef in
                if let surface = frameSurface {
                    handler(surface)
                }
            }
        ) else { return nil }

        let error = stream.start()
        guard error == CGError.success else {
            logger.error("Error starting display stream: \(error.rawValue)")
            return nil
        }

        return stream
    }
    
    static func window() -> (NSWindow, NSWindowController) {
        let view = VirtualDisplayView()
        
        let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, .resizable, .titled]
        let window = NSWindow()
        window.styleMask = styleMask
        window.contentView = NSHostingView(rootView: view)
        
        let controller = NSWindowController(window: window)
        window.windowController = controller
        
        return (window: window, controller: controller)
    }
}
