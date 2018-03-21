//
//  IssueType.swift
//  zira
//
//  Created by Alexander Zakatnov on 19.03.2018.
//  Copyright © 2018 Zaakk. All rights reserved.
//

struct IssueType: Codable {
    let `self`:String
    let id:String
    let description:String
    let name:String
    let subtask:Bool
}
