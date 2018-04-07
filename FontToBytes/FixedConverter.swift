//
// Lucky Resistor's Font to Byte
// ---------------------------------------------------------------------------
// (c)2015-2018 by Lucky Resistor.
// (c)2018 by Dominik Kapusta.
// See LICENSE for details.
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

/// A simple converter which converts fixed-width fonts.
///
/// Starting from the top-left 8x8 block, it converts each block from
/// left to right, from top to down.
///
/// For 'w' width and 'h' height, each w x h block is converted to the total
/// amount of h*(Int(w/8)+1) bytes, i.e. each row is represented by Int(w/8)+1 bytes,
/// so:
///
///   width | bytes
///  ---------------
///     5   |   1
///     7   |   1
///     8   |   1
///    12   |   2
///    16   |   2
///    19   |   3
///
/// The left bit is the highest bit, and the first byte in a row is a leftmost byte.
/// Unused trailing bits are zeroed.
/// Example:
/// 'A' (17 pixels wide)
/// ...######........ -> 0x1F, 0x80, 0x00
/// ...#######....... -> 0x1F, 0xC0, 0x00
/// .......###....... -> 0x01, 0xC0, 0x00
/// ......##.##...... -> 0x03, 0x60, 0x00
/// ......##.##...... -> 0x03, 0x60, 0x00
/// .....##...##..... -> 0x06, 0x30, 0x00
/// .....##...##..... -> 0x06, 0x30, 0x00
/// ....##....##..... -> 0x0C, 0x30, 0x00
/// ....#########.... -> 0x0F, 0xF8, 0x00
/// ...##########.... -> 0x1F, 0xF8, 0x00
/// ...##.......##... -> 0x18, 0x0C, 0x00
/// ..##........##... -> 0x30, 0x0C, 0x00
/// ######...#######. -> 0xFC, 0x7F, 0x00
/// ######...#######. -> 0xFC, 0x7F, 0x00
/// ................. -> 0x00, 0x00, 0x00
///
/// This char will result in the byte sequence: 0x1F, 0x80, 0x00, 0x1F, 0xC0, 0x00, ...
///
/// '9' (8 pixels wide)
/// ..XXXX.. -> 0x3C
/// .XX..XX. -> 0x66
/// .XX..XX. -> 0x66
/// ..XXXXX. -> 0x3E
/// .....XX. -> 0x06
/// .....XX. -> 0x06
/// .XX..XX. -> 0x66
/// ..XXXX.. -> 0x3C
/// ........ -> 0x00
///
/// This char will result in the byte sequence: 0x3c, 0x66, 0x66, ...
///
class FixedConverter: ModeConverter {

    /// The direction of the conversion
    ///
    enum Direction {
        case topDown ///< Each character from top to bottom.
        case leftRight ///< Each character from left to right.
    }
    
    /// The direction for the conversion
    ///
    let direction: Direction
    let height: Int
    let width: Int

    
    /// Create a new fixed 8x8 converter
    ///
    /// - parameters:
    ///   - height: Font height in pixels
    ///   - width: Font width in pixels
    ///   - direction: Direction of the conversion
    ///
    init(height: Int, width: Int, direction: Direction) {
        self.height = height
        self.width = width
        self.direction = direction
    }
    
    fileprivate func checkImage(_ inputImage: InputImage) throws {
        guard inputImage.height >= height else {
            throw ConverterError(summary: "Image Too Small", details: "The height of the image has to be minimum \(height) pixel.")
        }
        guard inputImage.width >= width else {
            throw ConverterError(summary: "Image Too Small", details: "The width of the image has to be minimum \(width) pixel.")
        }
        guard (inputImage.height % height) == 0 else {
            throw ConverterError(summary: "Odd Image Height", details: "The height of the image has to be a multiple of \(height) pixel.")
        }
        guard (inputImage.width % width) == 0 else {
            throw ConverterError(summary: "Odd Image Width", details: "The width of the image has to be a multiple of \(width) pixel.")
        }
        guard inputImage.width <= 2048 && inputImage.height <= 2048 else {
            throw ConverterError(summary: "Image Too Large", details: "The no image dimension must be greater than 2048.")
        }
    }
    
    func convertImage(_ inputImage: InputImage, byteWriter: ByteWriter) throws {
        try checkImage(inputImage);
        
        byteWriter.begin()
        byteWriter.beginArray("font")
        var characterCount = 0
        for y in 0..<(inputImage.height/height) {
            for x in 0..<(inputImage.width/width) {
                for row in 0..<height {
                    var remainingBits = width
                    
                    // for width > 8, each line will be represented by more than one byte;
                    // let's track bytes count per line here
                    var byteIndex = 0
                    
                    while remainingBits > 0 {
                        var byte: UInt8 = 0
                        let bitCount = min(remainingBits, 8)
                        for bit in 0..<bitCount {
                            byte <<= 1
                            switch self.direction {
                            case .topDown:
                                if inputImage.isPixelSet(x: x*width+bit+8*byteIndex, y: y*height+row) {
                                    byte |= 1
                                }
                            case .leftRight:
                                if inputImage.isPixelSet(x: x*height+row, y: y*width+bit+8*byteIndex) {
                                    byte |= 1
                                }
                            }
                            remainingBits -= 1
                        }
                        byteWriter.writeByte(byte)
                        byteIndex += 1
                    }
                }
                byteWriter.addComment(String(format: "Character 0x%02x (%d)", arguments: [characterCount, characterCount]))
                characterCount += 1
            }
        }
        byteWriter.endArray()
        byteWriter.end()
    }
    
    func createCharacterImages(_ inputImage: InputImage) throws -> [UnicodeScalar: NSImage] {
        try checkImage(inputImage);
        
        var result = [UnicodeScalar: NSImage]()
        var characterIndex = 0
        for cy in 0..<(inputImage.height/height) {
            for cx in 0..<(inputImage.width/width) {
                let pixelSize = 64
                let characterImage = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width*pixelSize, pixelsHigh: height*pixelSize, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSColorSpaceName.calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)!
                let gc = NSGraphicsContext(bitmapImageRep: characterImage)!
                let context = gc.cgContext
                context.setFillColor(NSColor.white.cgColor)
                context.fill(NSRect(x: 0.0, y: 0.0, width: CGFloat(width*pixelSize), height: CGFloat(height*pixelSize)))
                context.setFillColor(NSColor.black.cgColor)
                for y in 0..<height {
                    for x in 0..<width {
                        let shouldFill: Bool = {
                            switch self.direction {
                            case .topDown:
                                return inputImage.isPixelSet(x: cx*width+x, y: cy*height+y)
                            case .leftRight:
                                return inputImage.isPixelSet(x: cx*height+x, y: cy*width+y)
                            }
                        }()
                        if shouldFill {
                            context.fill(NSRect(x: x*pixelSize, y: (height-1-y)*pixelSize, width: pixelSize, height: pixelSize))
                        }
                    }
                }
                let image = NSImage(size: NSSize(width: CGFloat(width*pixelSize), height: CGFloat(height*pixelSize)))
                image.addRepresentation(characterImage)
                result[UnicodeScalar(characterIndex+0x20)!] = image
                characterIndex += 1
            }
        }
        return result
    }

}
