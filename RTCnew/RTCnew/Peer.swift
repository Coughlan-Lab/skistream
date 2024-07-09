//
//  Peer.swift
//  RTCnew
//
//  Created by Stefano on 25/04/24.
//

import Foundation
import WebRTC

class Peer: NSObject {
    
    static let shared = Peer()
    
    private let peerConnection: RTCPeerConnection
    private let mediaConstrains: RTCMediaConstraints
    private let mandatoryConstraints = [
        kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
        kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue
    ]
    
    //video
    private var videoCapturer: RTCVideoCapturer?
    
    private var localVideoTrack: RTCVideoTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    
    //data
    private var localDataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?
    
    private var innerBuffer: [RTCDataBuffer] = []
    
    
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    
    override init () {
        let config = RTCConfiguration()
        //config.iceServers = [RTCIceServer(urlStrings: Config.default.webRTCIceServers)]
        // Unified plan is more superior than planB
        config.sdpSemantics = .unifiedPlan
        // gatherContinually will let WebRTC to listen to any network changes and send any new candidates to the other client
        config.continualGatheringPolicy = .gatherContinually
        
        // Define media constraints. DtlsSrtpKeyAgreement is required to be true to be able to connect with web browsers.
        //let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement":kRTCMediaConstraintsValueTrue])
        self.mediaConstrains = RTCMediaConstraints.init(mandatoryConstraints: self.mandatoryConstraints, optionalConstraints: nil)
        
        let p = Peer.factory.peerConnection(with: config, constraints: self.mediaConstrains, delegate: nil)
        self.peerConnection = p
        
        super.init()
        //self.createMediaSenders()
        self.peerConnection.delegate = self
    }
    
    private func createMediaSenders() {
        let streamId = "stream"
        
        // Audio
        //let audioTrack = self.createAudioTrack()
        //self.peerConnection.add(audioTrack, streamIds: [streamId])
        
        // Video
        //let videoTrack = self.createVideoTrack()
        //self.localVideoTrack = videoTrack
        //self.peerConnection.add(videoTrack, streamIds: [streamId])
        //self.remoteVideoTrack = self.peerConnection.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
        
        // Data
        if let dataChannel = createDataChannel() {
            dataChannel.delegate = self
            let c = RTCDataChannelConfiguration()
            
            self.localDataChannel = dataChannel
        }
    }
    
    /*private func createAudioTrack() -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = Peer.factory.audioSource(with: audioConstrains)
        let audioTrack = Peer.factory.audioTrack(with: audioSource, trackId: "audio0")
        return audioTrack
    }
    
    private func createVideoTrack() -> RTCVideoTrack {
        let videoSource = Peer.factory.videoSource()
        
        #if targetEnvironment(simulator)
        self.videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
        #else
        self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        #endif
        
        let videoTrack = Peer.factory.videoTrack(with: videoSource, trackId: "video0")
        return videoTrack
    }*/
    
    // MARK: Data Channels
    
    private func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        guard let dataChannel = self.peerConnection.dataChannel(forLabel: "WebRTCData", configuration: config) else {
            debugPrint("Warning: Couldn't create data channel.")
            return nil
        }
        return dataChannel
    }
    
    public func createoffer() async -> [String:String] {
        if let dataChannel = createDataChannel() {
            dataChannel.delegate = self
            let c = RTCDataChannelConfiguration()
            self.localDataChannel = dataChannel
        }
        print("created dataChannel \(self.localDataChannel?.channelId) \(self.localDataChannel?.readyState.rawValue)")
        do {
            let constraints = RTCMediaConstraints.init(mandatoryConstraints: self.mandatoryConstraints, optionalConstraints: nil)
            let offer = try await self.peerConnection.offer(for: constraints)
            try await self.peerConnection.setLocalDescription(offer)
            //let jsonOffer = try JSONSerialization.data(withJSONObject: ["sdp": offer.sdp, "type":"offer"])
            //let jsonString = String(data: jsonOffer, encoding: .utf8)
            //print(["sdp": offer.sdp, "type":"offer"])
            return ["sdp": offer.sdp, "type":"offer"]
        } catch {
            print("error")
            return ["error":"error"]
        }
    }
    
    
    
    func setRemoteSDP(remoteSdpString: String) {
        let remoteSdp = RTCSessionDescription(type: .answer, sdp: remoteSdpString)
        self.peerConnection.setRemoteDescription(
            remoteSdp,
            completionHandler: {
                error in print("error in sdp from remote answer \(String(describing: error))")
            }
        )
        //self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }
    
    func sendData(data: Data) {
        self.remoteDataChannel?.sendData(RTCDataBuffer(data: data, isBinary: true))
        
        //print("inner buffer size: \(innerBuffer.count)")
        
        //print("remoteDataChannel.bufferedAmount : \(remoteDataChannel?.bufferedAmount)")
            
        /*let dp = DataPacket(
            dataType: DataType(basePriority: 1, priorityIncrement: 1, queuePolicy: QueuePolicy.lastOnly),
            data: data,
            timestamp: .now
        )*/
        
        
        /*if remoteDataChannel!.bufferedAmount != 0 {
            innerBuffer.append(actual)
            return
        }
        
        if innerBuffer.isEmpty {
            self.remoteDataChannel?.sendData(actual)
        } else {
            let poppedElement = innerBuffer.remove(at: 0)
            self.remoteDataChannel?.sendData(poppedElement)
        }*/
        
        //print("after msg, buffer: \(remoteDataChannel?.bufferedAmount)")
        
    }
    
    func isEmptyWebRTCBuffer() -> Bool {
        return self.remoteDataChannel!.bufferedAmount == 0
    }
}



