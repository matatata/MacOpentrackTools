//
//  ShellCommandRunner.swift
//  storytest
//
//  Created by Matteo Ceruti on 30.10.25.
//

import Cocoa

struct ShellCommandRunner {
    let executablePath:String!
    let args:[String]!
    var mergeStdErr:Bool=true
    var stdout: String?
    var stderr: String?
    
    var terminationStatus: Int32 = 0
    
    init(executablePath: String!,args:[String]!) {
        self.executablePath = executablePath
        self.args = args
    }
    
    mutating func run(){
        do {
            try safeShell()
        }catch {
            self.stderr = error.localizedDescription.description
        }
    }
    
    
    mutating func safeShell() throws {
        let task = Process()
        
        let stdoutPipe = Pipe();
        let stderrPipe = mergeStdErr ? stdoutPipe : Pipe()
        
        task.standardOutput = stdoutPipe
        task.standardError = stderrPipe
        task.arguments = args
        task.executableURL = URL(fileURLWithPath: executablePath)
        task.standardInput = nil
        
        try task.run()
        
        let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        stdout = String(data: data, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)
        if !mergeStdErr {
            let data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            stderr = String(data: data, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        task.waitUntilExit()
        
        self.terminationStatus = task.terminationStatus
    }
    
}
