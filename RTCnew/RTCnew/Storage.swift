//
//  Storage.swift
//  RTCnew
//
//  Created by Stefano on 12/07/24.
//

import Foundation

struct Storage {
    static let shared = Storage()
    private let defaults = UserDefaults.standard
    
    private let key = "storedString"
    
    func saveString(_ string: String) {
        defaults.set(string, forKey: key)
    }
    
    func loadString() -> String {
        return defaults.string(forKey: key) ?? "192.168.X.X:5000"
    }
}
