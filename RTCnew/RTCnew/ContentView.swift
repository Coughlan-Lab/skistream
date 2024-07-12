//
//  ContentView.swift
//  RTCnew
//
//  Created by Stefano on 25/04/24.
//

import SwiftUI
import WebRTC
import CoreLocation

struct ContentView: View {
    let peer = Peer()
    //let semaphore_webRtcDataBuffer = DispatchSemaphore(value: 0)
    //let semaphore_dataBuffer = DispatchSemaphore(value: 0)
    
    //@State private var remoteIP = "192.168.1.24:5000"
    
    @StateObject var model = Model.shared
    
    @State private var offer: String = ""
    @State private var SDPanswer: String = ""
    
    @State private var message = 0
    
    @State var notification: String = ""
    @State var notificationBackgroundColor: Color = .white
    @State var dataChannelState: String = ""
    @State var dataChannelConnectionState: RTCIceConnectionState = .disconnected
    @State var dataChannelConnectionState_str: String = ""
    
    @State private var ARView: ARSCNViewContainer?
    
    @State private var ActualPage: Pages = .SessionSettings
    
    @StateObject var transmitter: DataTransmitter = DataTransmitter.shared
    
    @State var delay: Double = 0.0
    
    var body: some View {
        ZStack{
            //Content
            VStack{
                /*if ActualPage != .SessionSettings {
                    ScrollView(.horizontal, showsIndicators: true){
                        HStack{
                            Text("dataChannel.connectionState: \(dataChannelConnectionState_str)").onReceive(
                                NotificationCenter.default.publisher(for: .dataChannelConnectionState),
                                perform: { notif in
                                    if let m = notif.object as? RTCIceConnectionState {
                                        dataChannelConnectionState = m
                                        switch m {
                                        case .checking: dataChannelConnectionState_str = "checking"
                                        case .closed: dataChannelConnectionState_str = "closed"
                                        case .completed: dataChannelConnectionState_str = "completed"
                                        case .connected: dataChannelConnectionState_str = "connected"
                                        case .count: dataChannelConnectionState_str = "count"
                                        case .disconnected: dataChannelConnectionState_str = "disconnected"
                                        case .failed: dataChannelConnectionState_str = "failed"
                                        case .new: dataChannelConnectionState_str = "new"
                                        default: dataChannelConnectionState_str = "Unknown"
                                        }
                                    }
                                    
                                }
                            )
                            Text("dataChannel.available: \(transmitter.channel != nil)").onReceive(
                                NotificationCenter.default.publisher(for: .dataChannelReadyState),
                                perform: { notif in
                                    if let m = notif.object as? RTCDataChannelState {
                                        switch m {
                                        case .closing: dataChannelState = "closing"
                                        case .connecting: dataChannelState = "connecting"
                                        case .open: dataChannelState = "open"
                                        case .closed: dataChannelState = "closed"
                                        default: dataChannelState = "unknown"
                                        }
                                    }
                                    
                                }
                            )
                            Text("delay (ms): \(delay)").onReceive(
                                NotificationCenter.default.publisher(for: .delay),
                                perform: { if let m = $0.object as? Double {delay = m}}
                            )
                        }
                        Divider()
                        
                    }
                }*/
                
                TabView(selection: $ActualPage) {
                    NavigationStack() {SessionSettings()}
                    .tabItem {
                        Label("Configuration", systemImage: "slider.horizontal.3")
                    }
                    .tag(Pages.SessionSettings)
                    
                    NavigationStack() {ConnectionSettings(connectionState: $dataChannelConnectionState, dataChannelConnectionState_str: $dataChannelConnectionState_str)}
                    .tabItem {
                        Label("Connection", systemImage: "link.circle")
                    }
                    .tag(Pages.ConnectionSettings)
                    
                    NavigationStack() {Main(connectionState: $dataChannelConnectionState, delay: $delay)}
                    .tabItem {
                        Label("Stream Data", systemImage: "arrow.triangle.pull")
                    }
                    .tag(Pages.Main)
                        
                }
                
            }
            .onReceive(
                NotificationCenter.default.publisher(for: .dataChannelConnectionState),
                perform: { notif in
                    if let m = notif.object as? RTCIceConnectionState {
                        dataChannelConnectionState = m
                        switch m {
                        case .checking: dataChannelConnectionState_str = "checking"
                        case .closed: dataChannelConnectionState_str = "closed"
                        case .completed: dataChannelConnectionState_str = "completed"
                        case .connected: dataChannelConnectionState_str = "connected"
                        case .count: dataChannelConnectionState_str = "count"
                        case .disconnected: dataChannelConnectionState_str = "disconnected"
                        case .failed: dataChannelConnectionState_str = "failed"
                        case .new: dataChannelConnectionState_str = "new"
                        default: dataChannelConnectionState_str = "Unknown"
                        }
                    }
                    
                }
            )
            .onReceive(
                NotificationCenter.default.publisher(for: .dataChannelReadyState),
                perform: { notif in
                    if let m = notif.object as? RTCDataChannelState {
                        switch m {
                        case .closing: dataChannelState = "closing"
                        case .connecting: dataChannelState = "connecting"
                        case .open: dataChannelState = "open"
                        case .closed: dataChannelState = "closed"
                        default: dataChannelState = "unknown"
                        }
                    }
                    
                }
            )
            .onReceive(
                NotificationCenter.default.publisher(for: .delay),
                perform: { if let m = $0.object as? Double {delay = m}}
            )
            
            //Notification
            VStack{
                Text(notification)
                .onTapGesture {
                    notification = ""
                    notificationBackgroundColor = Color.white
                }
                .background(notificationBackgroundColor)
                .cornerRadius(4)
                .padding(.all, 5)
                .onReceive(
                    NotificationCenter.default.publisher(for: .genericMessage),
                    perform: { notif in
                        if let m = notif.object as? [String: Any] {
                            notification = "\(m["msg"] as! String), tap to remove"
                            notificationBackgroundColor = m["backgroundColor"] as! Color
                        }
                        //print(msg)
                        //if let m = msg.object as? String {notification=m}
                    }
                )
                Spacer()

                
            }
            
        }
        
        
    }
}

#Preview {
    ContentView()
}
