//
//  ConfirmPathsView.swift
//  OtrWineManager
//
//  Created by Matteo Ceruti on 31.10.25.
//

import Cocoa

class ConfirmPathsView: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

  
    @IBOutlet var okButton: NSButtonCell!
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var label: NSTextField!
    @IBOutlet var tableView: NSTableView!
    
    var labelText:String?
    var promptText:String?
    var paths : [String]!
    var confirmationHandler: (([String]?) -> Void )? = nil
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if labelText != nil {
            self.label.stringValue = labelText!
        }
        if promptText != nil {
            self.okButton.title = promptText!
        }
        self.view.window?.minSize = NSSize(width: 400, height: 200)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.selectAll(self)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return paths.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
          guard let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else { return nil }
          
          cell.textField?.stringValue = paths[row]
          return cell
      }
    
    @IBAction func cancelled(_ sender: Any) {
        dismiss(self)
        confirmationHandler?(nil)
    }
    
    @IBAction func confirmed(_ sender: Any) {
        
        var confirmedPaths:[String] = []
        for x in tableView.selectedRowIndexes {
            confirmedPaths.append(paths[x])
        }
        
        dismiss(self)
        confirmationHandler?(confirmedPaths)
    }
}
