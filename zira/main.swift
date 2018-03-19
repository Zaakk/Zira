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
}

func help() {
    
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
    Net.createIssue(summary: "from CLI", description: "description from CLI call", project: "TEST", type: .bug)
    break
default:
    break
}

for i in 1..<CommandLine.arguments.count {
    let argument = CommandLine.arguments[i]
    
}



