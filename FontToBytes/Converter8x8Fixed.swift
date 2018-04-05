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


/// A simple converter which converts 8x8 pixel fonts
///
/// Starting from the top-left 8x8 block, it converts each block from
/// left to right, from top to down.
///
/// Each 8x8 block is converted into 8 bytes, where the left bit is the
/// highest bit.
///
/// Example:
/// ..XXXX.. -> 0x3c
/// .XX..XX. -> 0x66
/// .XX..XX. -> 0x66
/// ..XXXXX. -> 0x3e
/// .....XX. -> 0x06
/// .....XX. -> 0x06
/// .XX..XX. -> 0x66
/// ..XXXX.. -> 0x3c
/// ........ -> 0x00
///
/// This char will result in the byte sequence: 0x3c, 0x66, 0x66, ...
///
class Converter8x8Fixed: ModeConverter {

    /// The direction of the conversion
    ///
    enum Direction {
        case topDown ///< Each character from top to bottom.
        case leftRight ///< Each character from left to right.
    }
    
    /// The direction for the conversion
    ///
    fileprivate var direction: Direction
    
    
    /// Create a new fixed 8x8 converter
    ///
    init(direction: Direction) {
        self.direction = direction
    }
    
    
    fileprivate func checkImage(_ inputImage: InputImage) throws {
        guard inputImage.height >= 8 else {
            throw ConverterError(summary: "Image Too Small", details: "The height of the image has to be minimum 8 pixel.")
        }
        guard inputImage.width >= 8 else {
            throw ConverterError(summary: "Image Too Small", details: "The width of the image has to be minimum 8 pixel.")
        }
        guard (inputImage.height % 8) == 0 else {
            throw ConverterError(summary: "Odd Image Height", details: "The height of the image has to be a multiple of 8 pixel.")
        }
        guard (inputImage.width % 8) == 0 else {
            throw ConverterError(summary: "Odd Image Width", details: "The width of the image has to be a multiple of 8 pixel.")
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
        for y in 0..<(inputImage.height/8) {
            for x in 0..<(inputImage.width/8) {
                for row in 0...7 {
                    var byte: UInt8 = 0
                    for bit in 0...7 {
                        byte <<= 1
                        switch self.direction {
                        case .topDown:
                            if inputImage.isPixelSet(x: x*8+bit, y: y*8+row) {
                                byte |= 1
                            }
                        case .leftRight:
                            if inputImage.isPixelSet(x: x*8+row, y: y*8+bit) {
                                byte |= 1
                            }
                        }
                    }
                    byteWriter.writeByte(byte)
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
        for cy in 0..<(inputImage.height/8) {
            for cx in 0..<(inputImage.width/8) {
                let pixelSize = 64
                let characterImage = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 8*pixelSize, pixelsHigh: 8*pixelSize, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSColorSpaceName.calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)!
                let gc = NSGraphicsContext(bitmapImageRep: characterImage)!
                let context = gc.cgContext
                context.setFillColor(NSColor.white.cgColor)
                context.fill(NSRect(x: 0.0, y: 0.0, width: 8.0*CGFloat(pixelSize), height: 8.0*CGFloat(pixelSize)))
                context.setFillColor(NSColor.black.cgColor)
                for y in 0...7 {
                    for x in 0...7 {
                        if inputImage.isPixelSet(x: cx*8+x, y: cy*8+y) {
                            context.fill(NSRect(x: x*pixelSize, y: (7-y)*pixelSize, width: pixelSize, height: pixelSize))
                        }
                    }
                }
                let image = NSImage(size: NSSize(width: 8.0*CGFloat(pixelSize), height: 8.0*CGFloat(pixelSize)))
                image.addRepresentation(characterImage)
                result[UnicodeScalar(characterIndex+0x20)!] = image
                characterIndex += 1
            }
        }
        return result;
    }
}


