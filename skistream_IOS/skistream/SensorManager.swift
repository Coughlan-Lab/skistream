//
//  CM_Motion.swift
//  RTCnew
//
//  Created by Stefano on 20/06/24.
//

import Foundation
import CoreMotion
import CoreLocation
import UIKit

class SensorManager: NSObject {
    static let shared = SensorManager()
    
    let motionManager = CMMotionManager()
    let altitudeManager = CMAltimeter()
    let locationManager = CLLocationManager()
    
    var isWorking: Bool = false
    //var BatteryLevelUpdateInterval : Double = 1.0 //seconds
    
    let batteryQueue = DispatchQueue(label: "BatteryLevel.Queue")
    
    var gyroHandler: CMGyroHandler?
    var magnetometerHandler: CMMagnetometerHandler?
    var accelerometerHandler: CMAccelerometerHandler?
    var deviceMotionHandler: CMDeviceMotionHandler?
    var absoluteAltitudeHandler: CMAbsoluteAltitudeHandler?
    var relativeAltitudeHandler: CMAltitudeHandler?
    
    
    override init() {
        super.init()
        //motionManager.accelerometerUpdateInterval = 1
        //motionManager.gyroUpdateInterval = 1
        //motionManager.magnetometerUpdateInterval = 1
        //motionManager.deviceMotionUpdateInterval = 1
        locationManager.delegate = self
    }
    
    func UpdateInterval(newValue: Double) {
        let wasWorking = self.isWorking
        if self.isWorking {self.stopAll()}
        motionManager.accelerometerUpdateInterval = newValue
        if wasWorking && !self.isWorking {self.startAll()}
    }
    
    func stopAll(){
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        if CMAltimeter.isAbsoluteAltitudeAvailable() {
            altitudeManager.stopAbsoluteAltitudeUpdates()
        }
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altitudeManager.stopRelativeAltitudeUpdates()
        }
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
        self.isWorking = false
    }
    
    func startAll() {
        setHandlers()
        self.isWorking = true
        if let conf = Model.shared.t_currentConf?.sensors {
            print("sensorManager startAll")
            //printConf(conf: conf)
            if conf[DataTypes.Gyroscope]!.enabled && motionManager.isGyroAvailable {
                motionManager.gyroUpdateInterval = conf[DataTypes.Gyroscope]!.updateInterval ?? 1
                motionManager.startGyroUpdates(to: OperationQueue(), withHandler: self.gyroHandler!)
            }
            
            if conf[DataTypes.Magnetometer]!.enabled && motionManager.isMagnetometerAvailable {
                motionManager.magnetometerUpdateInterval = conf[DataTypes.Magnetometer]!.updateInterval ?? 1
                motionManager.startMagnetometerUpdates(to: OperationQueue(), withHandler: self.magnetometerHandler!)
            }
            
            if conf[DataTypes.Accelerometer]!.enabled && motionManager.isAccelerometerAvailable {
                motionManager.accelerometerUpdateInterval = conf[DataTypes.Accelerometer]!.updateInterval ?? 1
                motionManager.startAccelerometerUpdates(to: OperationQueue(), withHandler: self.accelerometerHandler!)
            }
            
            if conf[DataTypes.DeviceMotion]!.enabled && motionManager.isDeviceMotionAvailable {
                motionManager.deviceMotionUpdateInterval = conf[DataTypes.DeviceMotion]!.updateInterval ?? 1
                motionManager.startDeviceMotionUpdates(to: OperationQueue(), withHandler: self.deviceMotionHandler!)
            }
            
            if conf[DataTypes.AbsoluteAltitude]!.enabled && CMAltimeter.isAbsoluteAltitudeAvailable() {altitudeManager.startAbsoluteAltitudeUpdates(to: OperationQueue(), withHandler: self.absoluteAltitudeHandler!)}
            
            if conf[DataTypes.RelativeAltitude]!.enabled && CMAltimeter.isRelativeAltitudeAvailable() {altitudeManager.startRelativeAltitudeUpdates(to: OperationQueue(), withHandler: self.relativeAltitudeHandler!)}
            
            if conf[DataTypes.BatteryLevel]!.enabled {
                UIDevice.current.isBatteryMonitoringEnabled = true
                //self.BatteryLevelUpdateInterval = conf[DataTypes.BatteryLevel]!.updateInterval ?? 1
                batteryQueue.async {
                    while self.isWorking {
                        DataFilter.shared.pushData(packet: DataPacket(
                            dataType: conf[.BatteryLevel]!,
                            data: UIDevice.current.batteryLevel.description.data(using: .utf8)!,
                            all_timestamp: Date().timeIntervalSince1970
                        ))
                        usleep(useconds_t((conf[.BatteryLevel]!.updateInterval ?? 1) * 1000000))
                    }
                }
            }
            
            if conf[DataTypes.Heading]!.enabled && CLLocationManager.headingAvailable() {locationManager.startUpdatingHeading()}
            
            if conf[DataTypes.Location]!.enabled && CLLocationManager.locationServicesEnabled() {locationManager.startUpdatingLocation()}
        }

    }
    
    func setHandlers(){
        if let conf = Model.shared.t_currentConf?.sensors {
            gyroHandler = {data, error in
                if let e = error {
                    print("error in gyroHandler: \(e)")
                } else if let d = data {
                    
                    let p = "{\"x\": \(d.rotationRate.x),\"y\": \(d.rotationRate.y), \"z\": \(d.rotationRate.z)}"
                    
                    DataFilter.shared.pushData(packet: DataPacket(
                        dataType: conf[.Gyroscope]!,
                        data: p.data(using: .utf8)!,
                        all_timestamp: Date().timeIntervalSince1970
                    ))
                }
            }
            
            magnetometerHandler = {data, error in
                if let e = error {
                    print("error in magnetometerHandler: \(e)")
                } else if let d = data {
                    
                    let p = "{\"x\": \(d.magneticField.x),\"y\": \(d.magneticField.y), \"z\": \(d.magneticField.z)}"
                    
                    DataFilter.shared.pushData(packet: DataPacket(
                        dataType: conf[.Magnetometer]!,
                        data: p.data(using: .utf8)!,
                        all_timestamp: Date().timeIntervalSince1970
                    ))
                }
            }
            
            accelerometerHandler = {data, error in
                if let e = error {
                    print("error in accelerometerHandler: \(e)")
                } else if let d = data {
                    
                    let p = "{\"x\": \(d.acceleration.x),\"y\": \(d.acceleration.y), \"z\": \(d.acceleration.z)}"
                    
                    DataFilter.shared.pushData(packet: DataPacket(
                        dataType: conf[.Accelerometer]!,
                        data: p.data(using: .utf8)!,
                        all_timestamp: Date().timeIntervalSince1970
                    ))
                }
            }
            
            deviceMotionHandler = {data, error in
                if let e = error {
                    print("error in DeviceMotion: \(e)")
                } else if let d = data {
                    let p = "{\"attitude.roll\": \(d.attitude.roll), \"attitude.pitch\": \(d.attitude.pitch), \"attitude.yaw\": \(d.attitude.yaw)}"
                    DataFilter.shared.pushData(packet: DataPacket(
                        dataType: conf[.DeviceMotion]!,
                        data: p.data(using: .utf8)!,
                        all_timestamp: Date().timeIntervalSince1970
                    ))
                }
            }
            
            absoluteAltitudeHandler = {data,error in
                if let e = error {
                    print("error in absoluteAltitudeHandler: \(e)")
                } else if let d = data {
                    
                    let p = "{\"accuracy\": \(d.accuracy),\"altitude\": \(d.altitude), \"precision\": \(d.precision)}"
                    
                    DataFilter.shared.pushData(packet: DataPacket(
                        dataType: conf[.AbsoluteAltitude]!,
                        data: p.data(using: .utf8)!,
                        all_timestamp: Date().timeIntervalSince1970
                    ))
                }
            }
            
            relativeAltitudeHandler = {data,error in
                if let e = error {
                    print("error in relativeAltitudeHandler: \(e)")
                } else if let d = data {
                    let p = "{\"relativeAltitude\": \(d.relativeAltitude),\"pressure\": \(d.pressure)}"
                    
                    DataFilter.shared.pushData(packet: DataPacket(
                        dataType: conf[.RelativeAltitude]!,
                        data: p.data(using: .utf8)!,
                        all_timestamp: Date().timeIntervalSince1970
                    ))
                }
            }
            
        }
        

        
    }
}

