//
//  AppDelegate.swift
//  OtrWineManager
//
//  Created by Matteo Ceruti on 31.10.25.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var mainWindowController: MainWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        
        // Insert code here to initialize your application
        
        if !NSDocumentController.shared.recentDocumentURLs.isEmpty {
           // let last = NSDocumentController.shared.recentDocumentURLs.last!
            let last = NSDocumentController.shared.recentDocumentURLs[0]
            doOpenAtPath(last.path(percentEncoded: false))
        }
        else {
            open(self)
        }
        
    }
    
    @IBAction func about(_ sender: Any) {
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            NSApplication.AboutPanelOptionKey( rawValue: "Copyright"): "© 2025 matatata"
        ])
    }

    
    

    @IBAction func help(_ sender: Any) {
        
//        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        
        NSWorkspace.shared.open(URL(string: "https://matatata.github.io/MacOpentrack.html")!)
        
    }
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    @IBAction func open(_ sender: Any) {
        
        if let path = pickAppBundle() {
            doOpenAtPath(path)
        }
        
        

    }
    
    func doOpenAtPath(_ filename:String!){
        mainWindowController?.close()
        mainWindowController = nil
        
        mainWindowController = MainWindowController(filename,appDelegate: self)
        mainWindowController?.showWindow(nil)
        
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        
        doOpenAtPath(filename)
       
        return true
    }
    
    func pickAppBundle() -> String? {
        NSApplication.shared.activate()
        let dialog = NSOpenPanel();
        dialog.message = "Pick a Wine application bundle, e.g. CrossOver.app, Homebrew's Wine*.app ..."
        dialog.prompt = "Manage Opentrack DLLs"
        
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = false
        dialog.canCreateDirectories    = false
        
        dialog.allowsOtherFileTypes     = false
        dialog.allowedContentTypes      = [ .applicationBundle ] // .folder,
        dialog.treatsFilePackagesAsDirectories = false
        dialog.allowsMultipleSelection = false
        
        guard dialog.runModal() == .OK else { return nil }
        
        return dialog.url?.path
    }


}

