//
// Lucky Resistor's Font to Byte
// ---------------------------------------------------------------------------
// (c)2015-2018 by Lucky Resistor. See LICENSE for details.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//


import Cocoa


/// A protocol which wraps the input image for the converter
///
protocol InputImage {
    
    /// The width of the image in pixels.
    ///
    var width: Int { get }
    
    /// The height of the image in pixels.
    ///
    var height: Int { get }
    
    /// Check if a given pixel is set in the image.
    ///
    func isPixelSet(x: Int, y: Int) -> Bool
    
}


/// A input image which is based on a NSImage.
///
class InputImageFromNSImage: InputImage {

    /// The internal image representation.
    ///
    fileprivate var bitmapImage: NSBitmapImageRep? = nil;

    /// Create a new instance from the given image.
    ///
    /// - Parameter image: The image to use.
    ///
    init(image: NSImage) throws {
        if image.tiffRepresentation == nil {
            throw ConverterError(summary: "The current image can not be converted into the required format.",
                details: "Please use a RGB or RGBA image in PNG format for the best results.")
        }
        bitmapImage = NSBitmapImageRep(data: image.tiffRepresentation!)!;
    }

    // Implement the protocol
    
    var width: Int {
        get {
            return bitmapImage!.pixelsWide
        }
    }
    
    var height: Int {
        get {
            return bitmapImage!.pixelsHigh
        }
    }
    
    func isPixelSet(x: Int, y: Int) -> Bool {
        if x < 0 || x > self.width || y < 0 || y > self.height {
            return false
        }
        if let color = bitmapImage!.colorAt(x: x, y: y) {
            if color.alphaComponent < 1.0 {
                return false
            }
            if color.redComponent > 0.2 || color.blueComponent > 0.2 || color.greenComponent > 0.2 {
                return false
            } else {
                return true
            }
        } else {
            return false
        }
    }
}



