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

class VirtualDisplayViewController: NSViewController {
}
struct VirtualDisplayView: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> NSViewController {
        return VirtualDisplayViewController()
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
    }
}
