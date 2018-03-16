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
}

for i in 1..<CommandLine.arguments.count {
    let argument = CommandLine.arguments[i]
    switch argument {
    case Argument.install.rawValue:
        if Settings.shared.install() {
            print("Success!")
        } else {
            print("Something went wrong. I can't  initiate the tool. Try to start 'install' process again.")
        }
        break
    default:
        break
    }
}

if Settings.shared.isLoggedIn {
    
}

