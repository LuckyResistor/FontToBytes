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


/// The view for the welcome screen where the user can drop PNG files.
/// This view also displays the progress indicator until the result is ready.
///
class WelcomeView: NSView {

    /// A closure which is called if a URL is dropped on the welcome screen.
    ///
    var onURLDropped: ((_ url: URL)->())? = nil
    
    /// The main layer of this view
    ///
    fileprivate var mainLayer = CALayer()
    
    /// The displayed drop border.
    ///
    fileprivate var borderLayer = CAShapeLayer()
    
    /// The text inside of the drop border.
    ///
    fileprivate var textLayer = CATextLayer()
    
    
    /// The background color in normal state.
    ///
    fileprivate let backgroundColorNormal = StyleKit.lRWhite
    
    /// The foreground color in normal state.
    ///
    fileprivate let foregroundColorNormal = StyleKit.lRGray1
    
    /// The background color in drag state.
    ///
    fileprivate let backgroundColorDrag = StyleKit.lRBlue
    
    /// The foreground color in drag state.
    ///
    fileprivate let foregroundColorDrag = StyleKit.lRWhite
    
    
    /// If a file was successfully dropped.
    ///
    fileprivate var successFullDrop: Bool = false

    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initializeLayers()
        registerForDraggedTypes([.fileURL])
    }

    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeLayers()
        registerForDraggedTypes([.fileURL])
    }
    
    
    /// Initialize all layers
    ///
    func initializeLayers() {
        // setup the main layer
        self.layer = mainLayer
        self.wantsLayer = true
        mainLayer.layoutManager = CAConstraintLayoutManager()
        mainLayer.backgroundColor = backgroundColorNormal.cgColor
        
        // Setup the border
        mainLayer.addSublayer(borderLayer)
        borderLayer.addConstraint(CAConstraint(attribute: .midX, relativeTo: "superlayer", attribute: .midX))
        borderLayer.addConstraint(CAConstraint(attribute: .midY, relativeTo: "superlayer", attribute: .midY))
        borderLayer.frame = CGRect(x: 0.0, y: 0.0, width: 380.0, height: 280.0)
        let borderRadius: CGFloat = 40.0
        let borderLineWidth: CGFloat = 20.0
        let innerRect = borderLayer.bounds.insetBy(dx: borderLineWidth+2.0, dy: borderLineWidth+2.0)
        let path = NSBezierPath(roundedRect: innerRect, xRadius: borderRadius, yRadius: borderRadius)
        borderLayer.path = path.CGPath
        borderLayer.fillColor = nil
        borderLayer.lineWidth = 10.0
        borderLayer.lineDashPhase = 20.0
        borderLayer.lineDashPattern = [20.0, 10.0]
        borderLayer.strokeColor = foregroundColorNormal.cgColor
        borderLayer.actions = ["position": NSNull(), "bounds": NSNull()]
        
        // Setup the text
        mainLayer.addSublayer(textLayer)
        textLayer.addConstraint(CAConstraint(attribute: .midX, relativeTo: "superlayer", attribute: .midX))
        textLayer.addConstraint(CAConstraint(attribute: .midY, relativeTo: "superlayer", attribute: .midY))
        textLayer.string = NSLocalizedString("Drop your\nPNG file here!", comment: "Message to drop PNG files.")
        textLayer.alignmentMode = kCAAlignmentCenter
        textLayer.actions = ["position": NSNull(), "bounds": NSNull()]
        textLayer.font = NSFont.boldSystemFont(ofSize: 50.0)
        textLayer.foregroundColor = foregroundColorNormal.cgColor
    }
    
    
    /// Switch the colors to visualize the two drop states.
    ///
    func setDropState(_ cursorInside: Bool) {
        let newForegroundColor: NSColor
        let newBackgroundColor: NSColor
        if cursorInside {
            newForegroundColor = foregroundColorDrag
            newBackgroundColor = backgroundColorDrag
        } else {
            newForegroundColor = foregroundColorNormal
            newBackgroundColor = backgroundColorNormal
        }
        borderLayer.strokeColor = newForegroundColor.cgColor
        textLayer.foregroundColor = newForegroundColor.cgColor
        mainLayer.backgroundColor = newBackgroundColor.cgColor
    }
    
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteBoard = sender.draggingPasteboard()
        if let types = pasteBoard.types {
            if (types.contains(.fileURL)) {
                let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true,
                                                                     .urlReadingContentsConformToTypes: ["public.png"]]
                let classes: [AnyClass] = [NSURL.self]
                if let fileURLs = pasteBoard.readObjects(forClasses: classes, options: options) {
                    if fileURLs.count == 1 {
                        setDropState(true)
                        return .copy
                    }
                }
            }
        }
        return NSDragOperation()
    }
    
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        if !successFullDrop {
            setDropState(false)
        }
    }
    
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteBoard = sender.draggingPasteboard()
        if let types = pasteBoard.types {
            if (types.contains(.fileURL)) {
                let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true,
                                                                     .urlReadingContentsConformToTypes: ["public.png"]]
                let classes: [AnyClass] = [NSURL.self]
                let fileURLs = pasteBoard.readObjects(forClasses: classes, options: options)
                self.onURLDropped!(fileURLs![0] as! URL)
                self.successFullDrop = true
                goIntoDroppedState()
            }
        }
        return true
    }
    
    
    func goIntoDroppedState() {
        // background for progress indicator
        self.mainLayer.backgroundColor = StyleKit.lRWhite.cgColor
        self.borderLayer.isHidden = true
        self.textLayer.isHidden = true
    }

    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        if !successFullDrop {
            setDropState(false)
        }
    }
}
