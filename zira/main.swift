//
//  main.swift
//  zira
//
//  Created by Alexander Zakatnov on 16.03.2018.
//  Copyright © 2018 Zaakk. All rights reserved.
//

import Foundation

enum Argument:String {
    case install = "install"
    case createIssue = "createIssue"
    case createSubtask = "createSubtask"
    case issuetypes = "issuetypes"
}

func help() {
    print("-------------------\nThis is a simple, easy-to-use tool for JIRA.\nThe tool based on JIRA REST API and fully written on Swift\n-------------------")
}

func invalidArguments() {
    help()
    print("\nThere is wrong number of arguments. Check arguments are correct or not.")
    exit(0)
}

func checkLogin() {
    if (!Settings.shared.isLoggedIn) {
        print("You are not logged in. Enter 'zira install' and walk through install process.")
        exit(0)
    }
}

func argumentsParsing(argumentNames:[String]) -> [String:String] {
    var values:[String:String] = [:]
    for name in argumentNames {
        if CommandLine.arguments.contains(name) {
            guard let argcIndex = CommandLine.arguments.index(of: name) else {
                continue
            }
            let argvIndex = argcIndex + 1
            if CommandLine.arguments.count <= argvIndex {
                continue
            }
            values[name] = CommandLine.arguments[argvIndex]
        }
    }
    return values
}

if CommandLine.arguments.count == 1 {
    help()
    exit(0)
}

let firstArgument = CommandLine.arguments[1]

switch firstArgument {
case Argument.install.rawValue:
    if Settings.shared.install() {
        print("Success!")
    } else {
        print("Something went wrong. I can't  initiate the tool. Try to start 'install' process again.")
    }
    break
case Argument.issuetypes.rawValue:
    checkLogin()
    
    guard let project = Settings.shared.project else {
        print("Something went wrong, I can't find current project so you will be logout and you have to use `zira install` again. Sorry but it's necessary :(")
        Settings.shared.logout()
        exit(0)
    }
    
    print("Issue types for current project:")
    for issueType in project.issuetypes {
        print(" – Name: `\(issueType.name)` is it subtask type: \(issueType.subtask ? "yes" : "no")")
    }
    break
case Argument.createIssue.rawValue:
    checkLogin()
    let argumentNames = [kSummaryArgKey, kDescriptionArgKey, kIssueTypeArgKey, kParentNameArgKey]
    let arguments = argumentsParsing(argumentNames: argumentNames)
    guard   let summary = arguments[kSummaryArgKey],
            let description = arguments[kDescriptionArgKey] else {
        invalidArguments()
        exit(0)
    }
    let type = arguments[kIssueTypeArgKey]
    let parent = arguments[kParentNameArgKey]
    let (result, data) = Net.createIssue(summary: summary, description: description, type: type, parent: parent)
    guard let res = result else {
        print("Something went wrong.")
        print("Try to check entered issue type.\nAlso you should be ensure that you entered correct issue type if you want to create subtask.\nYou can list all availables issue types for current project by command `zira issuetypes`")
        guard let d = data else {
            exit(0)
        }
        print("data:")
        print("\(String(data: d, encoding: .utf8) ?? "No data")")
        exit(0)
    }
    print("Success!\nThere was created an issue.\n\n\(Settings.shared.host)browse/\(res.key)\n\n")
    break
default:
    break
}



