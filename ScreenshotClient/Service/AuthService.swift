//
//  UploadService.swift
//  ScreenshotUploader01
//
//  Created by Martin Dines on 13/08/2019.
//  Copyright © 2019 Martin Dines. All rights reserved.
//

import Foundation
import Alamofire

class AuthService {
    
    func test(host: String,
              secret: String,
              success: ((_ result: Any) -> Void)?,
              failure: ((_ error: String) -> Void)?) {
        
        let headers: HTTPHeaders
        headers = [
            "secret": secret
        ]
        
        let url = host + "/api/auth"
        
        Alamofire.request(url, method: .get, headers: headers)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJSON(completionHandler: { response in
                
                var errorMessage: String = ""
                
                switch response.result {
                case .success(_):
                    if let json = response.result.value as? [String: Any] {
                        if let responseSuccess = json["success"] as? Bool {
                            if responseSuccess {
                                success?(json)
                                return
                            } else {
                                if let error = json["message"] as? String {
                                    errorMessage = "Authentication failed. " + error
                                } else {
                                    errorMessage = "Authentication failed. No reason specified"
                                }
                            }
                        } else {
                            errorMessage = "Authentication failed. Invalid response from server"
                        }
                    } else {
                        errorMessage = "Authentication failed. Invalid response from server"
                    }
                case let .failure(error):
                    errorMessage = error.localizedDescription
                }
                
                failure?(errorMessage)
            })
    }
}

