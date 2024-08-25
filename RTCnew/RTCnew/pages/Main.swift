//
//  Main.swift
//  RTCnew
//
//  Created by Stefano on 25/06/24.
//

import SwiftUI
import WebRTC
import CoreMotion
import ARKit

struct Main: View {
    
    @StateObject var model = Model.shared
    @State private var arView_WorldTracking: ARView_WorldTracking?
    
    @Binding var connectionState: RTCIceConnectionState
    @StateObject var transmitter: DataTransmitter = DataTransmitter.shared
    
    @State var isRunning: Bool = false
    
    @State private var alert_unavailableSensors: Bool = false
    @State private var unavailableSensors: [String] = []
    
    @Binding var delay: Double
    @ObservedObject var sockerpeer: SocketPeer = SocketPeer.shared
    
    @StateObject private var dataBuffer = DataBuffer.shared
    
    func checkSensorAvailability() {
        guard let conf = Model.shared.t_currentConf else {
            print("Error: No configuration available")
            return
        }
        
        unavailableSensors = []
        
        if conf.sensors[DataTypes.Gyroscope]!.enabled && !SensorManager.shared.motionManager.isGyroAvailable {
            unavailableSensors.append("Gyroscope")
        }
        if conf.sensors[DataTypes.Magnetometer]!.enabled && !SensorManager.shared.motionManager.isMagnetometerAvailable {
            unavailableSensors.append("Magnetometer")
        }
        if conf.sensors[DataTypes.Accelerometer]!.enabled && !SensorManager.shared.motionManager.isAccelerometerAvailable {
            unavailableSensors.append("Accelerometer")
        }
        if conf.sensors[DataTypes.DeviceMotion]!.enabled && !SensorManager.shared.motionManager.isDeviceMotionAvailable {
            unavailableSensors.append("DeviceMotion")
        }
        if conf.sensors[DataTypes.AbsoluteAltitude]!.enabled && !CMAltimeter.isAbsoluteAltitudeAvailable() {
            unavailableSensors.append("AbsoluteAltitude")
        }
        if conf.sensors[DataTypes.RelativeAltitude]!.enabled && !CMAltimeter.isRelativeAltitudeAvailable() {
            unavailableSensors.append("RelativeAltitude")
        }
        if conf.sensors[DataTypes.Heading]!.enabled && !CLLocationManager.headingAvailable() {
            unavailableSensors.append("Heading")
        }
        if conf.sensors[DataTypes.Location]!.enabled && !CLLocationManager.locationServicesEnabled() {
            unavailableSensors.append("Location")
        }
        
        if conf.ARSession && conf.ARSession_conf == .ARWorldTrackingConfiguration && !(ARWorldTrackingConfiguration.isSupported) {
            unavailableSensors.append("ARWorldTrackingConfiguration")
        }
        
        if conf.ARSession_settings[.PlaneDetection]!.enabled && !(ARWorldTrackingConfiguration().planeDetection.contains([.horizontal, .vertical])) {
            unavailableSensors.append("Plane Detection (Horizontal and Vertical)")
        }
        
        if (conf.ARSession_settings[.ObjectDetection]!.enabled && 
            !(ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification))) {
            unavailableSensors.append("Object classification (meshWithClassification)")
        }
        
        
        
        if (conf.ARSession_settings[.DepthMap]!.enabled && !ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)){
            unavailableSensors.append("DepthMap")
        }
        
        
        if !unavailableSensors.isEmpty {alert_unavailableSensors = true}
    }
    
    func allOk() -> Bool {
        return SocketPeer.shared.isConnected && model.t_currentConf != nil
        //return model.receiverState == .serverDelay && model.t_currentConf != nil && self.connectionState == .connected && transmitter.channel != nil
    }
    
    func startAll(){
        //Model.shared.t_currentConf?.printC()
        
        DataTransmitter.shared.stop = false
        DataTransmitter.shared.start()
        SensorManager.shared.startAll()
        
        if Model.shared.t_currentConf!.ARSession {
            switch Model.shared.t_currentConf!.ARSession_conf {
            case .ARWorldTrackingConfiguration:
                arView_WorldTracking = ARView_WorldTracking()
            default:
                arView_WorldTracking = ARView_WorldTracking()
            }

        }
                
        isRunning = true
    }
    
    func stopAll(){
        SensorManager.shared.stopAll()
        DataTransmitter.shared.stop = true
        
        arView_WorldTracking?.stopSession()
        arView_WorldTracking = nil
        isRunning = false
    }
    
    
    var body: some View {
        VStack{
            //if model.receiverState != .serverDelay {Text("synch with receiver before start").foregroundStyle(.red)}
            if model.t_currentConf == nil {Text("choose a configuration in SessionSettings tab before start").foregroundStyle(.red)}
            //if transmitter.channel == nil {Text("no available channel, connect in connectionSetting tab or close and reopen the app if the problem persist").foregroundStyle(.red)}
            if isRunning{Text("delay (ms): \(self.delay)")}
            if !sockerpeer.isConnected {Text("no available socket connection, connect in connectionSetting tab").foregroundStyle(.red)}
            HStack {
                Circle()
                    .fill(isRunning ? Color.green : Color.red)
                    .frame(width: 20, height: 20)
                
                Text(isRunning ? "Running" : "Stopped")
                    .padding(.leading, 10)
            }
            
            Button("startSession") {
                startAll()
            }.buttonStyle(.bordered).disabled(!allOk())
            Button("stopSession") {
                stopAll()
            }.buttonStyle(.bordered).disabled(!allOk())
            if arView_WorldTracking != nil {arView_WorldTracking!}
            Spacer()
            ProgressView(value: dataBuffer.fill) {
                Text("Buffer fill")
            }
        }
        .onChange(of: connectionState) { newValue in
            if newValue != .connected && isRunning {
                stopAll()
            }
        }
        .onChange(of: sockerpeer.isConnected) { newValue in
            if !newValue && isRunning {
                stopAll()
            }
        }
        .onAppear {
            checkSensorAvailability()
        }
        .alert("Unavailable Sensors", isPresented: $alert_unavailableSensors) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Warning: The following sensors are enabled in the configuration but not available on this device: \(unavailableSensors.joined(separator: "\n"))")
        }
        
        
    }
}