extension SensorManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if let conf = Model.shared.t_currentConf?.sensors {
            let p = "{\"magneticHeading\": \(newHeading.magneticHeading), \"trueHeading\": \(newHeading.trueHeading), \"headingAccuracy\": \(newHeading.headingAccuracy), \"x\": \(newHeading.x), \"y\": \(newHeading.y), \"z\": \(newHeading.z), \"timestamp\": \(newHeading.timestamp.timeIntervalSince1970 + Model.shared.clockSynch.toAdd_toTheLocalClock)}"
            
            DataFilter.shared.pushData(packet: DataPacket(
                dataType: conf[.Heading]!,
                data: p.data(using: .utf8)!,
                all_timestamp: Date().timeIntervalSince1970
            ))
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let conf = Model.shared.t_currentConf?.sensors {
            let loc = locations.last!
            let p = "{\"latitude\": \(loc.coordinate.latitude), \"longitude\": \(loc.coordinate.longitude), \"course\": \(loc.course), \"courseAccuracy\": \(loc.courseAccuracy), \"speed\": \(loc.speed), \"speedAccuracy\": \(loc.speedAccuracy), \"timestamp\": \(loc.timestamp.timeIntervalSince1970 + Model.shared.clockSynch.toAdd_toTheLocalClock)}"
            
            DataFilter.shared.pushData(packet: DataPacket(
                dataType: conf[.Location]!,
                data: p.data(using: .utf8)!,
                all_timestamp: Date().timeIntervalSince1970
            ))
        }
        
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("locationManagerDidChangeAuthorization")
        if manager.authorizationStatus == .notDetermined {
            SensorManager.shared.locationManager.requestWhenInUseAuthorization()
        }
    }
}
