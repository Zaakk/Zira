//
//  Settings.swift
//  zira
//
//  Created by Alexander Zakatnov on 16.03.2018.
//  Copyright © 2018 Zaakk. All rights reserved.
//

import Foundation

class Settings:Codable {
    static let shared:Settings = Settings()
    
    var host:String = "" {
        didSet {
            if !host.hasPrefix("http") {
                host = "http://\(host)"
            }
            if !host.hasSuffix("/") {
                host = "\(host)/"
            }
        }
    }
    var user:String = ""
    var pass:String = ""
    var project:Project?
    var statuses:[Status] = []
    
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
            let settings = try JSONDecoder().decode(Settings.self, from: data)
            self.host = settings.host
            self.user = settings.user
            self.pass = settings.pass
            self.project = settings.project
            self.statuses = settings.statuses
        } catch {
            print("Sorry, but I can't read settings file")
        }
    }
    
    func install() -> Bool {
        let host = userInputFor(message: "Please, enter your JIRA's host:")
        let user = userInputFor(message: "Now, please, enter your jira login:")
        let pass = userInputFor(message: "And password, please:", isPassword: true)
        
        return install(user: user, pass: pass, host: host, project: nil)
    }
        
    
    func install(user:String, pass:String, host:String, project:String?) -> Bool {
        self.user = user
        self.pass = pass
        self.host = host
        
        if !setProjectName(name: project) {
            return false
        }
        
        guard let loadedStatuses:[Status] = Net.loadMeta("\(Settings.shared.host)\(kIssueStatusesEndpoint)") else {
            return false
        }
        
        statuses = loadedStatuses
        
        print("Just FYI. Available issue statuses:")
        for status in statuses {
            print(" – \(status.name)")
        }
        
        return save()
    }
    
    func setProjectName(name:String?) -> Bool {
        guard let meta:Meta = Net.loadMeta("\(Settings.shared.host)\(kMetaEndpoint)") else {
            logout()
            return false
        }
        
        if name == nil {
            self.project = selectProject(projects: meta.projects)
            return true
        }
        
        for proj in meta.projects {
            if proj.name == name {
                self.project = proj
                return true
            }
        }
        if self.project == nil {
            logout()
            return false
        }
        return true
    }
    
    func logout() {
        host = ""
        user = ""
        pass = ""
        project = nil
    }
    
    private func selectProject(projects:[Project]) -> Project {
        print("Select project, type number:")
        var counter = 0
        for project in projects {
            counter += 1
            print(" – \(project.name) (\(counter))")
        }
        print("------\nYou will be able to change current project at any time.")
        guard let response:String = readLine(), var enteredNumber = Int(response) else {
            print("You entered incorrect value. Try again, pleease.")
            return selectProject(projects:projects)
        }
        enteredNumber -= 1 // because user is entering value that starts from 1
        if enteredNumber >= projects.count || enteredNumber < 0 {
            print("You entered incorrect number. Try again, pleease.")
            return selectProject(projects: projects)
        }
        return projects[enteredNumber]
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
    
    func save() -> Bool {
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: self.homeDirURL)
            return true
        } catch {
            print("can't save local settings")
            return false
        }
    }
}
