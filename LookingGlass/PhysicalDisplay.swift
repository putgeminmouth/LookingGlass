import Foundation
import CoreGraphics
import IOKit
import IOKit.graphics

func describe(displayID: CGDirectDisplayID) -> DisplayConfig? {
    let productID = CGDisplayModelNumber(displayID)
    let vendorID = CGDisplayVendorNumber(displayID)
    let serialNumber = CGDisplaySerialNumber(displayID)
    let sizeInMillimeters = CGDisplayScreenSize(displayID)
    let pixelsWide = CGDisplayPixelsWide(displayID)
    let pixelsHigh = CGDisplayPixelsHigh(displayID)
    
    let screen = NSScreen.screens.first { $0.displayId == displayID }
    
    return DisplayConfig(
        id: displayID,
        name: screen?.localizedName,
        productId: productID,
        vendorId: vendorID,
        serialNumber: serialNumber,
        widthInMillimeters: UInt32(sizeInMillimeters.width),
        heightInMillimeters: UInt32(sizeInMillimeters.height),
        maxWidthPixels: UInt32(pixelsWide),
        maxHeightPixels: UInt32(pixelsHigh),
        displayModes: []
    )
}
