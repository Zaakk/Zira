//
//  Settings.swift
//  zira
//
//  Created by Alexander Zakatnov on 16.03.2018.
//  Copyright © 2018 Zaakk. All rights reserved.
//

import Cocoa

class Message {
    var text:String = ""
    var response:String = ""
    var isPassword:Bool = false
    
    required init(_ text:String, _ isPassword:Bool = false) {
        self.text = text
        self.isPassword = isPassword
    }
}

class Settings {
    static let shared:Settings = Settings()
    
    private var host:String = ""
    private var user:String = ""
    private var pass:String = ""
    
    func install() -> Bool {
        let messages = [Message("Please, enter your JIRA's host:"), Message("Now, please, enter your jira login:"), Message("And password, please:", true)]
        for message in messages {
            userInputFor(message: message)
        }
        print("Host: \(messages[0].response)")
        print("Login: \(messages[1].response)")
        print("Pass: \(messages[2].response)")
        return true
    }
    
    private func userInputFor(message:Message) {
        if message.isPassword {
            message.response = enterPass(message: message.text)
            return
        }
        print(message.text)
        if let response = readLine() {
            print("Your entered: \(response), are you sure? y/n: ")
            if let sure = readLine() {
                if sure.lowercased() == "y" {
                    message.response = response
                    return
                } else {
                    userInputFor(message:message)
                    return
                }
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
            } else {
                return enterPass(message: message)
            }
        } else {
            print("Something went wrong, please repeat")
            return enterPass(message: message)
        }
    }
}
