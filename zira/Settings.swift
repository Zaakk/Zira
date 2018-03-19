//
//  Settings.swift
//  zira
//
//  Created by Alexander Zakatnov on 16.03.2018.
//  Copyright © 2018 Zaakk. All rights reserved.
//

import Cocoa

class Settings {
    static let shared:Settings = Settings()
    
    var host:String = ""
    var user:String = ""
    var pass:String = ""
    
    var isLoggedIn:Bool {
        get {
            return host != "" && user != "" && pass != ""
        }
    }
    
    private var homeDirURL:URL {
        get {
            var url = FileManager.default.homeDirectoryForCurrentUser
            url.appendPathComponent(".zira", isDirectory: true)
            
            if !FileManager.default.fileExists(atPath: url.absoluteString, isDirectory: nil) {
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Something bad happens. I cant create my own directory to store your settings")
                }
            }
            
            url.appendPathComponent("settings", isDirectory: false)
            
            return url
        }
    }
    
    required init() {
        
        if !FileManager.default.fileExists(atPath: self.homeDirURL.relativePath) {
            return
        }
        
        do {
            let data = try Data(contentsOf: self.homeDirURL)
            guard   let dict:[String:String] = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:String],
                    var host = dict["host"],
                    let user = dict["user"],
                    let pass = dict["pass"] else {
                        print("Sorry, but I can't read settings file")
                        return
            }
            if !host.hasPrefix("http") {
                host = "http://\(host)"
            }
            if !host.hasSuffix("/") {
                host = "\(host)/"
            }
            self.host = host
            self.user = user
            self.pass = pass
        } catch {
            print("Sorry, but I can't read settings file")
        }
    }
    
    func install() -> Bool {
        self.host = userInputFor(message: "Please, enter your JIRA's host:")
        self.user = userInputFor(message: "Now, please, enter your jira login:")
        self.pass = userInputFor(message: "And password, please:", isPassword: true)
        
        return save()
    }
    
    private func save() -> Bool {
        
//        let (data, response, error) = Net.load(request: nil)
        let dict:[String:String] = ["host": self.host, "user": self.user, "pass": self.pass]
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            try data.write(to: self.homeDirURL)
            return true
        } catch {
            print("can't save local settings")
            return false
        }
    }
    
    private func userInputFor(message:String, isPassword:Bool = false) -> String{
        if isPassword {
            return enterPass(message: message)
        }
        print(message)
        if let response = readLine() {
            print("Your entered: \(response), are you sure? y/n: ")
            if let sure = readLine() {
                if sure.lowercased() == "y" {
                    return response
                }
                return userInputFor(message:message, isPassword: isPassword)
            }
        }
        print("Nothing :(")
        exit(0)
    }
    
    private func enterPass(message:String, isRepeat:Bool = false) -> String {
        let buf = [Int8](repeating: 0, count: 8192)
        if let password = readpassphrase(message, (UnsafeMutablePointer<Int8>)(mutating: buf), buf.count, 0),
            let passwordStr = String(validatingUTF8: password) {
            if isRepeat {
                return passwordStr
            }
            if passwordStr == enterPass(message: "Please, repeat: ", isRepeat: true) {
                return passwordStr
            }
            return enterPass(message: message)
        } else {
            print("Something went wrong, please repeat")
            return enterPass(message: message)
        }
    }
}
