//
//  Utils.swift
//  RTCnew
//
//  Created by Stefano on 25/06/24.
//

import Foundation
import ARKit

var sequentialImgID = 0
let chunkSize = 10 * 1024 // 10KB in bytes
let chuckSizeChar = 5120

func readFile(){}

func writeFile(){
}

func listOfFilesURL(path: [String]) -> [URL]? {
    var defUrl = Model.shared.directoryURL
    for e in path {defUrl.append(path: e)}
    print(defUrl)
    if let list = try? FileManager.default.contentsOfDirectory(at: defUrl, includingPropertiesForKeys: nil) {
        return list.sorted(by: {a,b in a.lastPathComponent<b.lastPathComponent})
    } else {
        print("error reading files at \(defUrl)")
    }
    return nil
}

func createSupportDirectories() {
    do {
        try FileManager.default.createDirectory(atPath: Model.shared.directoryURL.appending(path: Model.shared.settingDir).path, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print("error creating \(Model.shared.settingDir) directory")
    }
    
}

func printConf(conf: [DataTypes: DataType]) {
    print(conf.debugDescription)
    for k in Array(conf.keys).sorted(by: {$0.rawValue<$1.rawValue}) {
        let v = conf[k]!
        print("k: \(k.rawValue) \(v.toStr())")
    }
}


enum ARConfig: String, Codable, CaseIterable {
    case ARWorldTrackingConfiguration
    //case ARBodyTrackingConfiguration
    //case ARFaceTrackingConfiguration
    //case ARImageTrackingConfiguration
    /*func ARConfigurationFromName() -> ARConfiguration {
        switch self {
        case .ARWorldTrackingConfiguration: return ARWorldTrackingConfiguration()
        //case .ARBodyTrackingConfiguration: return ARBodyTrackingConfiguration()
        //case .ARFaceTrackingConfiguration: return ARFaceTrackingConfiguration()
        //case .ARImageTrackingConfiguration: return ARImageTrackingConfiguration()
        }
    }*/
}




func convertFrameToBase64(pixelBuffer: CVPixelBuffer, grayScale: Bool) -> String? {
    let imgID = sequentialImgID.description
    sequentialImgID += 1

    // Convert CVPixelBuffer to UIImage
    var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    if grayScale{ciImage = ciImage.applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0] )}
    let context = CIContext(options: nil)

    if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
        let uiImage = UIImage(cgImage: cgImage)
        
        // Convert UIImage to Data
        guard let imageData = uiImage.jpegData(compressionQuality: 0.0) else {
            return nil
        }

        // Convert Data to base64 string
        let base64String = imageData.base64EncodedString(options: .lineLength64Characters)
        return base64String
        
        /*if (/*base64String.data(using: .utf8)!.count <= chunkSize*/ base64String.count <= chuckSizeChar) {
            return ["""
                {
                \"imgID\" : \(imgID)
                \"fragmentID\" : \(1)
                \"nFragments\" : \(1)
                \"fragment\" : \(base64String)
                }
            """
            ]
        }
        
        var chunks: [String] = []
        
        var sub = base64String
        while true {
            let e = sub.prefix(chuckSizeChar) //10KB, each char 2 bytes
            chunks.append(String(e))
            if (sub.count <= chuckSizeChar) {break}
            let i = sub.index(sub.startIndex, offsetBy: chuckSizeChar)
            sub = String(sub[i...])
        }
        
        
        return chunks.enumerated().map{(n, e) in """
            {
            \"imgID\" : \(imgID)
            \"fragmentID\" : \(n+1)
            \"nFragments\" : \(chunks.count)
            \"fragment\" : \(e)
            }
        """}*/
        
    }
    
    return nil
}



extension ARFrame.WorldMappingStatus {
    func toString() -> String {
        switch self {
        case .extending:
            return "extending"
        case .limited:
            return "limited"
        case .mapped:
            return "mapped"
        case .notAvailable:
            return "notAvailable"
        @unknown default:
            fatalError()
        }
    }
}

extension ARCamera.TrackingState {
    func toString() -> String {
        switch self {
        case .notAvailable:
            return "notAvailable"
        case .limited:
            return "limited"
        case .normal:
            return "normal"
        @unknown default:
            fatalError()
        }
    }
}


enum PriorityLevel: String, Codable, CaseIterable {
    case nice, low, medium, high, maximum, personalized
    
    static func get_basePriorityFromDouble(n: Int) -> PriorityLevel {
        switch n {
        case 10: return .nice
        case 100: return .low
        case 1000: return .medium
        case 5000: return .high
        case 10000: return .maximum
        default: return .personalized
        }
    }
    
    static func get_priorityIncrementFromDouble(n: Int) -> PriorityLevel {
        switch n {
        case 0: return .nice
        case 10: return .low
        case 100: return .medium
        case 500: return .high
        case 1000: return .maximum
        default: return .personalized
        }
    }
    
