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


import Foundation


/// The bit order for the source generator
///
enum SourceGeneratorBitOrder {
    case Normal
    case Reverse
}


/// A protocol implemented by source generators
///
protocol SourceCodeGenerator: ByteWriter {
    
    /// Access the generated source code.
    ///
    var sourceCode: String { get }
    
    /// The generator requires a default constructor.
    ///
    init(bitOrder: SourceGeneratorBitOrder)
}


protocol SourceCodeGeneratorItem {
    
    /// The title of the item.
    ///
    var title: String { get }
    
    /// Create a new generator
    ///
    func createGenerator(bitOrder: SourceGeneratorBitOrder) -> SourceCodeGenerator
    
}


/// A item displayed in the user interface for each generator
///
class SourceCodeGeneratorItemImpl<GeneratorType: SourceCodeGenerator>: SourceCodeGeneratorItem {
    
    /// The title displayed for the item.
    ///
    let title: String
    
    /// Create a new source code generator item
    ///
    init(title: String) {
        self.title = title
    }
    
    /// Create a new source code generator from this item.
    ///
    func createGenerator(bitOrder: SourceGeneratorBitOrder) -> SourceCodeGenerator {
        return GeneratorType(bitOrder: bitOrder)
    }
    
}


/// A common implementation of a source generator
///
class CommonSourceGenerator: SourceCodeGenerator {
    
    /// The generated source code.
    ///
    var sourceCode: String = ""
    
    /// The used bit order.
    ///
    private let bitOrder: SourceGeneratorBitOrder
    
    /// Create a new generator instance.
    ///
    required init(bitOrder: SourceGeneratorBitOrder) {
        self.bitOrder = bitOrder
    }
    
    func begin() {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = .MediumStyle
        dateFormatter.dateStyle = .MediumStyle
        let dateTime = dateFormatter.stringFromDate(NSDate())
        sourceCode = "//\n// Font Data\n// Created: \(dateTime)\n//\n"
    }

    func beginArray(name: String) {
        sourceCode += "\n\nconst unsigned char \(name)[] = {\n\t"
    }
    
    final func writeByte(byte: UInt8) {
        if bitOrder == .Reverse {
            var reversedByte: UInt8 = 0
            for i: UInt8 in 0...7 {
                if (byte & (1<<i)) != 0 {
                    let setBit = (1<<(7-i))
                    reversedByte |= setBit
                }
            }
            writeFinalByte(reversedByte)
        } else {
            writeFinalByte(byte)
        }
    }
    
    func writeFinalByte(byte: UInt8) {
        sourceCode += String(format: "0x%02x,", byte)
    }
    
    func addComment(comment: String) {
        sourceCode += " // \(comment)\n\t"
    }
    
    func addLineBreak() {
        sourceCode += "\n\t"
    }
    
    func endArray() {
        sourceCode += "\n};\n"
    }
    
    func end() {
        sourceCode += "\n\n"
    }
    
}


/// A byte writer which generates suitable arrays for the Arduino platform.
///
class ArduinoSourceGenerator: CommonSourceGenerator {
    
    override func begin() {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = .MediumStyle
        dateFormatter.dateStyle = .MediumStyle
        let dateTime = dateFormatter.stringFromDate(NSDate())
        sourceCode = "//\n// Font Data\n// Created: \(dateTime)\n//\n\n#include <Arduino.h>\n"
    }
    
    override func beginArray(name: String) {
        sourceCode += "\n\nconst uint8_t \(name)[] PROGMEM = {\n\t"
    }
}


/// A byte writer which generates suitable arrays for generic C++ projects.
///
class CommonCppSourceGenerator: CommonSourceGenerator {
    
    // Just use the common implementation as it is.
    
}


