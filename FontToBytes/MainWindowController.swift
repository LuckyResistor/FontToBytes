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


/// The window controller for the main window
///
class MainWindowController: NSWindowController {

    /// Initialize the window.
    ///
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Set the required visual style.
        self.window!.titleVisibility = NSWindow.TitleVisibility.hidden;
        self.window!.titlebarAppearsTransparent = true;
        self.window!.isMovableByWindowBackground = true;
        
        // Register the controller in the app delegate
        let appDelegate = NSApp.delegate as! AppDelegate
        appDelegate.mainWindowController = self
    }

    /// Redirect to the website for help.
    ///
    @IBAction func showHelp(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "http://luckyresistor.me")!)
    }
}
