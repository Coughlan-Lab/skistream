//
//  Network.swift
//  RTCnew
//
//  Created by Stefano on 27/04/24.
//

import Foundation
import SwiftUI

func sendOffer(endpoint: String, offer: [String: String]) async throws -> [String: Any] {
    guard let jsonData = try? JSONSerialization.data(withJSONObject: offer) else {
        print("failed to serialized offer to JSON")
        return ["code": -1, "msg": "failed to serialized offer to JSON"]
    }
    
    var req = URLRequest(url: URL(string: endpoint)!)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-type")
    req.httpBody = jsonData
    
    
    let (data, response) = try await URLSession.shared.data(for: req)
    
    guard let httpRes = response as? HTTPURLResponse else {
        print("error converting response as? HTTPURLResponse")
        return ["code": -1, "msg": "error converting response as? HTTPURLResponse"]
    }
    
    if httpRes.statusCode != 200 {
        return ["code": httpRes.statusCode]
    }
    
    //print("before json answer")
    
    do {
        //let data = Data(s.utf8)
        let response = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        let sdp = response["sdp"] as! String
        return ["code": 1, "sdp": sdp]
    } catch {
        print("error -> \(error.localizedDescription)")
        return ["code": -1, "msg": "error -> \(error.localizedDescription)"]
    }
}

@MainActor
func synchWithServer(endpoint: String, maxIteration: Int, maxError: Double) async throws -> [String: Any] {
    
    var minError: Double = Double.infinity
    var RTT_minError: Double = 0.0
    
    var req = URLRequest(url: URL(string: endpoint)!)
    req.httpMethod = "GET"
    
    for i in 0...maxIteration {
        //TimeInterval=Double
        let start: TimeInterval = Date().timeIntervalSince1970
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        let RTT = Date().timeIntervalSince1970 - start
        
        /*guard let httpRes = response as? HTTPURLResponse else {
            //return ["code": -1, "msg": "error converting response as? HTTPURLResponse"]
        }
        
        if httpRes.statusCode != 200 {
            //return ["code": httpRes.statusCode]
        }*/
        
        do {
            let response = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            let server_time = response["server_time"] as! TimeInterval
            let error = abs(start+(RTT/2) - server_time)
            if error <= maxError {
                Model.shared.clockSynch.error = error
                Model.shared.clockSynch.toAdd_toTheLocalClock = RTT/2
                
                //ClockSynch.shared.error = error
                //ClockSynch.shared.toAdd_toTheLocalClock = RTT/2
                Model.shared.progressSynch = 1.0
                return ["code": 1, "msg": "ok synchronization"]
            }
            
            if error <= minError {
                minError = error
                RTT_minError = RTT/2
            }
            
            //print("synch: myTime \(start) servertime \(server_time), RTT \(RTT), error \( start+(RTT/2) - server_time )")
        }/* catch {
            print("error -> \(error.localizedDescription)")
            //return ["code": -1, "msg": "error -> \(error.localizedDescription)"]
        }*/
        sleep(1)
        Model.shared.progressSynch = Double(i)/Double(maxIteration)
        //print(Model.shared.progressSynch)
    }
    
    //ClockSynch.shared.error = minError
    //ClockSynch.shared.toAdd_toTheLocalClock = RTT_minError
    Model.shared.clockSynch.error = minError
    Model.shared.clockSynch.toAdd_toTheLocalClock = RTT_minError
    
    return ["code": -1, "msg": "synchronization impossible"]
    
    
}


