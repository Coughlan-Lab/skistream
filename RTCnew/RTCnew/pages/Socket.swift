//
//  Socket.swift
//  RTCnew
//
//  Created by Stefano on 04/07/24.
//

import SwiftUI
import Network

struct Socket: View {
    
    let host: NWEndpoint.Host
    let port: NWEndpoint.Port

    let connection: NWConnection
    
    init() {
        host = NWEndpoint.Host(" 192.168.84.18")
        port = NWEndpoint.Port(integerLiteral: 65432)
        connection = NWConnection(host: host, port: port, using: .tcp)
        connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("Connected to server")
            case .failed(let error):
                print("Connection failed: \(error)")
                exit(EXIT_FAILURE)
            case .waiting(let error):
                print("Connection waiting: \(error)")
            default:
                break
            }
        }
        //connection.start(queue: .main)
        //RunLoop.main.run()
    }
    
    func sendPing(message: String) {
        connection.send(content: message.data(using: .utf8), completion: .contentProcessed({ error in
            if let error = error {
                print("Failed to send: \(error)")
                return
            }
            print("Sent: \(message)")
            receivePong()
        }))
    }

    func receivePong() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { (data, _, isComplete, error) in
            if let data = data, let response = String(data: data, encoding: .utf8) {
                print("Received: \(response)")
            } else if let error = error {
                print("Failed to receive: \(error)")
            }
            //exit(EXIT_SUCCESS)
        }
    }
    
    var body: some View {
        Text("socket")
        Button("connect"){connection.start(queue: DispatchQueue(label: "Socket.Queue"))}
        Button("sendmesage"){sendPing(message: "ping")}
        Button("exit"){sendPing(message: "exit")}
    }
}


#Preview {
    Socket()
}
