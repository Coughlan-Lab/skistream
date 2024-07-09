//
//  Configuration.swift
//  RTCnew
//
//  Created by Stefano on 04/07/24.
//

import Foundation
import ARKit

class Configuration: Codable {
    var sensors: [DataTypes: DataType]
    var ARSession: Bool
    var ARSession_conf: ARConfig
    var ARSession_settings: [DataTypes: DataType]
    var CameraStream: Bool
    
    init(sensors: [DataTypes : DataType], ARSession: Bool, ARSession_conf: ARConfig, ARSession_settings: [DataTypes : DataType], CameraStream: Bool) {
        self.sensors = sensors
        self.ARSession = ARSession
        self.ARSession_conf = ARSession_conf
        self.ARSession_settings = ARSession_settings
        self.CameraStream = CameraStream
    }
    
    static var defaultConf: Configuration = Configuration(
        sensors: [
            DataTypes.Accelerometer : DataType(label: DataTypes.Accelerometer.rawValue, basePriority: 50, priorityIncrement: 50, queuePolicy: .lastOnly, enabled: true, updateInterval: 1.0, others: nil),
            DataTypes.Gyroscope: DataType(label: DataTypes.Gyroscope.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: 1.0, others: nil),
            DataTypes.Magnetometer: DataType(label: DataTypes.Magnetometer.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: 1.0, others: nil),
            DataTypes.DeviceMotion: DataType(label: DataTypes.DeviceMotion.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: 1.0, others: nil),
            DataTypes.AbsoluteAltitude: DataType(label: DataTypes.AbsoluteAltitude.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: nil, others: nil),
            DataTypes.RelativeAltitude: DataType(label: DataTypes.RelativeAltitude.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: nil, others: nil),
            DataTypes.BatteryLevel: DataType(label: DataTypes.BatteryLevel.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: 1.0, others: nil),
            DataTypes.Heading: DataType(label: DataTypes.Heading.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: nil, others: nil),
            DataTypes.Location: DataType(label: DataTypes.Location.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: nil, others: nil)
        ],
        ARSession: true,
        ARSession_conf: .ARWorldTrackingConfiguration,
        ARSession_settings: [
            DataTypes.CameraPose: DataType(label: DataTypes.CameraPose.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: nil, others: nil),
            DataTypes.WorldMappingStatus: DataType(label: DataTypes.WorldMappingStatus.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: nil, others: nil),
            DataTypes.TrackingState: DataType(label: DataTypes.TrackingState.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: nil, others: nil),
            DataTypes.RGBFrame: DataType(label: DataTypes.RGBFrame.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: nil, others: [
                OtherKeys.FrameColor.rawValue: FrameColor.GrayScale.rawValue,
                OtherKeys.FrameResolution.rawValue: [1920, 1080]
            ]),
            DataTypes.PlaneDetection: DataType(label: DataTypes.PlaneDetection.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: nil, others: [
                OtherKeys.PlaneDirection.rawValue: [ARWorldTrackingConfiguration.PlaneDetection.horizontal.rawValue, ARWorldTrackingConfiguration.PlaneDetection.vertical.rawValue].map{e in Int(e)},
                OtherKeys.CallbackEvent.rawValue: [CallbackEvent.didAdd.rawValue, CallbackEvent.didUpdate.rawValue, CallbackEvent.didRemove.rawValue]
            ]),
            DataTypes.DepthMap: DataType(label: DataTypes.DepthMap.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: nil, others: nil),
            DataTypes.FeaturesPoints: DataType(label: DataTypes.FeaturesPoints.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: nil, others: nil),
            DataTypes.ObjectDetection: DataType(label: DataTypes.ObjectDetection.rawValue, basePriority: 100, priorityIncrement: 50, queuePolicy: .enqueue, enabled: true, updateInterval: nil, others: nil)
        ],
        CameraStream: false
    )
    
    func printC(){
        print("Configuration")
        print("CameraStream: \(CameraStream)")
        print("ARSession: \(ARSession)")
        if (ARSession) {
            print("conf: \(ARSession_conf)")
            printConf(conf: ARSession_settings)
        }
        print("sensors:")
        printConf(conf: sensors)
        
    }
    
    func deepCopy() -> Configuration {
        var copy = Configuration(
            sensors: [:],
            ARSession: self.ARSession,
            ARSession_conf: self.ARSession_conf,
            ARSession_settings: [:],
            CameraStream: self.CameraStream
        )
        for (k, v) in self.sensors {
            copy.sensors[k] = DataType(
                label: v.label,
                basePriority: v.basePriority,
                priorityIncrement: v.priorityIncrement,
                queuePolicy: v.queuePolicy,
                enabled: v.enabled,
                updateInterval: v.updateInterval,
                others: v.others
            )
        }
        for (k, v) in self.ARSession_settings {
            copy.ARSession_settings[k] = DataType(
                label: v.label,
                basePriority: v.basePriority,
                priorityIncrement: v.priorityIncrement,
                queuePolicy: v.queuePolicy,
                enabled: v.enabled,
                updateInterval: v.updateInterval,
                others: v.others
            )
        }
        return copy
    }
}
