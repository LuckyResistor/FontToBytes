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


class ResultViewController: NSViewController {

    
    /// The text view
    ///
    @IBOutlet var textView: NSTextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Copy the formatted text into the text view.
        let code = self.representedObject as! String
        var font = NSFont(name: "Menlo", size: 12.0)
        if font == nil {
            font = NSFont.systemFont(ofSize: 12.0)
        }
        let attributes: [String: Any] = [NSFontAttributeName: font!]
        let text = NSMutableAttributedString(string: code, attributes: attributes)
        textView.textContainerInset = NSSize(width: 32.0, height: 32.0)
        textView.textStorage!.setAttributedString(text)
    }
    
    
    @IBAction func copyToPasteboard(_ sender: Any) {
        textView.selectAll(self)
        textView.copy(self)
    }
}
