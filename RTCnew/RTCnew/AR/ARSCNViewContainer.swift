//
//  ARSCNViewContainer.swift
//  RTCnew
//
//  Created by Stefano on 28/04/24.
//

import SwiftUI
import ARKit
import Foundation
import CoreMotion

struct ARSCNViewContainer: UIViewRepresentable {
    
    typealias UIViewType = ARSCNView
    
    var sceneView = ARSCNView(frame: .zero)
    var configuration = ARWorldTrackingConfiguration()
    
    var delegate = ARSCNDelegate()
    
    
    func makeUIView(context: Context) -> ARSCNView {
        sceneView.delegate = delegate
        delegate.setSceneView(sceneView)
        //Set lighting to the view
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        sceneView.scene = SCNScene()
        sceneView.session.delegate = delegate
        sceneView.session.run(configuration)
        return sceneView
    }

    func stopSession() {
        sceneView.session.pause()
        sceneView.removeFromSuperview()
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    
}

class ARSCNDelegate: NSObject, ARSCNViewDelegate, ARSessionDelegate {
    
    private var sceneView: ARSCNView?
    var trState: ARCamera.TrackingState?
    
    override init(){
        super.init()
    }
    
    /*func setpeer(p: Peer) {
        self.peer = p
    }*/
    
    /*func setEnv(semaphore_webRtcDataBuffer: DispatchSemaphore) {
        //self.peer = peer
        self.semaphore_webRtcDataBuffer = semaphore_webRtcDataBuffer
    }*/
    
    func setSceneView(_ scnV: ARSCNView) {
        sceneView = scnV
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        //var msg = ""
        
        /*if let camera = self.sceneView?.session.currentFrame?.camera {
            //CMMotionDetector.shared.stopDeviceMotionUpdates()
            DispatchQueue.main.async {NotificationCenter.default.post(name: .trackingPosition, object: camera.transform)}
        }*/
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        //print("session didUpdate")
        //let randomLength = Int.random(in: 1...loremIpsus.count)
        // Create a range from index 0 to the random length
        //let endIndex = loremIpsus.index(loremIpsus.startIndex, offsetBy: randomLength)
        //let substringRange = loremIpsus.startIndex..<endIndex
        // Extract the substring
        //let randomSubstring = String(loremIpsus[substringRange])
        
        /*peer?.sendMessage(data:
            " \(randomSubstring) \(self.sceneView?.session.currentFrame?.timestamp) "
            .data(using: .utf8)!
        )*/
        
        //print(session.currentFrame?.rawFeaturePoints?.description)
        
        /*peer?.sendMessage(data:
            " \(session.currentFrame?.rawFeaturePoints?.description) "
            .data(using: .utf8)!
        )*/
        
    }
    
    
}


struct ARSCNViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        ARSCNViewContainer()
    }
}
