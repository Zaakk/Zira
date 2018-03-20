//
//  Net.swift
//  zira
//
//  Created by Alexander Zakatnov on 16.03.2018.
//  Copyright © 2018 Zaakk. All rights reserved.
//

import Cocoa

let kTimeoutInterval:TimeInterval = 20.0
let kAPIVersion = 2
let kIssueEndpoint = "rest/api/\(kAPIVersion)/issue"
let kMetaEndpoint = "rest/api/\(kAPIVersion)/issue/createmeta"


class Net: NSObject {
    
    static func createIssue(summary:String, description:String, type:String?, parent:String?) -> (APIResponse?, Data?) {
        let url = "\(Settings.shared.host)\(kIssueEndpoint)"
        
        guard let issueType = handleIssueType(type: type, isSubtask: parent != nil) else {
            return (nil, nil)
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
        let (data, _, error) = self.syncLoad(url: url, payload: payload)
        if (error != nil) {
            return (nil, data)
        }
        guard let responseData = data else {
            return (nil, nil)
        }
        
        do {
            let result = try JSONDecoder().decode(APIResponse.self, from: responseData)
            return (result, responseData)
        } catch {
            return (nil, responseData)
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
    
    static func syncLoad(url:String, payload:[String:Any]) -> (Data?, URLResponse?, Error?) {
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
        request.httpMethod = "POST"
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
    
    static func loadProjects() -> Meta? {
        let urlStr = "\(Settings.shared.host)\(kMetaEndpoint)"
        guard let url = URL(string: urlStr) else {
            return nil
        }
        let request = NSMutableURLRequest(url: url)
        request.allHTTPHeaderFields = self.headers()
        let (data, _, error) = load(request: request)
        if error != nil {
            return nil
        }
        guard let d = data else {
            return nil
        }
        do {
            let meta = try JSONDecoder().decode(Meta.self, from: d)
            return meta
        } catch {
            return nil
        }
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
    
}
