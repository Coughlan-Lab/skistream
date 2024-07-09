//
//  Model.swift
//  RTCnew
//
//  Created by Stefano on 21/06/24.
//

import Foundation

class Model: ObservableObject {
    static let shared: Model = Model()
    
    @Published var remoteIP: String = "192.168.1.28:5000"
    public let offerEndpoint = "/offer"
    public let synchEndpoint = "/synch"
    
    @Published var progressSynch = 0.0
    @Published var clockSynch = ClockSynch()
    
    @Published var receiverState: ReceiverState = .serverDelay
    
    var currentConf: [DataTypes: DataType]?
    
    var t_currentConf: Configuration?
    
    let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    var settingDir = "settings"
    
    init(){
        Task{createSupportDirectories()}
    }
    
}

class ClockSynch: ObservableObject {
    //static let shared = ClockSynch()
    @Published var error: Double = Double.infinity
    @Published var toAdd_toTheLocalClock: Double = 0.0
    var tmpServerTime: Double = 0.0
    var tmpMyEndTime: Double = 0.0
}

enum ReceiverState {
    case serverTime
    case serverDelay
}

enum Pages: String, CaseIterable {
    case SessionSettings
    case ConnectionSettings
    case Main
    case Socket
}