    func get_basePriority() -> Int? {
        switch self {
        case .nice: return 10
        case .low: return 100
        case .medium: return 1000
        case .high: return 5000
        case .maximum: return 10000
        case .personalized: return nil
        }
    }
    
    func get_priorityIncrement() -> Int? {
        switch self {
        case .nice: return 0
        case .low: return 10
        case .medium: return 100
        case .high: return 500
        case .maximum: return 1000
        case .personalized: return nil
        }
    }
    
    static func get_priorityFromValues(bp: Int, pi: Int) -> PriorityLevel {
        let bp_level = PriorityLevel.get_basePriorityFromDouble(n: bp)
        let pi_level = PriorityLevel.get_priorityIncrementFromDouble(n: pi)
        return (bp_level == pi_level) ? bp_level : .personalized
    }
}


enum InfoText {
    case priority, basePriority, priorityIncrement, queuePolicy, updateInterval

    func getText() -> String {
        switch self {
        case .priority:
            return "This is the priority.\nHigher priority means higher network delay tolerability."
        case .basePriority:
            return "Base Priority is the initial priority value in milliseconds.\nIt sets the starting point for the priority of this data type."
        case .priorityIncrement:
            return "Priority Increment is the amount by which the priority increases each time the data is not queued.\nHigher values mean the priority increases more rapidly over time."
        case .queuePolicy:
            return "Queue Policy determines how data is managed in the queue before sending.\n'Enqueue' sends all queued data, 'LastOnly' sends only the most recent data"
        case .updateInterval:
            return "Update Interval is the time in seconds between each data update in seconds.\nIt controls how frequently new data is generated or sampled for this type.\nto specify a double value use the comma like 0,1"
        }
    }
}


func selectVideoFormat(for resolution: CGSize) -> ARConfiguration.VideoFormat {
    let availableFormats = ARWorldTrackingConfiguration.supportedVideoFormats
    let sorted = availableFormats.sorted { (f1, f2) -> Bool in
        abs(f1.imageResolution.width - resolution.width) < abs(f2.imageResolution.width - resolution.width)
    }
    return sorted.first ?? ARWorldTrackingConfiguration.supportedVideoFormats[0]
}

enum OtherKeys: String, Codable, CaseIterable {
    case FrameColor, FrameResolution, PlaneDirection, CallbackEvent
}

enum FrameColor: String, Codable, CaseIterable {
    case RGB, GrayScale
}

enum CallbackEvent: String, Codable, CaseIterable {
    case didAdd, didUpdate, didRemove
}



extension ARWorldTrackingConfiguration.PlaneDetection.RawValue {
    var planeDirection_StringDescription: String {
        switch self {
        case ARWorldTrackingConfiguration.PlaneDetection.horizontal.rawValue: return "horizontal"
        case ARWorldTrackingConfiguration.PlaneDetection.vertical.rawValue: return "vertical"
        default: return "none"
        }
    }
}


extension ARPlaneAnchor {
    func toString() -> String {
        var result = "{"
        result += "\"identifier\":\"\(self.identifier)\","
        result += "\"center\":[\(self.center.x),\(self.center.y),\(self.center.z)],"

        result += "\"size\":[\(self.planeExtent.width),\(self.planeExtent.height)],"
        
        // Transformation matrix
        result += "\"transform\":\(self.transform.debugDescription),"
        
        // Alignment (horizontal, vertical)
        result += "\"alignment\":\"\(self.alignment)\","
        
        // Classification (floor, wall, ceiling, etc.)
        if #available(iOS 12.0, *) {
            result += "\"classification\":\"\(self.classification)\""
        } else {
            result += "\"classification\":\"unknown\""
        }
        
        result += "}"
        return result
    }
}

extension ARMeshAnchor {
    func toString() -> String {
        var result = "{"
        
        // Identifier
        result += "\"identifier\":\"\(self.identifier)\","
        
        // Transform
        result += "\"transform\":\(self.transform.debugDescription),"
        
        // Geometry
        result += "\"vertexCount\":\(self.geometry.vertices.count),"
        result += "\"faceCount\":\(self.geometry.faces.count),"
        
        // Classification
        if #available(iOS 14.0, *) {
            if let geometrySource = geometry.classification {
                let buffer = geometrySource.buffer
                let stride = geometrySource.stride
                let format = geometrySource.format
                
                if format == .uchar {
                    let contents = buffer.contents().bindMemory(to: UInt8.self, capacity: 1)
                    let classificationValue = contents.pointee
                    if let classification = ARMeshClassification(rawValue: Int(classificationValue)) {
                        result += ",\"classification\":\"\(classification)\""
                    } else {
                        result += ",\"classification\":\"unknown\""
                    }
                } else {
                    result += ",\"classification\":\"unknown\""
                }
            } else {
                result += ",\"classification\":\"unknown\""
            }
        } else {
            result += ",\"classification\":\"unavailable\""
        }
        
        // Close the main JSON object
        result += "}"
        
        return result
    }
}
