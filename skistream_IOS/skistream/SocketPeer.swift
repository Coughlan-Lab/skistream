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
    var maxMTU = 0.0
    
    init(){
        // Create the log file if it doesn't exist
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
        
    }
    
    func connect() async -> (isConnected: Bool, msg: String) {
        var returnValue = (isConnected: false, msg: "")
        print("Attempting to connect...")
        
        host = NWEndpoint.Host(Model.shared.remoteIP)
        port = NWEndpoint.Port(integerLiteral: 65432)
        
        connection = NWConnection(host: host!, port: port!, using: .udp)
        
        connection!.stateUpdateHandler = { newState in
            switch newState {
                case .ready:
                    print("Connected to client")
                    //return (true,"Connected to client")
                    //receiveData(connection: connection)
                case .failed(let error):
                    self.isConnected = false
                    print("Connection failed: \(error)")
                    //return (isConnected: false, msg: "Connection failed: \(error)")
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
        await connection!.send(content: "1".data(using: .utf8), completion: .contentProcessed({error in
            if let error = error {
                print("Failed to send: \(error)")
                returnValue.msg = "Failed to send: \(error)"
            }
        }))
        returnValue.isConnected = await self.receivePong()
        return returnValue
    }
    
    func send(message: Data) {
        self.amount = 1
        
        self.logMessage(message)
        
        let chunks = splitDataIntoChunks(message, chunkSize: 1300) // Example chunk size
        let id = UUID()
        for (index, chunk) in chunks.enumerated() {
            let packet = createPacket(with: chunk, id: id, sequenceNumber: index+1, totalChunks: chunks.count)
            //sendPacket(packet, toAddress: address, port: port)
            connection!.send(content: packet, completion: .contentProcessed({ error in
                if let error = error {
                    self.isConnected = false
                    print("Failed to send: \(error)")
                    DataTransmitter.shared.semaphore_webRTCdataBuffer.signal()
                    self.amount = 0
                    return
                }
            }))
        }
        DataTransmitter.shared.semaphore_webRTCdataBuffer.signal()
        self.amount = 0
        
        
    }

    func splitDataIntoChunks(_ data: Data, chunkSize: Int) -> [Data] {
        var chunks: [Data] = []
        var offset = 0
        while offset < data.count {
            let end = min(offset + chunkSize, data.count)
            let chunk = data.subdata(in: offset..<end)
            chunks.append(chunk)
            offset += chunkSize
        }
        return chunks
    }
    
    struct PacketHeader: Codable {
        var id: UUID
        var sequenceNumber: Int
        var totalChunks: Int
    }

    func createPacket(with data: Data, id: UUID, sequenceNumber: Int, totalChunks: Int) -> Data {
        //headerData.count ~ 100
        let packet = PacketHeader(id: id, sequenceNumber: sequenceNumber, totalChunks: totalChunks)
        let packetData = try! JSONEncoder().encode(packet)
        return packetData + data
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

    func receivePong() async -> Bool {
        print(connection?.state)
        return await withCheckedContinuation { continuation in
            connection!.receive(minimumIncompleteLength: 1, maximumLength: 1024) { (data, _, isComplete, error) in
                if let data = data, let response = String(data: data, encoding: .utf8) {
                    // Check the response and return true/false based on the received data
                    if response == "1" {
                        DispatchQueue.main.async {
                            self.isConnected = true
                        }
                        continuation.resume(returning: true)
                    } else if response == "0" {
                        DispatchQueue.main.async {
                            self.isConnected = false
                        }
                        continuation.resume(returning: false)
                    } else {
                        print("Received: \(response)")
                        continuation.resume(returning: false)
                    }
                } else if let error = error {
                    print("Failed to receive: \(error)")
                    continuation.resume(returning: false) // Return false on error
                }
            }
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
