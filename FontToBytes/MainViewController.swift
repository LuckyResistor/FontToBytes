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


let UD_SelectedModeIndex = "selectedModeIndex"
let UD_SelectedOutputIndex = "selectedOutputIndex"
let UD_ReverseBitsChecked = "reverseBitsChecked"


/// The view controller for the main window
///
class MainViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    
    /// All visible mode items.
    private var modeItems = [
        ModeItem(title: "8×8 Fixed Top-Down", converter: Converter8x8Fixed(direction: .TopDown)),
        ModeItem(title: "8×8 Fixed Left-Right", converter: Converter8x8Fixed(direction: .LeftRight))
    ]
    
    private var sourceCodeGenerators: [SourceCodeGeneratorItem] = [
        SourceCodeGeneratorItemImpl<ArduinoSourceGenerator>(title: "Arduino Format"),
        SourceCodeGeneratorItemImpl<CommonCppSourceGenerator>(title: "C++ Common Format")
    ]
    
    /// The mode section.
    private let modeSectionItem = ModeItem(title: "MODES")
    
    /// The navigation outline view on the left side.
    @IBOutlet weak var navigation: NSOutlineView!
    
    /// The main view.
    @IBOutlet weak var mainView: NSView!
    
    /// Check reverse bits checkbox
    @IBOutlet weak var reverseBitsCheckbox: NSButton!
    
    /// The selection for the output format.
    @IBOutlet weak var outputFormatSelection: NSPopUpButton!
    
    /// The currently displayed view controller in the main view
    var mainViewController: NSViewController? = nil
    
    /// The currently displayed view
    enum DisplayedView {
        case Welcome
        case Error
        case Result
    }
    
    /// The currently displayed view
    var displayedView = DisplayedView.Welcome
    
    /// The current code which is displayed
    var code = ""
    
    
    /// Initialize the view after load.
    ///
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // expand all items.
        navigation.expandItem(nil, expandChildren: true)

        // The user defaults
        let ud = NSUserDefaults.standardUserDefaults()
        
        // Select the item
        let selectedModeIndex = ud.integerForKey(UD_SelectedModeIndex)
        dispatch_async(dispatch_get_main_queue()) {
            self.navigation.selectRowIndexes(NSIndexSet(index: selectedModeIndex+1), byExtendingSelection: false)
        }

        // Check the flip bits checkbox.
        let bitFlipChecked = ud.boolForKey(UD_ReverseBitsChecked)
        self.reverseBitsCheckbox.state = (bitFlipChecked ? NSOnState : NSOffState)
        
        // Prepare the popup button with the outputs
        self.outputFormatSelection.removeAllItems()
        for item in sourceCodeGenerators {
            self.outputFormatSelection.addItemWithTitle(item.title)
        }
        let selectedOutputIndex = ud.integerForKey(UD_SelectedOutputIndex)
        self.outputFormatSelection.selectItemAtIndex(selectedOutputIndex)
        
        // Show the welcome view
        displayWelcomeView()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        // Store the user defaults
        let ud = NSUserDefaults.standardUserDefaults()
        ud.setInteger(self.navigation.selectedRow-1, forKey: UD_SelectedModeIndex)
        ud.setBool(self.reverseBitsCheckbox.state == NSOnState, forKey: UD_ReverseBitsChecked)
        ud.setInteger(self.outputFormatSelection.indexOfSelectedItem, forKey: UD_SelectedOutputIndex)
    }
    
    /// Go back to the welcome view
    ///
    @IBAction func goBack(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(), {
            self.displayWelcomeView()
        })
    }

    /// Save the current result into a file.
    ///
    @IBAction func saveDocumentAs(sender: AnyObject) {
        guard displayedView == .Result else {
            return
        }
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["cpp", "h", "c", "txt"]
        savePanel.beginSheetModalForWindow(NSApp.mainWindow!, completionHandler: {(result: Int) in
            if result == NSFileHandlingPanelOKButton {
                do {
                    try self.code.writeToURL(savePanel.URL!, atomically: true, encoding: NSUTF8StringEncoding)
                } catch let error as NSError {
                    dispatch_async(dispatch_get_main_queue(), {
                        NSApp.mainWindow!.presentError(error)
                    })
                } catch {
                    print("Unknown error.")
                }
            }
        })
    }
   
    
    /// Open a document.
    ///
    @IBAction func openDocument(sender: AnyObject) {
        guard displayedView == .Welcome else {
            return
        }
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["png"]
        openPanel.beginSheetModalForWindow(NSApp.mainWindow!, completionHandler: {(result: Int) in
            if result == NSFileHandlingPanelOKButton {
                let welcomeViewController = self.mainViewController as! WelcomeViewController
                welcomeViewController.goIntoDroppedState()
                self.convertImage(openPanel.URLs[0])
            }
        })
    }
    
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        if menuItem.action == Selector("saveDocumentAs:") {
            return displayedView == .Result
        } else if menuItem.action == Selector("openDocument:") {
            return displayedView == .Welcome
        } else {
            return true
        }
    }
    
    /// Displays the welcome view
    ///
    func displayWelcomeView() {
        let newController = storyboard!.instantiateControllerWithIdentifier("welcomeView") as! WelcomeViewController
        newController.representedObject = self
        newController.onURLDropped = {(url: NSURL) in
            self.convertImage(url)
        }
        displayViewInMain(newController)
        displayedView = .Welcome
    }
    
    
    /// Displays the result view
    ///
    func displayResultView(result: String) {
        let newController = storyboard!.instantiateControllerWithIdentifier("resultView") as! NSViewController
        newController.representedObject = result
        displayViewInMain(newController)
        displayedView = .Result
    }
    
    
    /// Displays the error view
    ///
    func displayErrorView(error: ConverterError) {
        let newController = storyboard!.instantiateControllerWithIdentifier("errorView") as! NSViewController
        newController.representedObject = error
        displayViewInMain(newController)
        displayedView = .Error
    }
    
    
    /// Displays a new view using a given view controller.
    ///
    func displayViewInMain(newController: NSViewController) {
        if mainViewController != nil {
            for view in mainView.subviews {
                view.removeFromSuperviewWithoutNeedingDisplay();
            }
        }
        let newView = newController.view;
        newView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(newView)
        mainView.addConstraint(NSLayoutConstraint(item: newView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0.0));
        mainView.addConstraint(NSLayoutConstraint(item: newView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 0.0));
        mainView.addConstraint(NSLayoutConstraint(item: newView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0.0));
        mainView.addConstraint(NSLayoutConstraint(item: newView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0.0));
        self.mainViewController = newController
    }
    
    
    /// Convert the given image into code
    ///
    func convertImage(url: NSURL) {
        // Run this things in another thread.
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), {
            
            // Try to open the file as NSImage.
            if let image = NSImage(contentsOfURL: url) {
                do {
                    // Get the image object for the converter.
                    let inputImage = try InputImageFromNSImage(image: image)
                    // Get the byte writer for the output.
                    let selectedOutputIndex = self.outputFormatSelection.indexOfSelectedItem
                    let sourceCodeGeneratorItem = self.sourceCodeGenerators[selectedOutputIndex]
                    let sourceCodeGenerator = sourceCodeGeneratorItem.createGenerator(
                        self.reverseBitsCheckbox.state == NSOnState ? .Reverse : .Normal)
                    // Get the selected mode item.
                    if let modeItem = self.navigation.itemAtRow(self.navigation.selectedRow) as? ModeItem {
                        // Start the selected converter
                        let converter = modeItem.converter!
                        try converter.convertImage(inputImage, byteWriter: sourceCodeGenerator)
                        // Get the produced code and display it in the result view
                        let sourceCode = sourceCodeGenerator.sourceCode
                        self.code = sourceCode
                        dispatch_async(dispatch_get_main_queue(), {
                            self.displayResultView(sourceCode)
                        })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), {
                            let error = ConverterError(summary: "No Mode Selected",
                                details: "There is no mode selected. Select your desired mode in the navigation at the left side in this window.")
                            self.displayErrorView(error)
                        })
                    }
                } catch let error as ConverterError {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.displayErrorView(error)
                    })
                } catch {
                    dispatch_async(dispatch_get_main_queue(), {
                        let error = ConverterError(summary: "Unknown Error",
                            details: "There was a unknown problem. Try again and if the problem persists contact the author of the software.")
                        self.displayErrorView(error)
                    })
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    let error = ConverterError(summary: "Problem Loading the Image File",
                        details: "There was a problem while loading the image file. Check if the file is a valid PNG file in RGB or RGBA format.")
                    self.displayErrorView(error)
                })
            }
        })
    }


    // Implement NSOutlineViewDataSource and NSOutlineViewDelegate
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil {
            return 1
        } else {
            return modeItems.count
        }
    }

    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        if item is ModeItem {
            let modeItem = item as! ModeItem
            return modeItem.isSection
        } else {
            return false
        }
    }
    
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            return modeSectionItem
        } else {
            if item === self.modeSectionItem {
                return modeItems[index]
            }
            return ModeItem(title: "Unknown")
        }
    }
    

    func outlineView(outlineView: NSOutlineView, shouldShowOutlineCellForItem item: AnyObject) -> Bool {
        return false
    }
    
    
    func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        guard let modeItem = item as? ModeItem else {
            return false
        }
        return !modeItem.isSection
    }
    
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        guard let modeItem = item as? ModeItem else {
            return nil
        }
        
        if modeItem.isSection {
            let view = outlineView.makeViewWithIdentifier("HeaderCell", owner: self) as! NSTableCellView
            view.textField?.stringValue = modeItem.title
            return view
        } else {
            let view = outlineView.makeViewWithIdentifier("DataCell", owner: self) as! NSTableCellView
            view.textField?.stringValue = modeItem.title
            return view
        }
    }
    

}

