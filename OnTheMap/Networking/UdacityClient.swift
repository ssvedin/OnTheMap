//
//  UdacityClient.swift
//  OnTheMap
//
//  Created by Sabrina on 3/26/19.
//  Copyright © 2019 Sabrina Svedin. All rights reserved.
//

import Foundation

class UdacityClient: NSObject {
    
    struct Auth {
        static var sessionId: String? = nil
        static var key = ""
        static var firstName = ""
        static var lastName = ""
    }
    
    override init() {
        super.init()
    }
 
    class func shared() -> UdacityClient {
        struct Singleton {
            static var shared = UdacityClient()
        }
        return Singleton.shared
    }
    
    class func login(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        
        var request = URLRequest(url: URL(string: "https://onthemap-api.udacity.com/v1/session")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"udacity\": {\"username\": \"\(email)\", \"password\": \"\(password)\"}}".data(using: .utf8)
       
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(false, error)
                return
            }
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            if statusCode == 400 || statusCode == 403 {
                DispatchQueue.main.async {
                    completion(false, error)
                }
            }
            
            let decoder = JSONDecoder()
            do {
                let range = 5..<data.count
                let newData = data.subdata(in: range)
                print(String(data: newData, encoding: .utf8)!)
                let responseObject = try decoder.decode(LoginResponse.self, from: newData)
                Auth.sessionId = responseObject.session.id
                Auth.key = (responseObject.account.key)
                var profileURLString = URLRequest(url: URL(string: "https://onthemap-api.udacity.com/v1/users/\(responseObject.account.key)")!)
                profileURLString.httpMethod = "GET"
                let task = URLSession.shared.dataTask(with: profileURLString) { data, response, error in
                    if error != nil {
                        return
                    }
                    let range = 5..<data!.count
                    let newData = data?.subdata(in: range)
                    print("printing profile")
                    print(String(data: newData!, encoding: .utf8)!)
                    
                    guard let profileResponseData = newData else { exit(1) }
                    print("Decoding Profile JSON")
                    
                    guard let profileObject = try? JSONDecoder().decode(UserProfile.self, from: profileResponseData) else {
                        print("Failed to decode profile JSON")
                        exit(1)
                    }
                    print("First Name : \(profileObject.firstName) && Last Name : \(profileObject.lastName) && Full Name: \(profileObject.nickname)")
                    Auth.firstName = profileObject.firstName
                    Auth.lastName = profileObject.lastName
                    
                }
                task.resume()
                completion(true, nil)
            } catch {
                do {
                    let errorResponse = try decoder.decode(LoginErrorResponse.self, from: data) as Error
                    DispatchQueue.main.async {
                        completion(false, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(false, error)
                    }
                }
            }
            
        }
       task.resume()
        
    }
    
    class func getStudentsLocation(completion: @escaping ([StudentInformation]?, Error?) -> Void) {
        var request = URLRequest(url: URL(string: "https://parse.udacity.com/parse/classes/StudentLocation")!)
        request.addValue(Constants.Parse.ApplicationId, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(Constants.Parse.APIKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        let task = URLSession.shared.dataTask(with: request) { data, response, error  in
            guard let data = data else {
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(StudentsLocation.self, from: data)
                completion(responseObject.results, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    class func addStudentLocation(information: StudentInformation, completion: @escaping (Bool, Error?) -> Void) {
        var request = URLRequest(url: URL(string: "https://parse.udacity.com/parse/classes/StudentLocation")!)
        request.httpMethod = "POST"
        request.addValue(Constants.Parse.ApplicationId, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(Constants.Parse.APIKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"uniqueKey\": \"\(information.uniqueKey ?? "")\", \"firstName\": \"\(information.firstName)\", \"lastName\": \"\(information.lastName)\",\"mapString\": \"\(information.mapString ?? "")\", \"mediaURL\": \"\(information.mediaURL ?? "")\",\"latitude\": \(information.latitude ?? 0.0), \"longitude\": \(information.longitude ?? 0.0)}".data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(false, error)
                return
            }
            var response: PostLocationResponse!
            let decoder = JSONDecoder()
            do {
                print(String(data: data, encoding: .utf8)!)
                response = try decoder.decode(PostLocationResponse.self, from: data)
                if let response = response, response.createdAt != nil {
                    completion(true, nil)
                }
            } catch {
                 completion(false, error)
            }
        }
        task.resume()
    }
    
    class func updateStudentLocation(information: StudentInformation, completion: @escaping (Bool, Error?) -> Void ) {
        
        var request = URLRequest(url: URL(string: "https://parse.udacity.com/parse/classes/StudentLocation/\(information.objectId ?? "")")!)
        request.httpMethod = "PUT"
        request.addValue(Constants.Parse.ApplicationId, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(Constants.Parse.APIKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"uniqueKey\": \"\(information.uniqueKey ?? "")\", \"firstName\": \"\(information.firstName)\", \"lastName\": \"\(information.lastName)\",\"mapString\": \"\(information.mapString ?? "")\", \"mediaURL\": \"\(information.mediaURL ?? "")\",\"latitude\": \(information.latitude ?? 0.0), \"longitude\": \(information.longitude ?? 0.0)}".data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(false, error)
                return
            }
            var response: UpdateLocationResponse!
            let decoder = JSONDecoder()
            do {
                print(String(data: data, encoding: .utf8)!)
                response = try decoder.decode(UpdateLocationResponse.self, from: data)
                if let response = response, response.updatedAt != nil {
                    completion(true, nil)
                }
            } catch {
                completion(false, error)
            }
        }
        task.resume()
    }
    
}
