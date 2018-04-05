//
// Lucky Resistor's Font to Byte
// ---------------------------------------------------------------------------
// (c)2015 by Lucky Resistor. See LICENSE for details.
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


/// A converter for a given mode.
///
protocol ModeConverter {
    
    /// Converts the input into a byte array.
    ///
    /// - parameters:
    ///   - inputImage: The input image to convert.
    ///   - byteWriter: The interface to output the converted bytes.
    /// - throws: Throws an error on any problem while conversion or with the input image.
    ///
    func convertImage(_ inputImage: InputImage, byteWriter: ByteWriter) throws -> Void
    
    /// Create a character map from the input image.
    ///
    /// - parameter inputImage: The input image to use for the character images.
    /// - returns: A map with all characters to create a chart.
    ///
    func createCharacterImages(_ inputImage: InputImage) throws -> [UnicodeScalar: NSImage]
}

