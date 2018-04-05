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


class WelcomeViewController: NSViewController {

    /// The closure which is called if an URL is dropped onto the welcome screen
    ///
    var onURLDropped: ((_ url: URL)->())? = nil
    
    /// The progress indicator.
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    
    /// Go into dropped state
    ///
    func goIntoDroppedState() {
        let welcomeView = self.view as! WelcomeView
        welcomeView.goIntoDroppedState()
        self.progressIndicator.startAnimation(self)
    }
    
    
    /// Initialize the view after load
    ///
    override func viewDidLoad() {
        super.viewDidLoad()
        let welcomeView = self.view as! WelcomeView
        welcomeView.onURLDropped = {(url: URL) in
            self.progressIndicator.startAnimation(self)
            self.onURLDropped!(url)
        }
    }
    
}
