//
//  Settings.swift
//  RTCnew
//
//  Created by Stefano on 25/06/24.
//

import SwiftUI
import WebRTC

struct ConnectionSettings: View {
    @StateObject var model = Model.shared
    //let peer = Peer()
    
    @Binding var connectionState: RTCIceConnectionState
    @Binding var dataChannelConnectionState_str: String
    @StateObject var transmitter: DataTransmitter = DataTransmitter.shared
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true){
            VStack{
                HStack{
                    Text("remote ip: ")
                    TextField("remoteIP", text: $model.remoteIP).textFieldStyle(.roundedBorder)
                }
                
                Button("connect to peer") {
                    Storage.shared.saveString(model.remoteIP)
                    Task{
                        let offer = await Peer.shared.createoffer()
                        let answer = try await sendOffer(endpoint: "http://\(model.remoteIP)\(model.offerEndpoint)", offer: offer)
                        if answer["code"] as! Int==1 {Peer.shared.setRemoteSDP(remoteSdpString: answer["sdp"] as! String)}
                    }
                }.buttonStyle(.bordered)
                
                Text("dataChannel.connectionState: \(dataChannelConnectionState_str)")
                Text("dataChannel.available: \(transmitter.channel != nil)")
                

                //ClockSynchView(connectionState: $connectionState).border(Color.red, width: 1.0)
                HStack{
                    Text("location manager auth status: \(SensorManager.shared.locationManager.authorizationStatus.toString())")
                }

            }
        }
        
    }
    
}
