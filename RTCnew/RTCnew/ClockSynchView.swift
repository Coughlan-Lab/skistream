//
//  ClockSynchView.swift
//  RTCnew
//
//  Created by Stefano on 21/06/24.
//

import SwiftUI
import WebRTC

struct ClockSynchView: View {
    @StateObject var model = Model.shared
    @State var maxIteration = 2
    @State var maxError = 0.0001
    @State var sleepTime: UInt32 = 1
    
    @Binding var connectionState: RTCIceConnectionState
    @StateObject var transmitter: DataTransmitter = DataTransmitter.shared
    
    func isConnected() -> Bool {
        return self.connectionState == .connected && transmitter.channel != nil
    }
    
    var body: some View {
        HStack{
            
            Button("synch with server") {
                Task{
                    DataTransmitter.shared.synchWithServer(
                        maxIteration: maxIteration,
                        maxError: maxError,
                         sleepTime: sleepTime
                    )
                    /*let answer = try await synchWithServer(
                        endpoint: "http://\(model.remoteIP)\(model.synchEndpoint)",
                        maxIteration: maxIteration,
                        maxError: maxError
                    )
                    print(answer)
                    print()*/
                }
            }.buttonStyle(.bordered).disabled(!isConnected())
            
            
            VStack{
                HStack{
                    Text("maxIteration: ")
                    TextField("maxIteration", value: $maxIteration, format: .number).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                }
                
                HStack{
                    Text("sleepTime (between iterations): ")
                    TextField("sleepTime", value: $sleepTime, format: .number).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                }
                /*HStack{
                    Text("maxError (in seconds): ")
                    TextField("maxError (in seconds)", value: $maxError, format: .number).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                }*/
                Text("error in seconds: \(model.clockSynch.error)")
                Text("adjustment time in seconds: \(model.clockSynch.toAdd_toTheLocalClock)")
                ProgressView(value: model.progressSynch)
            }
            
            
        }.padding(.all, 20)
    }
}
