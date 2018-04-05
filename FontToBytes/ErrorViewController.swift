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


/// The view controller for the error view.
///
class ErrorViewController: NSViewController {

    /// The title for the error message
    ///
    @IBOutlet weak var errorTitleField: NSTextField!
    
    /// The details for the error message
    ///
    @IBOutlet weak var errorDetailsField: NSTextField!
    
    /// The warn sign image view
    ///
    @IBOutlet weak var warnSignImageView: NSImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Set the image
        self.warnSignImageView.image = StyleKit.imageOfWarningSign
        
        // Get the error details.
        if let error = (self.representedObject as? ConverterError) {
            errorTitleField.stringValue = error.summary
            errorDetailsField.stringValue = error.details
        }
    }
}
