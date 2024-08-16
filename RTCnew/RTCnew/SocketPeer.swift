//
//  SocketPeer.swift
//  RTCnew
//
//  Created by Stefano on 16/08/24.
//

import Foundation
import Network

class SocketPeer: ObservableObject {
    
    static let shared = SocketPeer()
    var host: NWEndpoint.Host?
    var port: NWEndpoint.Port?

    var connection: NWConnection?
    
    @Published var isConnected = false
    var amount = 0
    let logFileURL = Model.shared.directoryURL.appendingPathComponent("logData.txt")
    
    init(){
        // Create the log file if it doesn't exist
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
        
    }
    
    func connect(){
        print("Attempting to connect...")
        
        host = NWEndpoint.Host(Model.shared.remoteIP)
        port = NWEndpoint.Port(integerLiteral: 65432)
        
        connection = NWConnection(host: host!, port: port!, using: .udp)
        
        connection!.stateUpdateHandler = { newState in
            switch newState {
                case .ready:
                    print("Connected to client")
                    //receiveData(connection: connection)
                case .failed(let error):
                    self.isConnected = false
                    print("Connection failed: \(error)")
                case .cancelled:
                    self.isConnected = false
                    print("Connection cancelled by client")
                case .waiting(let error):
                    self.isConnected = false
                    print("Connection waiting: \(error)")
                case .preparing:
                    print("Connection preparing")
                @unknown default:
                    print("Unknown connection state")
            }
        }
        
        connection!.start(queue: DispatchQueue(label: "Socket.Queue"))
        connection!.send(content: "1".data(using: .utf8), completion: .contentProcessed({ error in
            if let error = error {
                print("Failed to send: \(error)")
                return
            }
            self.receivePong()
        }))
    }
    
    func send(message: Data) {
        self.amount = 1
        connection!.send(content: message, completion: .contentProcessed({ error in
            if let error = error {
                self.isConnected = false
                print("Failed to send: \(error)")
                return
            }
            //message correctly sended
            self.logMessage(message)
            self.amount = 0
            DataTransmitter.shared.semaphore_webRTCdataBuffer.signal()
        }))
    }
    
    private func logMessage(_ data: Data) {
        if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.write("\n".data(using: .utf8)!)  // Add a newline after each message
            fileHandle.closeFile()
        } else {
            print("Failed to log message")
        }
    }

    func receivePong() {
        connection!.receive(minimumIncompleteLength: 1, maximumLength: 1024) { (data, _, isComplete, error) in
            if let data = data, let response = String(data: data, encoding: .utf8) {
                if response == "1" {
                    DispatchQueue.main.sync {
                        self.isConnected = true
                    }
                    self.receivePong()
                }
                if response == "0" {
                    DispatchQueue.main.sync {
                        self.isConnected = false
                    }
                }
                print("Received: \(response)")
            } else if let error = error {
                print("Failed to receive: \(error)")
            }
            //exit(EXIT_SUCCESS)
        }
    }
    
    func closeConnection(){
        connection!.send(content: "exit".data(using: .utf8), completion: .contentProcessed({ error in
            if let error = error {
                print("Failed to send: \(error)")
                return
            }
            DispatchQueue.main.sync {
                self.isConnected = false
            }
            
        }))
    }
    
    
    
}
