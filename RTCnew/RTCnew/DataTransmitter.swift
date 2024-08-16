//
//  DataTransmitter.swift
//  RTCnew
//
//  Created by Stefano on 19/06/24.
//

import Foundation
import WebRTC

class DataTransmitter: ObservableObject {
    static let shared = DataTransmitter()
    
    let semaphore_webRTCdataBuffer = DispatchSemaphore(value: 0)
    let semaphore_dataBuffer = DispatchSemaphore(value: 0)
    let semaphore_receiveFromWebRTC = DispatchSemaphore(value: 0)
    
    let serialQueue = DispatchQueue(label: "DataTransmitter.Queue", qos: .userInitiated)
    let synchQueue = DispatchQueue(label: "DataTransmitter.synchQueue")
    
    var stop: Bool = false
    
    var dataBuffer: DataBuffer = DataBuffer.shared
    @Published var channel: RTCDataChannel?
    
    func setDataChannel(channel: RTCDataChannel?){DispatchQueue.main.async{self.channel = channel}}
    
    func synchWithServer(maxIteration: Int, maxError: Double, sleepTime: UInt32) {
        Model.shared.receiverState = .serverTime
        synchQueue.async {
            //Model.shared.clockSynch.error = 0.0
            Model.shared.clockSynch.toAdd_toTheLocalClock = 0.0
            
            //var error_list: [Double] = []
            //var RTT_list: [Double] = []
            var adj_list: [Double] = []
            
            sleep(sleepTime)
            
            for i in 0...maxIteration {
                let b = RTCDataBuffer(data: "TR".data(using: .utf8)!, isBinary: false)
                let start = Date().timeIntervalSince1970
                self.channel!.sendData(b)
                self.semaphore_receiveFromWebRTC.wait()
                let end = Model.shared.clockSynch.tmpMyEndTime
                
                let RTT = end  - start
                let newTime = Model.shared.clockSynch.tmpServerTime + (RTT/2)
                
                
                
                let error = abs(start + (RTT/2) + (newTime - end) - Model.shared.clockSynch.tmpServerTime)
                /*if error <= maxError {
                    DispatchQueue.main.async{
                        Model.shared.clockSynch.error = error
                        Model.shared.clockSynch.toAdd_toTheLocalClock = RTT/2
                        Model.shared.progressSynch = 1.0
                    }
                    return
                }*/
                /*if error <= minError {
                    minError = error
                    RTT_minError = RTT/2
                }*/
                
                //error_list.append(error)
                //RTT_list.append(RTT/2)
                adj_list.append(newTime - end)
                
                //Model.shared.clockSynch.error += error / Double(maxIteration)
                Model.shared.clockSynch.toAdd_toTheLocalClock += (newTime - end) / Double(maxIteration)
                
                
                sleep(sleepTime)
                
                DispatchQueue.main.sync{Model.shared.progressSynch = Double(i)/Double(maxIteration)}
                
            }
            DispatchQueue.main.sync{Model.shared.receiverState = .serverDelay}
            //print(error_list)
            //print(RTT_list)
            print(adj_list)
            //Model.shared.clockSynch.toAdd_toTheLocalClock = Double(adj_list.reduce(0, +))/Double(adj_list.count)
            //Model.shared.clockSynch.error = errorList.reduce(0.0){$0+$1} / Double(errorList.count)
            //Model.shared.clockSynch.toAdd_toTheLocalClock = RTT_List.reduce(0.0){$0+$1} / Double(RTT_List.count)
        }
        
        
        
    }
    
    func start() {
        
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            while (!self.stop) {
                autoreleasepool {
                    /*
                    WEBRTC
                    guard let channel = self.channel else { return }
                    while (channel.bufferedAmount != 0) {
                        self.semaphore_webRTCdataBuffer.wait()
                    }
                    */
                    
                    while (SocketPeer.shared.amount != 0) {
                        self.semaphore_webRTCdataBuffer.wait()
                    }
                    
                    
                    
                    while (self.dataBuffer.isEmpty()) {
                        self.semaphore_dataBuffer.wait()
                    }
                    
                    let sendingTime = Date().timeIntervalSince1970 + Model.shared.clockSynch.toAdd_toTheLocalClock
                    var packet = Data()
                    packet.append("{\"sending_timestamp\": \(sendingTime),".data(using: .utf8)!)
                    packet.append("\"packet\": ".data(using: .utf8)!)
                    packet.append(self.dataBuffer.getData())
                    packet.append("}".data(using: .utf8)!)
                    
                    DispatchQueue.main.async {
                        DataFilter.shared.updateDelay(sendingTime: sendingTime)
                    }
                    SocketPeer.shared.send(message: packet)
                    //WEBRTC channel.sendData(RTCDataBuffer(data: packet, isBinary: true))
                }
            }
        }
        
        /*serialQueue.async {
            while (!self.stop) {
                
                /*while ( peer.isEmptyWebRTCBuffer() == false ) {
                    print("semaphore_webRTCdataBuffer.wait()")
                    self.semaphore_webRTCdataBuffer.wait()
                }*/
                
                while ( self.channel!.bufferedAmount != 0 ) {
                    //print("semaphore_webRTCdataBuffer.wait()")
                    self.semaphore_webRTCdataBuffer.wait()
                }
                
                while (self.dataBuffer.isEmpty()) {
                    self.semaphore_dataBuffer.wait()
                    //print("semaphore_dataBuffer.wait()")
                }
                
                //print("send data on channel")
                
                let sendingTime = Date().timeIntervalSince1970 + Model.shared.clockSynch.toAdd_toTheLocalClock
                var packet = Data()
                packet.append("{\"sending_timestamp\": \(sendingTime),".data(using: .utf8)!)
                packet.append("\"packet\": ".data(using: .utf8)!)
                packet.append(self.dataBuffer.getData())
                packet.append("}".data(using: .utf8)!)
                
                DataFilter.shared.updateDelay(sendingTime: sendingTime)
                
                /*= [
                    "sending_timestamp": Date.now,
                    "packet": self.dataBuffer.getData()
                ]*/
                
                //peer.sendData(data: packet)
                self.channel!.sendData(RTCDataBuffer(data: packet, isBinary: true))
                
            }
        }*/
        
    }
    
    
}
