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
}

func help() {
    print("-------------------\nThis is a simple, easy-to-use tool for JIRA.\nThe tool based on JIRA REST API and fully written on Swift\n-------------------")
}

func invalidArguments() {
    help()
    print("\nThere is wrong number of arguments. Check arguments are correct or not.")
    exit(0)
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
case Argument.createIssue.rawValue:
    if (!Settings.shared.isLoggedIn) {
        print("You are not logged in. Enter 'zira install' and walk through install process.")
        break
    }
    let argumentNames = [kSummaryArgKey, kDescriptionArgKey, kProjectArgKey, kIssueTypeArgKey]
    let arguments = argumentsParsing(argumentNames: argumentNames)
    if arguments.count != argumentNames.count {
        invalidArguments()
    }
    guard   let summary = arguments[kSummaryArgKey],
            let description = arguments[kDescriptionArgKey],
            let project = arguments[kProjectArgKey],
            let type = arguments[kIssueTypeArgKey] else {
        invalidArguments()
        exit(0)
    }
    let subtaskKey = [kSubtaskNameArgKey]
    let subtaskArgument = argumentsParsing(argumentNames: subtaskKey)
    let subtask = subtaskArgument[kSubtaskNameArgKey]
    let (result, data) = Net.createIssue(summary: summary, description: description, project: project, type: type, subtask: subtask)
    guard let res = result else {
        print("Something went wrong, I can't parse JIRA's response :(")
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



