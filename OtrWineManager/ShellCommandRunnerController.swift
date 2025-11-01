//
//  ShellCommandRunnerController.swift
//  OtrWineManager
//
//  Created by Matteo Ceruti on 31.10.25.
//

import Cocoa

class ShellCommandRunnerController: NSViewController {
    
    @IBOutlet var labelField:NSTextField!
    @IBOutlet var textView:NSTextView!
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var progressIndicator: NSProgressIndicator!
    
    var err:Error?
    
    fileprivate var _runner:ShellCommandRunner?
        
    var runner:ShellCommandRunner? {
        set {
            _runner = newValue
            if !_runner!.mergeStdErr {
                print("isolatedStdErr not allowed")
            }
            _runner?.mergeStdErr=true
        }
        get {
            _runner
        }
    }
    
    var label:String?

    
    var commandDidTerminateCallBack: ((Error?,ShellCommandRunner?) -> Bool)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        preventLineWrap()
        
        labelField.stringValue = label ?? "Output"
        
        progressIndicator.isHidden = true
    }
    
    
    func preventLineWrap(){
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autoresizingMask = NSView.AutoresizingMask(rawValue: (NSView.AutoresizingMask .width.rawValue | NSView.AutoresizingMask .height.rawValue))
        textView.maxSize = NSMakeSize(CGFloat(Float.greatestFiniteMagnitude), CGFloat(Float.greatestFiniteMagnitude))
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = .width
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = NSMakeSize(CGFloat(Float.greatestFiniteMagnitude), CGFloat(Float.greatestFiniteMagnitude))
    }
    
    
    override func viewDidLayout() {
        super.viewDidLayout()
    
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.view.window?.minSize = NSSize(width: 400, height: 200)
        
    }
    
    
    fileprivate func asyncRun(){
       var output:String?
       var err:Error?
       
        do {
            try runner!.safeShell()
            output = runner?.stdout
        }catch {
            err = error
            output = err!.localizedDescription.description
        }
       
       DispatchQueue.main.async {
           self.progressIndicator.isHidden = true
           self.progressIndicator.stopAnimation(self)
           self.textView.string += output ?? ""
           
           if self.commandDidTerminateCallBack != nil && self.commandDidTerminateCallBack!(err,self.runner) == true {
               self.presentingViewController!.dismiss(self)
           }
           
       }
           
    }
    
    func run() {
        
        if runner == nil {
            return
        }
        
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(self)
        
        DispatchQueue.global().async {
            self.asyncRun()
        }
    }
    
    
    
}
