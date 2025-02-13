//
//  DataBuffer.swift
//  RTCnew
//
//  Created by Stefano on 18/06/24.
//

import Foundation

class DataBuffer: ObservableObject {
    
    static let shared = DataBuffer()
    
    var lock = NSLock()
    var buffer: [DataPacket] = []
    //var maxSize: Int = Int(10 * 1000000) // bytes to MB
    //var maxSize: Int = 16 * 1000 // 16KB, max datachannel x msg
    var maxSize: Double = 500 * 1000 // x * 1000 = x KB
    //var maxSize: Int = 	65507 // max MTU using udp without headers
    
    @Published var fill: Double = 0.0
    
    func push(packet: DataPacket) -> Bool {
        DispatchQueue.global().sync{ self.lock.lock() }
        let isFirst = buffer.isEmpty
        buffer.append(packet)
        DataTransmitter.shared.semaphore_dataBuffer.signal()
        DispatchQueue.global().sync{ self.lock.unlock() }
        return isFirst
    }

    func replace(packet: DataPacket) {
        DispatchQueue.global().sync{ self.lock.lock() }
        if let i = buffer.firstIndex(where: {$0.dataType.label == packet.dataType.label}) {
            buffer[i].replaceData(packet: packet)
        }
        DispatchQueue.global().sync{ self.lock.unlock() }
    }
    
    func canContain(packet: DataPacket) -> Bool {
        DispatchQueue.global().sync{ self.lock.lock() }
        let bufferFill = buffer.reduce(0, { partialResult, dataPacket in partialResult + dataPacket.getSize()})
        let packetSize = packet.getSize()
        //let res = packetSize <= maxSize - bufferFill
        DispatchQueue.main.async {self.fill = min(( bufferFill + packetSize ) / self.maxSize, 1.0) }
        DispatchQueue.global().sync{self.lock.unlock()}
        return self.fill < 1
    }
    
    func isEmpty() -> Bool {
        DispatchQueue.global().sync{ self.lock.lock() }
        let empty = buffer.isEmpty
        DispatchQueue.global().sync{self.lock.unlock()}
        return empty
    }
    
    /*func isFull() -> Bool {
        return buffer.count == maxSize
    }*/
    
    /*func getData() -> String {
        DispatchQueue.global().sync{ self.lock.lock() }
        let data = buffer.map{$0.getStringData()}.description
        self.buffer = []
        DispatchQueue.global().sync{ self.lock.unlock() }
        return data
    }*/
    
    func getData() -> Data {
        DispatchQueue.global().sync{ self.lock.lock() }
        var result = Data()
        result.append("[".data(using: .utf8)!)
        for i in self.buffer.indices {
            result.append(self.buffer[i].getBinaryData())
            if i != self.buffer.count-1 {
                result.append(",".data(using: .utf8)!)
            }
        }
        result.append("]".data(using: .utf8)!)
        self.buffer = []
        DispatchQueue.main.async {self.fill = 0.0}
        DispatchQueue.global().sync{self.lock.unlock()}
        return result
    }
    
    func containTypeData(datatype: DataType) -> Bool {
        if let p = buffer.firstIndex(where: {$0.dataType.label == datatype.label}) {return true}
        return false
    }
}
