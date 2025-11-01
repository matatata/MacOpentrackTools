//
//  MainWindowController.swift
//  OtrWineManager
//
//  Created by Matteo Ceruti on 31.10.25.
//

import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {
    @IBOutlet var viewController: NSViewController!
    @IBOutlet var labelField: NSTextField!
    @IBOutlet var installButton: NSButton!
    @IBOutlet var uninstallButton: NSButton!
    
    @IBOutlet var details: NSButton!
    
    var appDelegate:AppDelegate!
    var wineEnvPath:String!
    var detectedPaths:[String]?
    var showDetails:Bool {
        get {
            details.state == .on
        }
    }
    
    enum State {
        case Initial
        case Detected
        case Verified
        case Confirmed
        case NotWine
        case Error
    }
    
    var _state:State = .Initial
    var state:State {
        get {
            return _state
        }
        set {
            _state = newValue
            updateStatus()
        }
        
    }
   
    
    convenience init(_ path:String!, appDelegate:AppDelegate ) {
        self.init(windowNibName: "MainWindowController")
        self.wineEnvPath = path
        self.shouldCascadeWindows = false
        self.appDelegate = appDelegate
    }
    
    @IBAction func quit(_ sender: Any) {
        NSApplication.shared.terminate(sender)
    }
    
    @IBAction func pickAnother(_ sender: Any) {
        
        appDelegate.open(sender)
    }
    
    
    
    fileprivate func updateStatus(){
        switch state {
        case .Initial:
            installButton.isEnabled = false
            uninstallButton.isEnabled = false
            labelField.stringValue = ""
            details.isHidden = true
            break
        case .Detected:
            labelField.stringValue = "🟡 Opentrack DLLs not installed"
            installButton.isEnabled = true
            uninstallButton.isEnabled = false
            details.isHidden = false
            break
        case .Confirmed:
            labelField.stringValue = "✅ Confirmed"
            break
        case .Verified:
            labelField.stringValue = "🟢 Opentrack DLLs installed"
            installButton.isEnabled = false
            uninstallButton.isEnabled = true
            details.isHidden = false
            break
        case .NotWine:
            labelField.stringValue = "🔴 Unrecognized"
            details.isHidden = true
        case .Error:
            labelField.stringValue = "🚫 Error"
            details.isHidden = true
            break
        }
    }
    
    @discardableResult
    fileprivate func detect() -> Bool {
        var runner = ShellCommandRunner(executablePath: "/usr/local/bin/otrwine", args: ["detect", wineEnvPath])
        runner.mergeStdErr = false
        
        runner.run()
        if (runner.terminationStatus == 0 ){
            state = .Detected
            detectedPaths = runner.stdout?.components(separatedBy: "\n")
            return true
        }
        state = .NotWine
        
        if runner.stderr != nil && !runner.stderr!.isEmpty{
            labelField.stringValue = "🚫 " + runner.stderr!
        }
        
        return false;
    }
    
    fileprivate func confirm(label:String, followup:  @escaping ([String]) -> Void) {
        let confirmView = ConfirmPathsView();
        confirmView.labelText = label
        confirmView.paths = detectedPaths
        confirmView.confirmationHandler = { paths -> Void in
            self.onConfirmed(paths, followup: followup)
        }
        
        contentViewController!.presentAsSheet(confirmView)
    }
    
    fileprivate func onConfirmed(_ paths:[String]?, followup: ([String]) -> Void){
        if paths != nil {
            state = .Confirmed
            followup(paths!)
        }
    }
    
    fileprivate func verify() -> Bool {
        var runner = ShellCommandRunner(executablePath: "/usr/local/bin/otrwine", args: ["verify", wineEnvPath])
        runner.run()
        if (runner.terminationStatus == 0 ){
            state = .Verified
            return true
        }
        state = .Error
        return false;
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window!.center()
        window!.title = wineEnvPath
        contentViewController = viewController
        
        state = .Initial
        
        window?.delegate = self
        
        window?.makeKeyAndOrderFront(self)
        
        labelField.stringValue = "checking..."
        labelField.isHidden = false
        
        
        if detect() {
            NSDocumentController.shared.noteNewRecentDocumentURL(NSURL.fileURL(withPath: wineEnvPath))
            if !verify() {
                state = .Detected
            }
        }
        
        
    }
    
    fileprivate func execute(paths: [String], command: String,label:String?,  commandDidTerminateCallBack: ((Error?,ShellCommandRunner?) -> Bool)?) {
        
        
        var args = [command]
        args.append(contentsOf: paths)
        
        var runner = ShellCommandRunner(executablePath: "/usr/local/bin/otrwine", args: args)
        
        if !showDetails {
            runner.run()
            commandDidTerminateCallBack!(nil,runner)
        }
        else {
            let runnerController = ShellCommandRunnerController()
            runnerController.label = label
            runnerController.runner = runner
            runnerController.commandDidTerminateCallBack =  commandDidTerminateCallBack
            contentViewController!.presentAsSheet(runnerController)
            runnerController.run()
        }
    }
    
  
    
    
    fileprivate func doInstall(paths: [String]) {
        execute(paths: paths, command: "install",label: "Creating symbolic links") { error, sender in
            if sender?.terminationStatus == 0 {
                if self.verify() {
                    return !self.showDetails
                }
                else {
                    self.state = .Detected
                }
            }
            else {
                self.state = .Error
            }
            return false
        }
    }
    
   
    
    
    fileprivate func doUninstall(paths: [String]) {
        execute(paths: paths, command: "uninstall", label: "Removing symbolic links") { error, sender in
            if sender?.terminationStatus == 0 {
                if self.verify() {
                    self.state = .Error
                }
                else {
                    self.state = .Detected
                }
                
                self.state = .Detected
                return !self.showDetails
                
            }
            else {
                self.state = .Error
            }
            return false
        }
    }
    
    @IBAction func install(_ sender: Any) {
        
        if showDetails {
            confirm(label:"The following Wine DLL directories were found for you to review. You can make adjustments to the selection, if you think something's been wrongly identified. Only selected rows will be touched.", followup: self.doInstall(paths:))
        }
        else {
            doInstall(paths: [wineEnvPath])
        }
        
    }
    
    @IBAction func uninstall(_ sender: Any) {
        doUninstall(paths: [wineEnvPath])
    }
    
    
    
}
