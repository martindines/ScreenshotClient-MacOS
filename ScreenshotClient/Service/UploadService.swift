//
//  UploadService.swift
//  ScreenshotUploader01
//
//  Created by Martin Dines on 13/08/2019.
//  Copyright © 2019 Martin Dines. All rights reserved.
//

import Foundation
import Alamofire

class UploadService {
    
    func upload(host: String,
                secret: String,
                file: URL,
                success: ((_ uploadPath: String) -> Void)?,
                failure: ((_ error: String) -> Void)?,
                progress: ((_ percent: Double) -> Void)?) {
        
        // Headers
        let headers: HTTPHeaders
        headers = [
            "Content-type": "multipart/form-data",
            "Content-Disposition" : "form-data",
            "secret": secret
        ]
        
        // Server address (replace this with the address of your own server):
        let url = host + "/api/upload"
        
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(file, withName: "file")
                
                // Parameters are unused. Keeping for future reference
//                let parameters = ["key": "value"]
//                for (key, val) in parameters {
//                    multipartFormData.append(val.data(using: String.Encoding.utf8)!, withName: key)
//                }
        },
            to: url,
            headers: headers) { (result) in
                switch result{
                case .success(let request, _ , _):
                    request.responseJSON(completionHandler: { (response) in
                        switch response.result {
                        case .success(_):
                            var errorMessage: String = ""
                            if let json = response.result.value as? [String: Any] {
                                if let responseSuccess = json["success"] as? Bool {
                                    if responseSuccess {
                                        if let path = json["path"] as? String {
                                            success?(host + path)
                                            return
                                        } else {
                                            errorMessage = "Upload failed. Resource path not returned"
                                        }
                                    } else {
                                        if let error = json["message"] as? String {
                                            errorMessage = "Upload failed. " + error
                                        } else {
                                            errorMessage = "Upload failed. No reason specified"
                                        }
                                    }
                                } else {
                                    errorMessage = "Upload failed. Invalid response from server"
                                }
                            } else {
                                errorMessage = "Upload failed. Invalid response from server"
                            }
                            failure?(errorMessage)
                        case let .failure(error):
                            failure?(error.localizedDescription)
                        }
                        
                        request.uploadProgress(queue: DispatchQueue.global(qos: .utility), closure: { (requestProgress) in
                            progress?(requestProgress.fractionCompleted)
                        })
                    })
                case let .failure(error):
                    failure?(error.localizedDescription)
                }
        }
    }
}
