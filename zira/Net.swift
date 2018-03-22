//
//  Net.swift
//  zira
//
//  Created by Alexander Zakatnov on 16.03.2018.
//  Copyright © 2018 Zaakk. All rights reserved.
//

import Foundation

let kTimeoutInterval:TimeInterval = 20.0
let kAPIVersion = 2
let kIssueEndpoint = "rest/api/\(kAPIVersion)/issue"
let kMetaEndpoint = "rest/api/\(kAPIVersion)/issue/createmeta"
let kIssueStatusesEndpoint = "rest/api/\(kAPIVersion)/status"
let kChangeIssueStatusEndpoint = "rest/api/\(kAPIVersion)/issue/%@/transitions"
let kEditIssueEndpoint = "rest/api/\(kAPIVersion)/issue/%@/"

enum HTTPMethod:String {
    case post = "POST"
    case get = "GET"
    case put = "PUT"
}

class Net {
    
    static func createIssue(summary:String, description:String, type:String?, parent:String?) -> String? {
        let url = "\(Settings.shared.host)\(kIssueEndpoint)"
        
        guard let issueType = handleIssueType(type: type, isSubtask: parent != nil) else {
            return nil
        }
        
        var payload:[String:Any] =   [
                            "fields": [
                                "project": [
                                    "key": Settings.shared.project?.key
                                ],
                                "summary": summary,
                                "description": description,
                                "issuetype": [
                                    "name": issueType
                                ]
                            ]
                        ]
        
        if parent != nil {
            var fields:[String:Any] = payload["fields"] as! [String:Any]
            fields["parent"] = ["key": parent!]
            payload["fields"] = fields
        }
        let (data, _, error) = self.syncLoad(method: .post, url: url, payload: payload)
        if (error != nil) {
            return nil
        }
        guard let responseData = data else {
            return nil
        }
        
        do {
            let result = try JSONDecoder().decode(APIResponse.self, from: responseData)
            return "\(Settings.shared.host)browse/\(result.key)"
        } catch {
            return nil
        }
    }
    
    static func editIssue(issue:String, summary:String?, description:String?, assign:String?) -> Bool {
        let url = String(format: "\(Settings.shared.host)\(kEditIssueEndpoint)", issue)
        
        var dict:[String:Any] = [:]
        
        if summary != nil {
            dict["summary"] = [["set" : summary!]]
        }
        if description != nil {
            dict["description"] = [["set" : description!]]
        }
        if assign != nil {
            dict["assignee"] = [["set" : [ "name": assign! ] ]]
        }
        
        let payload:[String:Any] = ["update": dict]
        
        let (_, response, error) = self.syncLoad(method: .put, url: url, payload: payload)
        if (error != nil) {
            return false
        }
        guard let resp = response as? HTTPURLResponse, resp.statusCode == 204 else {
            return false
        }
        return true
        
    }
    
    static func changeIssueStatus(issue:String, status:String) -> Bool {
        let url = String(format: "\(Settings.shared.host)\(kChangeIssueStatusEndpoint)", issue)
        
        guard let newStatusId = handleIssueStatus(status, for: url) else {
            return false
        }
        
        let payload:[String:Any] =  [
                                        "transition": [
                                            "id": newStatusId
                                        ]
                                    ]
        
        let (_, response, error) = self.syncLoad(method: .post, url: url, payload: payload)
        if (error != nil) {
            return false
        }
        guard let resp = response as? HTTPURLResponse, resp.statusCode == 204 else {
            return false
        }
        return true
    }
    
    static func loadMeta<T:Codable>(_ urlStr:String) -> T? {
        let (data, error) = get(urlStr)
        
        if error != nil {
            return nil
        }
        guard let d = data else {
            return nil
        }
        do {
            let statuses:T = try JSONDecoder().decode(T.self, from: d)
            return statuses
        } catch {
            return nil
        }
    }
    
    static func headers() -> [String:String]? {
        
        let credString = "\(Settings.shared.user):\(Settings.shared.pass)"
        
        let utf8str = credString.data(using: .utf8, allowLossyConversion: true)
        
        guard let base64Encoded = utf8str?.base64EncodedString(options: .lineLength64Characters) else {
            return nil
        }
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Basic \(base64Encoded)",
            "Cache-Control": "no-cache"
        ]
        
        return headers
    }
    
    private static func get(_ urlStr:String) -> (Data?, Error?) {
        guard let url = URL(string: urlStr) else {
            return (nil, nil)
        }
        let request = NSMutableURLRequest(url: url)
        request.allHTTPHeaderFields = self.headers()
        let (data, _, error) = load(request: request)
        return (data, error)
    }
    
    static func syncLoad(method:HTTPMethod, url:String, payload:[String:Any]) -> (Data?, URLResponse?, Error?) {
        guard let url = URL(string: url) else {
            return (nil, nil, nil)
        }
        
        var postData = Data()
        do {
            postData = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            return (nil, nil, nil)
        }
        
        let request = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: kTimeoutInterval)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = self.headers()
        request.httpBody = postData
        
        return load(request: request)
    }
    
    static func load(request:NSURLRequest) -> (Data?, URLResponse?, Error?) {
        let semaphore = DispatchSemaphore(value: 0)
        var dataResp: Data?
        var serverResponse: URLResponse?
        var errorResp: Error?
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            dataResp = data
            serverResponse = response
            errorResp = error
            semaphore.signal()
        })
        dataTask.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (dataResp, serverResponse, errorResp)
    }
    
    private static func handleIssueType(type:String?, isSubtask:Bool) -> String? {
        guard let project = Settings.shared.project else {
            return nil
        }
        
        let issueTypes:[IssueType] = project.issuetypes
        
        if type == nil {
            return issueTypes.first?.name
        }
        
        for issueType in issueTypes {
            if type == issueType.name && issueType.subtask == isSubtask {
                return type
            }
        }
        
        return nil
    }
    
    private static func handleIssueStatus(_ newStatus:String, for url:String) -> String? {
        guard let issueStatuses:IssueStatuses = loadMeta(url) else {
            return nil
        }
        for status in issueStatuses.transitions {
            if newStatus == status.name {
                return status.id
            }
        }
        return nil
    }
    
}