extension Peer: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        debugPrint("peerConnection new signaling state: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        debugPrint("peerConnection did add stream")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        debugPrint("peerConnection did remove stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        debugPrint("peerConnection should negotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        debugPrint("peerConnection new connection state: \(newState)")
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .dataChannelConnectionState,
                object: newState
            )
        }
        if newState == .disconnected {
            DataTransmitter.shared.setDataChannel(channel: nil)
        }
        
        /*if newState == .disconnected {
            self.remoteDataChannel?.close()
            self.localDataChannel?.close()
        }*/
        /*debugPrint("peerConnection new connection state: \(newState)")
        switch newState {
        case .checking: print("checking")
        case .closed: print("closed")
        case .completed: print("completed")
        case .connected: print("connected")
        case .count: print("count")
        case .disconnected: print("disconnected")
        case .failed: print("failed")
        case .new: print("new")
        default: print("Unknown")
        }*/
        
        //self.delegate?.webRTCClient(self, didChangeConnectionState: newState)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugPrint("peerConnection new gathering state: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        //self.delegate?.webRTCClient(self, didDiscoverLocalCandidate: candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugPrint("peerConnection did remove candidate(s)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugPrint("peerConnection did open data channel")
        //self.remoteDataChannel = dataChannel
    }
}


extension Peer: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("dataChannelDidChangeState did change state: \(dataChannel.readyState.rawValue)")
        print(": \(dataChannel.readyState.rawValue)")
        print(": \(dataChannel.readyState == .open)")
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .dataChannelReadyState,
                object: dataChannel.readyState
            )
        }
        
        
        if (dataChannel.readyState == .open) {
            DataTransmitter.shared.setDataChannel(channel: dataChannel)
        } else {
            DataTransmitter.shared.setDataChannel(channel: nil)
        }
        
        /*DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .genericMessage,
                object: ["type": "dataChannelDidChangeState", "msg": dataChannel.description]
            )            
        }
        
        if (dataChannel.readyState.rawValue == 1) {
            self.remoteDataChannel = dataChannel
            self.remoteDataChannel?.observe(\.bufferedAmount) {(obj, change) in print("change bufferedAmount \(change.oldValue) to \(change.newValue) -> obj value \(obj.bufferedAmount)")}
        }*/
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didChangeBufferedAmount amount: UInt64) {
        //print("didChangeBufferedAmount \(amount)")
        //if (amount == 0) {DataTransmitter.shared.semaphore_webRTCdataBuffer.signal()}
        
        DataTransmitter.shared.semaphore_webRTCdataBuffer.signal()
        //print("didChangeBufferedAmount, semaphore_webRTCdataBuffer.signal()")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        //datafilter.setTransmissionDelay()
        let timestamp = Date().timeIntervalSince1970
        let msg = String(decoding: buffer.data, as: UTF8.self)
        switch Model.shared.receiverState {
        case .serverTime:
            Model.shared.clockSynch.tmpServerTime = Double(msg)!
            Model.shared.clockSynch.tmpMyEndTime = timestamp
            DataTransmitter.shared.semaphore_receiveFromWebRTC.signal()
        case .serverDelay:
            //print("delay: \(msg)")
            if let delay = Double(msg) {
                print("delay ms: \(delay * 1000)")
                //DataFilter.shared.updateDelay(newDelay: delay * 1000)
            }
        default:
            print("dataChannel didReceiveMessageWith: \(dataChannel.channelId) \(buffer.data) \(String(decoding: buffer.data, as: UTF8.self))")
        }
        
    }
    
}
