//
//  FixedConverter.swift
//  FontToBytes
//
//  Created by Dominik Kapusta on 03/04/2018.
//  Copyright © 2018 Lucky Resistor. All rights reserved.
//

import Cocoa

class FixedConverter: ModeConverter {

    /// The direction of the conversion
    ///
    enum Direction {
        case topDown ///< Each character from top to bottom.
        case leftRight ///< Each character from left to right.
    }
    
    /// The direction for the conversion
    ///
    fileprivate var direction: Direction
    fileprivate var height: Int
    fileprivate var width: Int

    
    /// Create a new fixed 8x8 converter
    ///
    init(height: Int, width: Int, direction: Direction) {
        self.height = height
        self.width = width
        self.direction = direction
    }
    
    private struct Const {
        static let height = 16
        static let width = 10
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
                        if inputImage.isPixelSet(x: cx*width+x, y: cy*height+y) {
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
