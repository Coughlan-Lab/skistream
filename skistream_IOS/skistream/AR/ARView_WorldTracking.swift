//
//  ARView_spatialTracking.swift
//  RTCnew
//
//  Created by Stefano on 03/07/24.
//

import SwiftUI
import Foundation
import ARKit

struct ARView_WorldTracking: UIViewRepresentable {
    
    typealias UIViewType = ARSCNView
    
    var sceneView = ARSCNView(frame: .zero)
    
    var configuration = ARWorldTrackingConfiguration()
    
    //var c5 = ARBodyTrackingConfiguration()
    //var c6 = ARFaceTrackingConfiguration()
    
    //var c7 = ARImageTrackingConfiguration()
    
    var delegate = ARView_WorldTracking_Delegate()
    
    func makeUIView(context: Context) -> ARSCNView {
        sceneView.delegate = delegate
        //delegate.setSceneView(sceneView)
        //Set lighting to the view
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        sceneView.scene = SCNScene()
        sceneView.session.delegate = delegate
        
        if let conf = Model.shared.t_currentConf {
            if conf.ARSession_settings[.PlaneDetection]!.enabled {
                let toAdd = (
                    conf.ARSession_settings[.PlaneDetection]!.others![OtherKeys.PlaneDirection.rawValue] as! [Int]
                )
                .map{x in UInt(x)}
                .map{y in ARWorldTrackingConfiguration.PlaneDetection(rawValue: y)}
                for e in toAdd {configuration.planeDetection.insert(e)}
            }
            if conf.ARSession_settings[.RGBFrame]!.enabled,
            let WidthHeight = conf.ARSession_settings[.RGBFrame]!.others![OtherKeys.FrameResolution.rawValue] as? [Int]
            {
                configuration.videoFormat = selectVideoFormat(for: CGSize(width: WidthHeight[0], height: WidthHeight[1]))
            }
            if (conf.ARSession_settings[.ObjectDetection]!.enabled && ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification)) {
                configuration.sceneReconstruction = .meshWithClassification
            }
            
            
            
            if (conf.ARSession_settings[.DepthMap]!.enabled && ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)){
                configuration.frameSemantics.insert(.sceneDepth)
            }
            
        }
        
        
        sceneView.session.run(configuration)
        
        return sceneView
    }

    func stopSession() {
        sceneView.session.pause()
        sceneView.removeFromSuperview()
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

class ARView_WorldTracking_Delegate: NSObject, ARSCNViewDelegate, ARSessionDelegate {
    let imgProcessingQueue = DispatchQueue(label: "imgProcessing.Queue")
    let imgProcessingQueue_lock = NSLock()
    
    override init(){
        super.init()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if let conf = Model.shared.t_currentConf {
            if (conf.ARSession_settings[.CameraPose]!.enabled) {
                DataFilter.shared.pushData(packet: DataPacket(
                    dataType: conf.ARSession_settings[.CameraPose]!,
                    data: frame.camera.transform.debugDescription.data(using: .utf8)!,
                    all_timestamp: Date().timeIntervalSince1970
                ))
            }
            if (conf.ARSession_settings[.WorldMappingStatus]!.enabled) {
                DataFilter.shared.pushData(packet: DataPacket(
                    dataType: conf.ARSession_settings[.WorldMappingStatus]!,
                    data: frame.worldMappingStatus.toString().data(using: .utf8)!,
                    all_timestamp: Date().timeIntervalSince1970
                ))
            }
            if (conf.ARSession_settings[.TrackingState]!.enabled) {
                DataFilter.shared.pushData(packet: DataPacket(
                    dataType: conf.ARSession_settings[.TrackingState]!,
                    data: frame.camera.trackingState.toString().data(using: .utf8)!,
                    all_timestamp: Date().timeIntervalSince1970
                ))
            }
            
            if (conf.ARSession_settings[.RGBFrame]!.enabled) {
                if imgProcessingQueue_lock.try() {
                    imgProcessingQueue.async{
                        if let base64Image = convertFrameToBase64(
                            pixelBuffer: frame.capturedImage,
                            grayScale: conf.ARSession_settings[.RGBFrame]!.others?[OtherKeys.FrameColor.rawValue] as! String == FrameColor.GrayScale.rawValue
                        ) {
                            DataFilter.shared.pushData(packet: DataPacket(
                                dataType: conf.ARSession_settings[.RGBFrame]!,
                                data: base64Image.data(using: .utf8)!,
                                all_timestamp: Date().timeIntervalSince1970
                            ))
                            //print(base64Images.count)
                            /*for img in base64Images {
                                DataFilter.shared.pushData(packet: DataPacket(
                                    dataType: conf.ARSession_settings[.RGBFrame]!,
                                    data: img.data(using: .utf8)!,
                                    all_timestamp: Date().timeIntervalSince1970
                                ))
                            }*/
                        }
                        self.imgProcessingQueue_lock.unlock()
                    }
                    
                }
                
            }
            
            if (conf.ARSession_settings[.DepthMap]!.enabled) {
                if let depthMap = frame.sceneDepth?.depthMap, imgProcessingQueue_lock.try() {
                    imgProcessingQueue.async{
                        if let base64Image = convertFrameToBase64(
                            pixelBuffer: depthMap,
                            grayScale: false
                        ) {
                            DataFilter.shared.pushData(packet: DataPacket(
                                dataType: conf.ARSession_settings[.DepthMap]!,
                                data: base64Image.data(using: .utf8)!,
                                all_timestamp: Date().timeIntervalSince1970
                            ))
                        }
                        self.imgProcessingQueue_lock.unlock()
                    }
                }
            }
            
            if (conf.ARSession_settings[.FeaturesPoints]!.enabled) {
                if let pointCloud = frame.rawFeaturePoints, pointCloud.identifiers.count > 0 {
                    var jsonString = (0..<pointCloud.identifiers.count).reduce(into: "{") { result, index in
                            let identifier = pointCloud.identifiers[index]
                            let point = pointCloud.points[index]
                            result += "\"\(identifier)\":[\(point.x),\(point.y),\(point.z)],"
                        }
                    jsonString += "}"
                    DataFilter.shared.pushData(packet: DataPacket(
                        dataType: conf.ARSession_settings[.FeaturesPoints]!,
                        data: jsonString.data(using: .utf8)!,
                        all_timestamp: Date().timeIntervalSince1970
                    ))
                }
            }
        }
    }
    
    /*func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if
            let planeAnchor = anchor as? ARPlaneAnchor,
            let conf = Model.shared.t_currentConf,
            let opts = conf.ARSession_settings[.PlaneDetection]?.others?[OtherKeys.CallbackEvent.rawValue] as? [CallbackEvent.RawValue],
            opts.contains(CallbackEvent.didAdd.rawValue) {
                DataFilter.shared.pushData(packet: DataPacket(
                    dataType: conf.ARSession_settings[.PlaneDetection]!,
                    data: "{\"didAdd\": \(planeAnchor.toString())}".data(using: .utf8)!,
                    all_timestamp: Date().timeIntervalSince1970
                ))
        }
        if
            let meshAnchor = anchor as? ARMeshAnchor,
            let conf = Model.shared.t_currentConf,
            let opts = conf.ARSession_settings[.ObjectDetection]?.others?[OtherKeys.CallbackEvent.rawValue] as? [CallbackEvent.RawValue],
            opts.contains(CallbackEvent.didAdd.rawValue) {
                DataFilter.shared.pushData(packet: DataPacket(
                    dataType: conf.ARSession_settings[.ObjectDetection]!,
                    data: "{\"didAdd\": \(meshAnchor.toString())}".data(using: .utf8)!,
                    all_timestamp: Date().timeIntervalSince1970
                ))
        }
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if 
            let planeAnchor = anchor as? ARPlaneAnchor,
            let conf = Model.shared.t_currentConf,
            let opts = conf.ARSession_settings[.PlaneDetection]?.others?[OtherKeys.CallbackEvent.rawValue] as? [CallbackEvent.RawValue],
            opts.contains(CallbackEvent.didUpdate.rawValue) {
                DataFilter.shared.pushData(packet: DataPacket(
                    dataType: conf.ARSession_settings[.WorldMappingStatus]!,
                    data: "{\"didUpdate\": \(planeAnchor.toString())}".data(using: .utf8)!,
                    all_timestamp: Date().timeIntervalSince1970
                ))
        }
        if
            let meshAnchor = anchor as? ARMeshAnchor,
            let conf = Model.shared.t_currentConf,
            let opts = conf.ARSession_settings[.ObjectDetection]?.others?[OtherKeys.CallbackEvent.rawValue] as? [CallbackEvent.RawValue],
            opts.contains(CallbackEvent.didAdd.rawValue) {
                DataFilter.shared.pushData(packet: DataPacket(
                    dataType: conf.ARSession_settings[.ObjectDetection]!,
                    data: "{\"didAdd\": \(meshAnchor.toString())}".data(using: .utf8)!,
                    all_timestamp: Date().timeIntervalSince1970
                ))
        }
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if
            let planeAnchor = anchor as? ARPlaneAnchor,
            let conf = Model.shared.t_currentConf,
            let opts = conf.ARSession_settings[.PlaneDetection]?.others?[OtherKeys.CallbackEvent.rawValue] as? [CallbackEvent.RawValue],
            opts.contains(CallbackEvent.didRemove.rawValue) {
                DataFilter.shared.pushData(packet: DataPacket(
                    dataType: conf.ARSession_settings[.WorldMappingStatus]!,
                    data: "{\"didRemove\": \(planeAnchor.toString())}".data(using: .utf8)!,
                    all_timestamp: Date().timeIntervalSince1970
                ))
        }
        if
            let meshAnchor = anchor as? ARMeshAnchor,
            let conf = Model.shared.t_currentConf,
            let opts = conf.ARSession_settings[.ObjectDetection]?.others?[OtherKeys.CallbackEvent.rawValue] as? [CallbackEvent.RawValue],
            opts.contains(CallbackEvent.didAdd.rawValue) {
                DataFilter.shared.pushData(packet: DataPacket(
                    dataType: conf.ARSession_settings[.ObjectDetection]!,
                    data: "{\"didAdd\": \(meshAnchor.toString())}".data(using: .utf8)!,
                    all_timestamp: Date().timeIntervalSince1970
                ))
        }
    }*/
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor,
           let conf = Model.shared.t_currentConf,
           let opts = conf.ARSession_settings[.PlaneDetection]?.others?[OtherKeys.CallbackEvent.rawValue] as? [CallbackEvent.RawValue],
           opts.contains(CallbackEvent.didAdd.rawValue) {
            DataFilter.shared.pushData(packet: DataPacket(
                dataType: conf.ARSession_settings[.PlaneDetection]!,
                data: "{\"didAdd\": \(planeAnchor.toString())}".data(using: .utf8)!,
                all_timestamp: Date().timeIntervalSince1970
            ))
        }
        if let meshAnchor = anchor as? ARMeshAnchor,
           let conf = Model.shared.t_currentConf,
           let opts = conf.ARSession_settings[.ObjectDetection]?.others?[OtherKeys.CallbackEvent.rawValue] as? [CallbackEvent.RawValue],
           opts.contains(CallbackEvent.didAdd.rawValue) {
            DataFilter.shared.pushData(packet: DataPacket(
                dataType: conf.ARSession_settings[.ObjectDetection]!,
                data: "{\"didAdd\": \(meshAnchor.toString())}".data(using: .utf8)!,
                all_timestamp: Date().timeIntervalSince1970
            ))
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor,
           let conf = Model.shared.t_currentConf,
           let opts = conf.ARSession_settings[.PlaneDetection]?.others?[OtherKeys.CallbackEvent.rawValue] as? [CallbackEvent.RawValue],
           opts.contains(CallbackEvent.didUpdate.rawValue) {
            DataFilter.shared.pushData(packet: DataPacket(
                dataType: conf.ARSession_settings[.PlaneDetection]!,
                data: "{\"didUpdate\": \(planeAnchor.toString())}".data(using: .utf8)!,
                all_timestamp: Date().timeIntervalSince1970
            ))
        }
        if let meshAnchor = anchor as? ARMeshAnchor,
           let conf = Model.shared.t_currentConf,
           let opts = conf.ARSession_settings[.ObjectDetection]?.others?[OtherKeys.CallbackEvent.rawValue] as? [CallbackEvent.RawValue],
           opts.contains(CallbackEvent.didUpdate.rawValue) {
            DataFilter.shared.pushData(packet: DataPacket(
                dataType: conf.ARSession_settings[.ObjectDetection]!,
                data: "{\"didUpdate\": \(meshAnchor.toString())}".data(using: .utf8)!,
                all_timestamp: Date().timeIntervalSince1970
            ))
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor,
           let conf = Model.shared.t_currentConf,
           let opts = conf.ARSession_settings[.PlaneDetection]?.others?[OtherKeys.CallbackEvent.rawValue] as? [CallbackEvent.RawValue],
           opts.contains(CallbackEvent.didRemove.rawValue) {
            DataFilter.shared.pushData(packet: DataPacket(
                dataType: conf.ARSession_settings[.PlaneDetection]!,
                data: "{\"didRemove\": \(planeAnchor.toString())}".data(using: .utf8)!,
                all_timestamp: Date().timeIntervalSince1970
            ))
        }
        if let meshAnchor = anchor as? ARMeshAnchor,
           let conf = Model.shared.t_currentConf,
           let opts = conf.ARSession_settings[.ObjectDetection]?.others?[OtherKeys.CallbackEvent.rawValue] as? [CallbackEvent.RawValue],
           opts.contains(CallbackEvent.didRemove.rawValue) {
            DataFilter.shared.pushData(packet: DataPacket(
                dataType: conf.ARSession_settings[.ObjectDetection]!,
                data: "{\"didRemove\": \(meshAnchor.toString())}".data(using: .utf8)!,
                all_timestamp: Date().timeIntervalSince1970
            ))
        }
    }
}


