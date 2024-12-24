//
//  DataPacket.swift
//  RTCnew
//
//  Created by Stefano on 18/06/24.
//

import Foundation

class DataPacket {
    var dataType: DataType
    var data: Data
    var dataTypeTimestamp: TimeInterval
    var dataTimestamp: TimeInterval

    init(dataType: DataType, data: Data, all_timestamp: TimeInterval) {
        self.dataType = dataType
        self.data = data
        self.dataTypeTimestamp = all_timestamp + Model.shared.clockSynch.toAdd_toTheLocalClock
        self.dataTimestamp = all_timestamp + Model.shared.clockSynch.toAdd_toTheLocalClock
    }

    func replaceData(packet: DataPacket) {
        self.dataType = packet.dataType
        self.data = packet.data
        self.dataTimestamp = packet.dataTimestamp + Model.shared.clockSynch.toAdd_toTheLocalClock
    }
    
    func getSize() -> Double {
        return Double(
            dataType.label.data(using: .utf8)!.count +
            data.count +
            dataTimestamp.description.data(using: .utf8)!.count +
            dataTypeTimestamp.description.data(using: .utf8)!.count
        )
    }
    
    func getStringData() -> String {
        return [
            "dataType": dataType.label,
            "data": data.description,
            "dataTimestamp": dataTimestamp.description,
            "dataTypeTimestamp": dataTypeTimestamp.description
        ].description
    }
    
    func getBinaryData() -> Data {
        var result = Data()
        result.append("{\"dataType\": \"\(self.dataType.label)\",".data(using: .utf8)!)
        result.append("\"dataTimestamp\": \(dataTimestamp.description),".data(using: .utf8)!)
        result.append("\"dataTypeTimestamp\": \(dataTypeTimestamp.description),".data(using: .utf8)!)
        result.append("\"data\": ".data(using: .utf8)!)
        result.append(self.data)
        result.append("}".data(using: .utf8)!)
        return result
    }
}
