//
//  FlickrClient.swift
//  Virtual-Tourist
//
//  Created by Jack Ngai on 10/28/16.
//  Copyright © 2016 Jack Ngai. All rights reserved.
//

import Foundation

class FlickrClient: NSObject {
    
    // shared session
    var session = URLSession.shared
    
    // MARK: Create a bounding box to designate the area of photos that Flickr should retrieve
    func bboxString(latitude: Double, longitude: Double) -> String {
        let minLat = max(-90.00,latitude - FlickrConstants.SearchBBoxHalfWidth)
        let maxLat = min(90.00, latitude + FlickrConstants.SearchBBoxHalfWidth)
        let minLon = max(-180.00, longitude - FlickrConstants.SearchBBoxHalfHeight)
        let maxLon = min(180.00, longitude + FlickrConstants.SearchBBoxHalfHeight)
        
        return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
    }
    
    // MARK: Convert Received JSON data to foundation objects
    fileprivate func convertDataWithCompletionHandler(data: Data, completionHandler: (_ result: AnyObject?, _ error: Error?)->Void){
        var parsedResult:Any!
        do{
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            print("Error converting JSON to foundation objects")
        }
        completionHandler(parsedResult as AnyObject, nil)
    }
    
    
    // MARK: Task to process request with session.dataTask
    func startTask(request: URLRequest, completionHandlerForTask: @escaping (_ result: AnyObject?, _ error: Error?)->Void)->URLSessionDataTask{
        let task = session.dataTask(with: request){
            data, response, error in
            
            guard error == nil else {
                print("Received error at startTask method. Error: \(error)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Status code: \((response as? HTTPURLResponse)?.statusCode))")
                return
            }
            
            guard let data = data else {
                print("data field is nil at startTask method")
                return
            }
            
            self.convertDataWithCompletionHandler(data: data, completionHandler: completionHandlerForTask)
        }
        task.resume()
        return task
    }
    
    
    // MARK: Get
    func get(parameters: [String:AnyObject])->URLRequest{
        let url = buildURL(scheme: FlickrConstants.APIScheme, host: FlickrConstants.APIHost, path: FlickrConstants.APIPath, parameters: parameters)
        let request = URLRequest(url: url)
        return request
    }
    
    
    // MARK: Build URL
    func buildURL(scheme: String, host: String, path: String, parameters:[String:AnyObject]) -> URL{
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        
        components.queryItems = [URLQueryItem]()
        for (key, value) in parameters{
            let queryItem = URLQueryItem(name: key, value: value as? String)
            components.queryItems?.append(queryItem)
        }
        guard let url = components.url else {
            print("Error building URL")
            return URL(string: "")!
        }
        return url
    }
    
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
}
