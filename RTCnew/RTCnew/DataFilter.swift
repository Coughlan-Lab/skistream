//
//  DataFilter.swift
//  RTCnew
//
//  Created by Stefano on 18/06/24.
//

import Foundation

class DataFilter {
    
    static let shared = DataFilter()
    private var olderTimestamp: TimeInterval = 0.0
    
    var transmissionDelay: Double = 0.0 // in ms
    
    var delayCounter: Int = 0
    var delayUpdate: Int = 10
    
    
    func updateDelay(sendingTime: TimeInterval) {
        delayCounter += 1
        //print("update delay: \(transmissionDelay)")
        NotificationCenter.default.post(
            name: .delay,
            object: self.transmissionDelay
        )
        /*if delayCounter % delayUpdate == 0 {
            
        }*/
        //print("old delay: \(transmissionDelay)")
        transmissionDelay = max(0, (sendingTime - olderTimestamp) * 1000)
        //print("update delay: \(transmissionDelay)")
    }
    
    func pushData(packet: DataPacket) -> Bool {
        
        if packet.dataType.queuePolicy == .lastOnly && DataBuffer.shared.containTypeData(datatype: packet.dataType) {
            DataBuffer.shared.replace(packet: packet)
            return true
        }
        if isPushable(packet: packet) {
            let isFirst = DataBuffer.shared.push(packet: packet)
            if (isFirst) {olderTimestamp = packet.dataTimestamp}
            packet.dataType.refreshPriority()
            return true
        }
        packet.dataType.incrementPriority()
        return false
    }

    func isPushable(packet: DataPacket) -> Bool {
        if (DataBuffer.shared.canContain(packet: packet) == false) {return false}
        if transmissionDelay > Double(packet.dataType.currentPriority) {return false}
        return true
    }
}
