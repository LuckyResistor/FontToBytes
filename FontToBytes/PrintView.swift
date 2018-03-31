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
import Foundation


/// A view which is used to prepare the printed character map
///
class PrintView: NSView {

    
    private let characterMap: [UnicodeScalar: NSImage]
    
    private let rowCount: Int
    private let columnCount = 16
    
    private let boxSize = NSSize(width: 30.0, height: 60.0)
    private let marginSize = NSSize(width: 5.0, height: 5.0)

    private let pageSize: NSSize
    private let pageRect: NSRect
    
    init(characterMap: [UnicodeScalar: NSImage]) {
        self.characterMap = characterMap
        self.rowCount = characterMap.count / 16
        self.pageSize = NSSize(width: (boxSize.width*CGFloat(self.columnCount)) + 2.0*marginSize.width, height: (boxSize.height*CGFloat(self.rowCount)) + 2.0*marginSize.height)
        self.pageRect = NSRect(x: 0.0, y: 0.0, width: pageSize.width, height: pageSize.height)
        super.init(frame: pageRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        var cx = 0
        var cy = 0
        for character in characterMap.keys.sorted() {
            
            // draw the box
            let boxRect = NSRect(x: boxSize.width*CGFloat(cx) + marginSize.width,
                y: boxSize.height*CGFloat(rowCount-cy-1) + marginSize.height,
                width: boxSize.width, height: boxSize.height)
            let boxRectQuadHeight = boxRect.height/4.0
            let box = NSBezierPath(rect: boxRect)
            box.lineWidth = 1.0
            NSColor.black.setStroke()
            box.stroke()
            
            // draw the bitmap in the box
            let image = characterMap[character]!
            let imageRect = NSRect(x: boxRect.origin.x, y: boxRect.origin.y+2.0*boxRectQuadHeight, width: boxRect.size.width, height: 2.0*boxRectQuadHeight)
            image.draw(in: NSInsetRect(imageRect, 2.0, 2.0), from: NSZeroRect, operation: .copy, fraction: 1.0)
            
            // draw the hex number of the character
            let hexNumber = String(format: "0x%02x", arguments: [character.value])
            let hexRect = NSRect(x: boxRect.origin.x, y: boxRect.origin.y+boxRectQuadHeight, width: boxRect.size.width, height: boxRectQuadHeight)
            let textParagraph = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
            textParagraph.alignment = .center
            let textAttributes = [NSFontAttributeName: NSFont(name: "Helvetica Neue", size: 10.0)!, NSParagraphStyleAttributeName: textParagraph]
            hexNumber.draw(in: hexRect, withAttributes: textAttributes)
            
            // Draw the character if it is printable
            if character.isASCII {
                let printableCharacter = String(Character(character))
                let printableRect = NSRect(x: boxRect.origin.x, y: boxRect.origin.y, width: boxRect.size.width, height: boxRectQuadHeight)
                printableCharacter.draw(in: printableRect, withAttributes: textAttributes)
            }
            
            cx += 1
            
            if (cx >= columnCount) {
                cx = 0
                cy += 1
            }
        }
    }
    
    override func rectForPage(_ page: Int) -> NSRect {
        return pageRect
    }
    
}
