//
//  Project.swift
//  zira
//
//  Created by Alexander Zakatnov on 19.03.2018.
//  Copyright © 2018 Zaakk. All rights reserved.
//

struct Project: Codable {
    let `self`:String
    let id:String
    let key:String
    let name:String
    let avatarUrls:[String:String]
    let issuetypes:[IssueType]
}
