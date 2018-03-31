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
let UD_InvertBitsChecked = "invertBitsChecked"
let UD_ReverseBitsChecked = "reverseBitsChecked"


/// The view controller for the main window
///
class MainViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    
    /// All visible mode items.
    fileprivate var modeItems = [
        ModeItem(title: "8×8 Fixed Top-Down", converter: Converter8x8Fixed(direction: .topDown)),
        ModeItem(title: "8×8 Fixed Left-Right", converter: Converter8x8Fixed(direction: .leftRight))
    ]
    
    fileprivate var sourceCodeGenerators: [SourceCodeGeneratorItem] = [
        SourceCodeGeneratorItemImpl<ArduinoSourceGenerator>(title: "Arduino Format"),
        SourceCodeGeneratorItemImpl<CommonCppSourceGenerator>(title: "C++ Common Format")
    ]
    
    /// The mode section.
    fileprivate let modeSectionItem = ModeItem(title: "MODES")
    
    /// The navigation outline view on the left side.
    @IBOutlet weak var navigation: NSOutlineView!
    
    /// The main view.
    @IBOutlet weak var mainView: NSView!
    
    /// Invert bits checkbox
    @IBOutlet weak var invertBitsCheckbox: NSButton!
    
    /// Reverse bits checkbox
    @IBOutlet weak var reverseBitsCheckbox: NSButton!
    
    /// The selection for the output format.
    @IBOutlet weak var outputFormatSelection: NSPopUpButton!
    
    /// The currently displayed view controller in the main view
    var mainViewController: NSViewController? = nil
    
    /// The currently displayed view
    enum DisplayedView {
        case welcome
        case error
        case result
    }
    
    /// The currently displayed view
    var displayedView = DisplayedView.welcome
    
    /// The current code which is displayed
    var code = ""
    
    /// The least used input image for a later print operation
    var inputImage: InputImage? = nil
    
    
    /// Initialize the view after load.
    ///
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // expand all items.
        navigation.expandItem(nil, expandChildren: true)

        // The user defaults
        let ud = UserDefaults.standard
        
        // Select the item
        let selectedModeIndex = ud.integer(forKey: UD_SelectedModeIndex)
        DispatchQueue.main.async {
            self.navigation.selectRowIndexes(IndexSet(integer: selectedModeIndex+1), byExtendingSelection: false)
        }

        // Check the invert bits checkbox.
        let invertBitsChecked = ud.bool(forKey: UD_InvertBitsChecked)
        self.invertBitsCheckbox.state = (invertBitsChecked ? .on : .off)
        
        // Check the flip bits checkbox.
        let reverseBitsChecked = ud.bool(forKey: UD_ReverseBitsChecked)
        self.reverseBitsCheckbox.state = (reverseBitsChecked ? .on : .off)
        
        // Prepare the popup button with the outputs
        self.outputFormatSelection.removeAllItems()
        for item in sourceCodeGenerators {
            self.outputFormatSelection.addItem(withTitle: item.title)
        }
        let selectedOutputIndex = ud.integer(forKey: UD_SelectedOutputIndex)
        self.outputFormatSelection.selectItem(at: selectedOutputIndex)
        
        // Show the welcome view
        displayWelcomeView()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        // Store the user defaults
        let ud = UserDefaults.standard
        ud.set(self.navigation.selectedRow-1, forKey: UD_SelectedModeIndex)
        ud.set(self.invertBitsCheckbox.state == .on, forKey: UD_InvertBitsChecked)
        ud.set(self.reverseBitsCheckbox.state == .off, forKey: UD_ReverseBitsChecked)
        ud.set(self.outputFormatSelection.indexOfSelectedItem, forKey: UD_SelectedOutputIndex)
    }
    
    /// Go back to the welcome view
    ///
    @IBAction func goBack(_ sender: Any) {
        DispatchQueue.main.async(execute: {
            self.displayWelcomeView()
        })
    }

    /// Save the current result into a file.
    ///
    @IBAction func saveDocumentAs(_ sender: Any) {
        guard displayedView == .result else {
            return
        }
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["cpp", "h", "c", "txt"]
        savePanel.beginSheetModal(for: NSApp.mainWindow!, completionHandler: {(result: NSApplication.ModalResponse) in
            if result == .OK {
                do {
                    try self.code.write(to: savePanel.url!, atomically: true, encoding: String.Encoding.utf8)
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: {
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
    @IBAction func openDocument(_ sender: Any) {
        guard displayedView == .welcome else {
            return
        }
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["png"]
        openPanel.beginSheetModal(for: NSApp.mainWindow!, completionHandler: {(result: NSApplication.ModalResponse) in
            if result == .OK {
                let welcomeViewController = self.mainViewController as! WelcomeViewController
                welcomeViewController.goIntoDroppedState()
                self.convertImage(openPanel.urls[0])
            }
        })
    }
    
    
    /// Enable all valid menu items.
    ///
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(MainViewController.saveDocumentAs(_:)) {
            return displayedView == .result
        } else if menuItem.action == #selector(MainViewController.openDocument(_:)) {
            return displayedView == .welcome
        } else if menuItem.action == #selector(MainViewController.printDocument(_:)) {
            return displayedView == .result
        } else {
            return true
        }
    }
    

    /// Displays the welcome view
    ///
    func displayWelcomeView() {
        let newController = storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "welcomeView")) as! WelcomeViewController
        newController.representedObject = self
        newController.onURLDropped = {(url: URL) in
            self.convertImage(url)
        }
        displayViewInMain(newController)
        displayedView = .welcome
    }
    
    
    /// Displays the result view
    ///
    func displayResultView(_ result: String) {
        let newController = storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "resultView")) as! NSViewController
        newController.representedObject = result
        displayViewInMain(newController)
        displayedView = .result
    }
    
    
    /// Displays the error view
    ///
    func displayErrorView(_ error: ConverterError) {
        let newController = storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "errorView")) as! NSViewController
        newController.representedObject = error
        displayViewInMain(newController)
        displayedView = .error
    }
    
    
    /// Displays a new view using a given view controller.
    ///
    func displayViewInMain(_ newController: NSViewController) {
        if mainViewController != nil {
            for view in mainView.subviews {
                view.removeFromSuperviewWithoutNeedingDisplay();
            }
        }
        let newView = newController.view;
        newView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(newView)
        mainView.addConstraint(NSLayoutConstraint(item: newView, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: mainView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 0.0));
        mainView.addConstraint(NSLayoutConstraint(item: newView, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: mainView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: 0.0));
        mainView.addConstraint(NSLayoutConstraint(item: newView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: mainView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0.0));
        mainView.addConstraint(NSLayoutConstraint(item: newView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: mainView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0.0));
        self.mainViewController = newController
    }
    
    
    /// Convert the given image into code
    ///
    func convertImage(_ url: URL) {
        // Run this things in another thread.
        let selectedOutputIndex = outputFormatSelection.indexOfSelectedItem
        let shouldInvertBits = invertBitsCheckbox.state == .on
        let shouldReverseBits = reverseBitsCheckbox.state == .on
        let selectedModeItem = navigation.item(atRow: navigation.selectedRow) as? ModeItem

        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: {
            
            // Try to open the file as NSImage.
            if let image = NSImage(contentsOf: url) {
                do {
                    // Get the image object for the converter.
                    let inputImage = try InputImageFromNSImage(image: image)
                    // Store a copy for later print of a character map
                    self.inputImage = inputImage
                    // Get the byte writer for the output.
                    let sourceCodeGeneratorItem = self.sourceCodeGenerators[selectedOutputIndex]
                    let sourceCodeOptions = SourceCodeOptions(
                        inversion: shouldInvertBits ? .invert : .none,
                        bitOrder: shouldReverseBits ? .reverse : .normal)
                    let sourceCodeGenerator = sourceCodeGeneratorItem.createGenerator(sourceCodeOptions)
                    
                    // Get the selected mode item.
                    if let modeItem = selectedModeItem {
                        // Start the selected converter
                        let converter = modeItem.converter!
                        try converter.convertImage(inputImage, byteWriter: sourceCodeGenerator)
                        // Get the produced code and display it in the result view
                        let sourceCode = sourceCodeGenerator.sourceCode
                        self.code = sourceCode
                        DispatchQueue.main.async(execute: {
                            self.displayResultView(sourceCode)
                        })
                    } else {
                        DispatchQueue.main.async(execute: {
                            let error = ConverterError(summary: "No Mode Selected",
                                details: "There is no mode selected. Select your desired mode in the navigation at the left side in this window.")
                            self.displayErrorView(error)
                        })
                    }
                } catch let error as ConverterError {
                    DispatchQueue.main.async(execute: {
                        self.displayErrorView(error)
                    })
                } catch {
                    DispatchQueue.main.async(execute: {
                        let error = ConverterError(summary: "Unknown Error",
                            details: "There was a unknown problem. Try again and if the problem persists contact the author of the software.")
                        self.displayErrorView(error)
                    })
                }
            } else {
                DispatchQueue.main.async(execute: {
                    let error = ConverterError(summary: "Problem Loading the Image File",
                        details: "There was a problem while loading the image file. Check if the file is a valid PNG file in RGB or RGBA format.")
                    self.displayErrorView(error)
                })
            }
        })
    }

    
    /// Create a character map to print or as PDF
    ///
    @IBAction func printDocument(_ sender: Any) {
        guard let modeItem = self.navigation.item(atRow: self.navigation.selectedRow) as? ModeItem else {
            return
        }
        // Run this things in another thread.
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: {
            do {
                // Start the selected converter
                let converter = modeItem.converter!
                let characterMap = try converter.createCharacterImages(self.inputImage!)
                // Start the print from the main queue
                DispatchQueue.main.async(execute: {
                    let printView = PrintView(characterMap: characterMap)
                    let printOperation = NSPrintOperation(view: printView)
                    printOperation.run()
                })
            } catch {
                // ignore any problems.
            }
        })
    }
    

    // Implement NSOutlineViewDataSource and NSOutlineViewDelegate
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return 1
        } else {
            return modeItems.count
        }
    }

    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if item is ModeItem {
            let modeItem = item as! ModeItem
            return modeItem.isSection
        } else {
            return false
        }
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return modeSectionItem
        } else {
            if let modeItem = item as? ModeItem, modeItem === self.modeSectionItem {
                return modeItems[index]
            }
            return ModeItem(title: "Unknown")
        }
    }
    

    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return false
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let modeItem = item as? ModeItem else {
            return false
        }
        return !modeItem.isSection
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let modeItem = item as? ModeItem else {
            return nil
        }
        
        if modeItem.isSection {
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as! NSTableCellView
            view.textField?.stringValue = modeItem.title
            return view
        } else {
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as! NSTableCellView
            view.textField?.stringValue = modeItem.title
            return view
        }
    }
    

}

