//
//  DataType.swift
//  RTCnew
//
//  Created by Stefano on 18/06/24.
//

import Foundation
import SwiftUI

enum QueuePolicy: String, CaseIterable, Equatable, Codable {
    case lastOnly
    case enqueue
}

enum Cat: String{
    case Sensors
    case ARSession
    case CameraStream
}

/*let Categories: [Cat : [DataTypes]] = [
    .Sensors :[DataTypes.Accelerometer, DataTypes.Gyroscope, DataTypes.Magnetometer, DataTypes.DeviceMotion, DataTypes.AbsoluteAltitude, DataTypes.RelativeAltitude, DataTypes.BatteryLevel, DataTypes.Heading, DataTypes.Location],
    .ARSession : [DataTypes.Accelerometer],
    .CameraStream : [DataTypes.Accelerometer]
]*/

enum DataTypes: String, Hashable, Codable {
    //sensors
    case Accelerometer
    case Gyroscope
    case Magnetometer
    case DeviceMotion
    case AbsoluteAltitude
    case RelativeAltitude
    case BatteryLevel
    case Heading
    case Location
    //AR
    case CameraPose
    case WorldMappingStatus
    case TrackingState
    case RGBFrame
    case PlaneDetection
    case DepthMap
    case FeaturesPoints
    case ObjectDetection
}

class DataType: ObservableObject, Codable {
    
    @Published var basePriority: Int //ms
    @Published var priorityIncrement: Int //ms
    @Published var currentPriority: Int // ms, Represents the maximum communication delay for which this data type is enqueued. The higher the value, the more times this data will be accommodated, even with significant delay.
    @Published var queuePolicy: QueuePolicy
    var label: String
    @Published var enabled: Bool
    @Published var updateInterval: Double?
    @Published var others: [String:Any]?

    init(label: String, basePriority: Int, priorityIncrement: Int, queuePolicy: QueuePolicy, enabled: Bool, updateInterval: Double?, others: [String:Any]?) {
        self.label = label
        self.basePriority = basePriority
        self.priorityIncrement = priorityIncrement
        self.queuePolicy = queuePolicy
        self.currentPriority = basePriority
        self.enabled = enabled
        self.updateInterval = updateInterval
        self.others = others
    }

    func incrementPriority() {
        currentPriority += priorityIncrement
    }

    func refreshPriority() {
        currentPriority = basePriority
    }
    
    func printC() {
        //print("\(self.label), \(self.basePriority), \(self.currentPriority), \(self.queuePolicy) \(self.enabled)")
        print("label: \(self.label), basePriority: \(self.basePriority), currentPriority: \(self.currentPriority), priorityIncrement: \(self.priorityIncrement), enabled: \(self.enabled), queuePolicy: \(self.queuePolicy.rawValue)")
    }
    
    func toStr() -> String {
        return "label: \(self.label), basePriority: \(self.basePriority), currentPriority: \(self.currentPriority), priorityIncrement: \(self.priorityIncrement), enabled: \(self.enabled), queuePolicy: \(self.queuePolicy.rawValue), updateInterval: \(self.updateInterval), others: \(self.others)"
    }
    
    enum CodingKeys: String, CodingKey {
            case basePriority
            case priorityIncrement
            case queuePolicy
            case enabled
            case label
            case updateInterval
            case others
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.basePriority = try container.decode(Int.self, forKey: .basePriority)
        self.priorityIncrement = try container.decode(Int.self, forKey: .priorityIncrement)
        self.currentPriority = try container.decode(Int.self, forKey: .basePriority)
        self.queuePolicy = try container.decode(QueuePolicy.self, forKey: .queuePolicy)
        self.enabled = try container.decode(Bool.self, forKey: .enabled)
        self.label = try container.decode(String.self, forKey: .label)
        //self.updateInterval = try container.decode(Double?.self, forKey: .updateInterval)
        self.updateInterval = try container.decodeIfPresent(Double.self, forKey: .updateInterval)
        if let flexibleData = try container.decodeIfPresent(FlexibleCodingData.self, forKey: .others) {
            others = flexibleData.data
        } else {
            others = nil
        }
                
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(basePriority, forKey: .basePriority)
        try container.encode(priorityIncrement, forKey: .priorityIncrement)
        //try container.encode(currentPriority, forKey: .currentPriority)
        try container.encode(queuePolicy, forKey: .queuePolicy)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(label, forKey: .label)
        //try container.encode(updateInterval, forKey: .updateInterval)
        try container.encodeIfPresent(updateInterval, forKey: .updateInterval)
        if let others = others {
            try container.encode(FlexibleCodingData(others), forKey: .others)
        }
        
    }
}


struct FlexibleCodingData: Codable {
    var data: [String: Any]
    
    init(_ data: [String: Any]) {
        self.data = data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.data = try container.decode([String: AnyCodable].self)
            .mapValues { $0.value }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data.mapValues { AnyCodable($0) })
    }
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}
