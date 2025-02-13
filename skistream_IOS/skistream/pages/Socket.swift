//
//  Socket.swift
//  RTCnew
//
//  Created by Stefano on 04/07/24.
//

import SwiftUI
import Network

struct Socket: View {
    @StateObject var model = Model.shared
    @ObservedObject var socketpeer = SocketPeer.shared
    
    var body: some View {
        VStack{
            Image(systemName: socketpeer.isConnected ? "shareplay" : "shareplay.slash").resizable().scaledToFit()
                .frame(width: 100, height: 200)
            HStack{
                Text("remote ip: ")
                TextField("remoteIP", text: $model.remoteIP).textFieldStyle(.roundedBorder)
            }
            HStack{
                Button("connect"){
                    Storage.shared.saveString(model.remoteIP)
                    Task{
                        let result = await SocketPeer.shared.connect()
                        let _ = print(result.isConnected)
                        if !result.isConnected {
                            NotificationCenter.default.post(
                                name: .genericMessage,
                                object: ["msg": "Failed to connect: \(result.msg)", "backgroundColor": Color.red]
                            )
                        } else {
                            NotificationCenter.default.post(
                                name: .genericMessage,
                                object: ["msg": "connected", "backgroundColor": Color.green]
                            )
                        }
                    }
                    
                }.buttonStyle(.bordered).disabled(socketpeer.isConnected)
                //Button("sendmesage"){sendPing(message: "ping")}
                Button("close connection"){
                    SocketPeer.shared.closeConnection()
                }.buttonStyle(.bordered).disabled(!socketpeer.isConnected)
                
            }
            Divider()
            Image(systemName: "location.fill").resizable().scaledToFit()
                    .frame(width: 100, height: 200)
            Text("location manager auth status: \(SensorManager.shared.locationManager.authorizationStatus.toString())")
        }.padding(.all, 10)
    }
}


#Preview {
    Socket()
}
