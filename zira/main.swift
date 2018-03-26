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
    case create = "create"
    case issueTypes = "issueTypes"
    case issueStatuses = "issueStatuses"
    case edit = "edit"
    case help = "--help"
}

func help() {
    print("-------------------\nThis is a simple, easy-to-use tool for JIRA.\nThe tool based on JIRA REST API and fully written on Swift\n-------------------")
    print("There is a list of available arguments and theirs parameters")
    print("`install` - initiate authorization and setting process. No parameters")
    print("`createIssue` - creating issue. Parameters: -summary, summary of issue, -description, description of issue, -type, type of issue, make sure you specify the correct type by enter command `issueTypes`, -parent, name of parent issue if you specify this parameter it requires correct issue type. Example:")
    print("zira createIssue -summary \"Issue's summary\" -description \"Issue's description\" -type Sub-Task -parent \"PROJ-1\"")
    print("`editIssue` - for now this parameter able to change issue's status. Parameters: -issue, Issue's name like \"PROJ-12\", -status, New status. Pay attention and specify correct status. You can get all available statuses by command `zira issueStatuses`")
    print("`issueTypes` - output all available issue types")
    print("`issueStatuses` - output all available issue statuses")
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

let argumentNames = [kLoginArgKey, kPassArgKey, kHostArgKey, kProjectArgKey]
let arguments = argumentsParsing(argumentNames: argumentNames)
if  arguments[kLoginArgKey] != nil &&
    arguments[kPassArgKey] != nil &&
    arguments[kHostArgKey] != nil {
    
    let login = arguments[kLoginArgKey]!
    let pass = arguments[kPassArgKey]!
    let host = arguments[kHostArgKey]!
    Settings.shared.user = login
    Settings.shared.pass = pass
    Settings.shared.host = host
}

if arguments[kProjectArgKey] != nil {
    let project = arguments[kProjectArgKey]
    if !Settings.shared.setProjectName(name: project) {
        print("You entered incorrect project name. Please make sure that you entered correct project name.")
        exit(0)
    }
}

switch firstArgument {
case Argument.install.rawValue:
    var installed = false
    if CommandLine.arguments.count > 2 {
        let argumentNames = [kLoginArgKey, kPassArgKey, kHostArgKey, kProjectArgKey]
        let arguments = argumentsParsing(argumentNames: argumentNames)
        guard   let user = arguments[kLoginArgKey],
                let pass = arguments[kPassArgKey],
                let host = arguments[kHostArgKey],
                let project = arguments[kProjectArgKey] else {
                    invalidArguments()
                    exit(0)
        }
        installed = Settings.shared.install(user: user, pass: pass, host: host, project: project)
    } else {
        installed = Settings.shared.install()
    }
    if installed {
        print("Success!")
    } else {
        print("Something went wrong. I can't  initiate the tool. Try to start 'install' process again.")
    }
    break
case Argument.edit.rawValue:
    checkLogin()
    let argumentNames = [kIssueArgKey, kIssueStatusArgKey, kAssignIssueArgKey, kDescriptionArgKey, kSummaryArgKey]
    let arguments = argumentsParsing(argumentNames: argumentNames)
    guard   let issue = arguments[kIssueArgKey] else {
            invalidArguments()
            exit(0)
    }
    let status = arguments[kIssueStatusArgKey]
    let summary = arguments[kSummaryArgKey]
    let assign = arguments[kAssignIssueArgKey]
    let description = arguments[kDescriptionArgKey]
    if status != nil && !Net.changeIssueStatus(issue: issue, status: status!) {
        print("Something went wrong.")
        print("Try to check entered issue status.\nYou can list all availables issue statuses for current project by command `zira issueStatuses`")
        exit(0)
    }
    if !Net.editIssue(issue: issue, summary: summary, description: description, assign: assign) {
        print("Something went wrong.")
        print("Try to check entered parameters.\nPay attention on username.")
        exit(0)
    }
    print("Success!\nThe issue has been edited\n\n")
    break
case Argument.issueStatuses.rawValue:
    checkLogin()
    
    print("Available issue statuses:")
    for status in Settings.shared.statuses {
        print(" – \(status.name)")
    }
    
    break
case Argument.issueTypes.rawValue:
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
case Argument.create.rawValue:
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
    let result = Net.createIssue(summary: summary, description: description, type: type, parent: parent)
    guard let res = result else {
        print("Something went wrong.")
        print("Try to check entered issue type.\nAlso you should be ensure that you entered correct issue type if you want to create subtask.\nYou can list all availables issue types for current project by command `zira issuetypes`")
        exit(0)
    }
    print("Success!\nThere was created an issue.\n\n\(res)\n\n")
    break
case Argument.help.rawValue:
    help()
    break
default:
    break
}



