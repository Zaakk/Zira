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

enum IssueType:String {
    case bug = "Bug"
    case task = "Task"
    case feature = "Feature"
    case epic = "Epic"
}

class Net: NSObject {
    
    static func createIssue(summary:String, description:String, project:String, type:IssueType) {
        let url = "\(Settings.shared.host)\(kIssueEndpoint)"
        
        let payload:[String:Any] =   [
                            "fields": [
                                "project": [
                                    "key": project
                                ],
                                "summary": summary,
                                "description": description,
                                "issuetype": [
                                    "name": type.rawValue
                                ]
                            ]
                        ]
        
        let (data, _, error) = self.syncLoad(url: url, payload: payload)
        if (error != nil) {
            print("\(String(describing: error))")
            exit(0)
        }
        guard let responseData = data else {
            return
        }
        
        do {
            let result = try JSONDecoder().decode(APIResponse.self, from: responseData)
            print("\(result)")
        } catch {
            print("Something went wrong, I can't parse JIRA's response :(")
            exit(0)
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
        
        let semaphore = DispatchSemaphore(value: 0)
        var dataResp: Data?
        var serverResponse: URLResponse?
        var errorResp: Error?
        
        
        guard let url = URL(string: url) else {
            self.triggerNetworkExit()
            return (nil, nil, nil)
        }
        
        var postData = Data()
        do {
            postData = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            self.triggerNetworkExit()
        }
        
        let request = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: kTimeoutInterval)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = self.headers()
        request.httpBody = postData
        
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
    
    private static func triggerNetworkExit() {
        print("Incorrect network request. Hmm, try to check all parameters.")
        exit(0)
    }
    
}
