//
//  SessionSettings.swift
//  RTCnew
//
//  Created by Stefano on 25/06/24.
//

import SwiftUI
import ARKit

struct SessionSettings: View {
    
    private let adaptiveColumn = [GridItem(.adaptive(minimum: 200))]
    
    @State var currentConf: [DataTypes: DataType] = [:]
    
    @State var t_currentConf: Configuration
    
    @State var refresh: Bool = false
    
    @State private var showingAlert = false
    @State private var name = ""
    @State private var filter = ""
    
    @State private var show_ModalSelectConf = false
    @State private var show_ModalSaveConf = false
    @State private var show_Filter = false
    
    init() {
        if let c = Model.shared.t_currentConf {
            t_currentConf = c
        } else {
            //_t_currentConf = State(initialValue: Configuration.defaultConf.deepCopy())
            t_currentConf = Configuration.defaultConf.deepCopy()
            Model.shared.t_currentConf = t_currentConf
        }
        /*if let c = Model.shared.currentConf {
            currentConf = c
        } else {
            var copyConf: [DataTypes: DataType] = [:]
            for (k, v) in DataType.types {
                copyConf[k] = DataType(label: v.label, basePriority: v.basePriority, priorityIncrement: v.priorityIncrement, queuePolicy: v.queuePolicy, enabled: v.enabled, updateInterval: v.updateInterval)
            }
            _currentConf = State(initialValue: copyConf)
            Model.shared.currentConf = currentConf
        }*/
        
        
    }
    
    func updateView() {
       refresh.toggle()
    }
    
    func newConf(){
        t_currentConf = Configuration.defaultConf.deepCopy()
        Model.shared.t_currentConf = t_currentConf
        /*var copyConf: [DataTypes: DataType] = [:]
        for (k, v) in DataType.types {
            copyConf[k] = DataType(label: v.label, basePriority: v.basePriority, priorityIncrement: v.priorityIncrement, queuePolicy: v.queuePolicy, enabled: v.enabled, updateInterval: v.updateInterval)
        }
        currentConf = copyConf
        Model.shared.currentConf = currentConf*/
    }
    
    func saveConf(){
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(t_currentConf)
            try data.write(to: Model.shared.directoryURL.appending(path: Model.shared.settingDir).appending(path: self.name))
            Model.shared.t_currentConf = t_currentConf
            updateView()
            NotificationCenter.default.post(
                name: .genericMessage,
                object: ["msg": "configuration saved: \(self.name)", "backgroundColor": Color.green]
            )
        } catch {
            print(error)
            NotificationCenter.default.post(
                name: .genericMessage,
                object: ["msg": "Failed to encode currentConf: \(error)", "backgroundColor": Color.red]
            )
        }
    }
    
    func loadConf(url: URL) {
        print("load Conf: \(url) \(url.lastPathComponent)")
        do {
            let data = try? Data(contentsOf: url)
            let conf = try? JSONDecoder().decode(Configuration.self, from: data!)
            t_currentConf = conf!
            name = url.lastPathComponent
            Model.shared.t_currentConf = t_currentConf
            NotificationCenter.default.post(
                name: .genericMessage,
                object: ["msg": "configuration loaded: \(self.name)", "backgroundColor": Color.green]
            )
        } catch {
            NotificationCenter.default.post(
                name: .genericMessage,
                object: ["msg": "Failed to decode conf form file: \(error)", "backgroundColor": Color.red]
            )
        }
        /*do {
            let data = try? Data(contentsOf: url)
            let conf = try? JSONDecoder().decode([DataTypes: DataType].self, from: data!)
            currentConf = conf!
            name = url.lastPathComponent
            Model.shared.currentConf = currentConf
            //let data2 = jsonString.data(using: .utf8)
            //let decoder = JSONDecoder()
            //let decodedConf = try decoder.decode([DataTypes: DataType].self, from: data)
            NotificationCenter.default.post(
                name: .genericMessage,
                object: ["msg": "configuration loaded: \(self.name)", "backgroundColor": Color.green]
            )
        } catch {
            print("Failed to decode conf form file: \(error)")
        }*/
        
    }
    
    func selectAll(){
        for k in self.t_currentConf.sensors.keys {
            self.t_currentConf.sensors[k]!.enabled = true
        }
        self.t_currentConf.ARSession = true
        self.t_currentConf.CameraStream = false
        for k in self.t_currentConf.ARSession_settings.keys {
            self.t_currentConf.ARSession_settings[k]!.enabled = true
        }
        /*for k in Array(self.currentConf.keys).sorted(by: {$0.rawValue<$1.rawValue}) {
            self.currentConf[k]!.enabled = true
        }*/
        updateView()
    }
    func deselectAll(){
        for k in self.t_currentConf.sensors.keys {
            self.t_currentConf.sensors[k]!.enabled = false
        }
        self.t_currentConf.ARSession = false
        self.t_currentConf.CameraStream = false
        for k in self.t_currentConf.ARSession_settings.keys {
            self.t_currentConf.ARSession_settings[k]!.enabled = false
        }
        /*for k in Array(self.currentConf.keys).sorted(by: {$0.rawValue<$1.rawValue}) {
            self.currentConf[k]!.enabled = false
        }*/
        updateView()
    }
    
    var body: some View {
        VStack{
            
            HStack{
                //FILTER
                Button(action: {show_Filter = !show_Filter}){
                    Image(systemName: show_Filter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    Text("filter")
                }
                Spacer()
                //DESELECT ALL
                Button(action: self.deselectAll){
                    Image(systemName: "checkmark.circle")
                    Text("uncheck all")
                }
                Spacer()
                //SELECT ALL
                Button(action: self.selectAll){
                    Image(systemName: "checkmark.circle.fill")
                    Text("check all")
                }
                
            }
            
            if show_Filter{
                HStack{
                    Text("filter: ")
                    TextField("filter", text: $filter).textFieldStyle(.roundedBorder)
                    Button("clear", action: {filter = ""}).buttonStyle(.bordered)
                }
            }
            
            
            /*HStack{
                Button("select all", action: self.selectAll).buttonStyle(.bordered)
                .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 10)
                Button("deselect all", action: self.deselectAll).buttonStyle(.bordered)
                .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 10)
            }*/
            //Button("printConf", action: {printConf(conf: self.currentConf)}).buttonStyle(.bordered)
            ScrollView(.vertical, showsIndicators: true){
                //Sensors
                //title
                ZStack{
                    Color.red.opacity(0.1)
                    VStack{
                        Text(Cat.Sensors.rawValue)
                    }.padding(.all, 10)
                }
                //settings
                ForEach(t_currentConf.sensors.map{$0.key}.sorted(by: {$0.rawValue<$1.rawValue}), id: \.rawValue){ k in
                    if (filter == "" || k.rawValue.lowercased().contains(filter.lowercased())) {
                        ZStack{
                            Color.gray.opacity(0.1)
                            HStack{
                                Toggle(k.rawValue, isOn: Binding(
                                    get:{self.t_currentConf.sensors[k]!.enabled},
                                    set:{
                                        self.t_currentConf.sensors[k]!.enabled = $0
                                        updateView()
                                    }
                                ))
                                Card2(
                                    k: k,
                                    pV: Binding(
                                        get: { self.t_currentConf.sensors[k]! },
                                        set: { self.t_currentConf.sensors[k] = $0 }
                                    ),
                                    updateView: updateView
                                )
                                /*if (self.t_currentConf.sensors[k]!.enabled) {
                                    //Card(k: k, pV: self.t_currentConf.sensors[k]!, updateView: updateView)
                                }*/
                            }.padding(.all, 10)
                        }
                    }
                }
                //AR
                //title
                ZStack{
                    Color.red.opacity(0.1)
                    VStack{
                        Text(Cat.ARSession.rawValue)
                    }.padding(.all, 10)
                }
                //general enable
                ZStack{
                    Color.gray.opacity(0.1)
                    HStack{
                        Toggle(
                            Cat.ARSession.rawValue,
                            isOn: Binding(
                                get: {self.t_currentConf.ARSession},
                                set: {
                                    self.t_currentConf.ARSession = $0
                                    if ($0) {self.t_currentConf.CameraStream = !$0}
                                    updateView()
                                }
                            )
                        )
                        Picker(
                            "configuration",
                            selection: Binding(
                                get: {self.t_currentConf.ARSession_conf},
                                set: {
                                    self.t_currentConf.ARSession_conf = $0
                                    updateView()
                                }
                            )
                        ){
                            ForEach(ARConfig.allCases, id: \.self) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }.disabled(!self.t_currentConf.ARSession)
                        
                    }.padding(.all, 10)
                }
                //settings
                ForEach(self.t_currentConf.ARSession ? t_currentConf.ARSession_settings.map{$0.key}.sorted(by: {$0.rawValue<$1.rawValue}) : [], id: \.rawValue){ k in
                    if (filter == "" || k.rawValue.lowercased().contains(filter.lowercased())) {
                        ZStack{
                            Color.gray.opacity(0.1)
                            HStack{
                                Toggle(k.rawValue, isOn: Binding(
                                    get:{self.t_currentConf.ARSession_settings[k]!.enabled},
                                    set:{
                                        self.t_currentConf.ARSession_settings[k]!.enabled = $0
                                        updateView()
                                    }
                                ))
                                Card2(
                                    k: k,
                                    pV: Binding(
                                        get: { self.t_currentConf.ARSession_settings[k]! },
                                        set: { self.t_currentConf.ARSession_settings[k] = $0 }
                                    ),
                                    updateView: updateView
                                )
                                /*if (self.t_currentConf.ARSession_settings[k]!.enabled) {Card(k: k, pV: self.t_currentConf.ARSession_settings[k]!, updateView: updateView)}*/
                            }.padding(.all, 10)
                        }
                    }
                }
                //CameraStream
                //title
                ZStack{
                    Color.red.opacity(0.1)
                    VStack{
                        Text(Cat.CameraStream.rawValue)
                    }.padding(.all, 10)
                }
                //general enabled
                ZStack{
                    Color.gray.opacity(0.1)
                    VStack{
                        Toggle(Cat.CameraStream.rawValue, isOn: Binding(
                            get: {self.t_currentConf.CameraStream},
                            set: {
                                self.t_currentConf.CameraStream = $0
                                if ($0) {self.t_currentConf.ARSession = !$0}
                                updateView()
                            }
                        ))
                    }.padding(.all, 10)
                }
                
                
                
            }
            
            
            Divider()
            HStack{
                if let listOfSettings = listOfFilesURL(path: [Model.shared.settingDir]) {
                    HStack{
                        Button(action: {show_ModalSelectConf = true}){
                            HStack{
                                Image(systemName: "square.and.arrow.up.fill")
                                Text("Load")
                            }
                            
                        }.disabled(listOfSettings.count == 0)
                        
                        //Button("load configuration"){show_ModalSelectConf = true}.buttonStyle(.bordered).disabled(listOfSettings.count == 0)
                        
                        //Text("Available configurations: \(listOfSettings.count)")
                        if (name != "") {
                            Text("Loaded: \(name)")
                        }
                    }
                    
                } else {
                    Text("error while reading \(Model.shared.settingDir) directory")
                    
                }
                Spacer()
                Button(action: {show_ModalSaveConf = true}){
                    HStack{
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Save")
                    }
                    
                }.buttonStyle(.borderedProminent)
                //Button("save configuration"){show_ModalSaveConf = true}.buttonStyle(.borderedProminent)
            }
            
            
                
            Text("\(self.refresh)").foregroundStyle(.white)
            //.containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 10)
            
        }
        .padding(.all, 10)
        .sheet(isPresented: $show_ModalSelectConf) {
            ModalSelectConf(showingOverlay: $show_ModalSelectConf, listOfSettings: listOfFilesURL(path: [Model.shared.settingDir])!,loadConf: loadConf)
        }
        .sheet(isPresented: $show_ModalSaveConf) {
            ModalSaveConf(showingOverlay: $show_ModalSaveConf, name: $name, saveConf: saveConf)
        }
    }
}

/*struct Card: View {
    var k: DataTypes
    var pV: DataType
    let updateView: () -> Void
    
    var body: some View {
        VStack{
            
            HStack{
                Text("basePriority (ms)").containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: 0)
                TextField(
                    "basePriority",
                    value: Binding(get: {pV.basePriority}, set: {pV.basePriority = $0}),
                    format: .number
                )
                .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("priorityIncrement (ms)").containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: 0)
                TextField(
                    "priorityIncrement",
                    value: Binding(get: {pV.priorityIncrement}, set: {pV.priorityIncrement = $0}),
                    format: .number
                )
                .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
            }
            
            HStack{
                Text("queuePolicy").containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: 0)
                Picker(
                    "queuePolicy",
                    selection: Binding(get: {pV.queuePolicy}, set: {
                        pV.queuePolicy = $0
                        updateView()
                    })
                ){
                    ForEach(QueuePolicy.allCases, id: \.self) { item in
                        Text(item.rawValue).tag(item)
                    }
                }.pickerStyle(.segmented)
            }
            
            if (pV.updateInterval != nil) {
                HStack {
                    Text("updateInterval (s)").containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: 0)
                    TextField(
                        "updateInterval",
                        value: Binding(get: {pV.updateInterval}, set: {pV.updateInterval = $0}),
                        format: .number
                    )
                    .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                }
            }
            
            
            

        }

    }
}*/

struct ModalSelectConf: View {
    @Binding var showingOverlay: Bool
    var listOfSettings: [URL]
    var loadConf: (URL) -> Void
    var body: some View {
        VStack {
            Text("load configuration:")
            .containerRelativeFrame(.vertical, count: 5, span: 1, spacing: 10)
            
            ScrollView(.vertical, showsIndicators: true){
                ForEach(listOfSettings, id: \.absoluteString){item in
                    Button(item.lastPathComponent){
                        loadConf(item)
                        showingOverlay = false
                    }.buttonStyle(.bordered)
                }
            }
            .containerRelativeFrame(.vertical, count: 5, span: 3, spacing: 10)
            
            Button("dismiss"){showingOverlay = false}
            .containerRelativeFrame(.vertical, count: 5, span: 1, spacing: 10)
        }
    }
}

struct ModalSaveConf: View {
    @Binding var showingOverlay: Bool
    @Binding var name: String
    var saveConf: () -> Void
    var body: some View {
        VStack {
            Text("configuration name")
            TextField("configuration name", text: $name).textFieldStyle(.roundedBorder)
            Button("save configuration"){
                saveConf()
                showingOverlay = false
            }.buttonStyle(.bordered)
        }.padding(.all, 10)
    }
}

struct Card2: View {
    var k: DataTypes
    @Binding var pV: DataType
    let updateView: () -> Void
    
    @State private var showingFreshestOnlyInfo = false
    @State private var showingPriorityInfo = false
    @State private var showingBasePriorityInfo = false
    @State private var showingPriorityIncrementInfo = false
    @State private var showingQueuePolicyInfo = false
    @State private var showingUpdateIntervalInfo = false
    
    @State private var showEditModal = false
    @State private var showingInfo = false
    @State private var infoText = ""
    
    var body: some View {
        return Button("edit"){showEditModal = true}.disabled(!pV.enabled)
        .sheet(isPresented: $showEditModal) {
            VStack{
                //Text("edit modal")
                //Button("printConf"){Model.shared.t_currentConf?.printC()}
                HStack{
                    Text("priority").containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: 0)
                    HStack{
                        Picker("priority", selection: Binding(
                            get: {PriorityLevel.get_priorityFromValues(bp: pV.basePriority, pi: pV.priorityIncrement)},
                            set: {
                                pV.basePriority = $0.get_basePriority() ?? -1
                                pV.priorityIncrement = $0.get_priorityIncrement() ?? -1
                                updateView()
                            }
                        )){
                            ForEach(PriorityLevel.allCases, id: \.self) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        Button(action: {
                            showingInfo = true
                            infoText = InfoText.priority.getText()
                        }){Image(systemName: "info.circle")}
                    }
                }
                HStack{
                    Text("basePriority (ms)")
                    HStack{
                        TextField(
                            "basePriority",
                            value: $pV.basePriority,
                            format: .number
                        )
                        .textFieldStyle(.roundedBorder).disabled(PriorityLevel.get_priorityFromValues(bp: pV.basePriority, pi: pV.priorityIncrement) != .personalized)
                        Button(action: {
                            showingInfo = true
                            infoText = InfoText.basePriority.getText()
                        }){Image(systemName: "info.circle")}
                    }
                }
                HStack{
                    Text("priorityIncrement (ms)")
                    HStack{
                        TextField(
                            "priorityIncrement",
                            value: $pV.priorityIncrement,
                            format: .number
                        )
                        .textFieldStyle(.roundedBorder).disabled(PriorityLevel.get_priorityFromValues(bp: pV.basePriority, pi: pV.priorityIncrement) != .personalized)
                        Button(action: {
                            showingInfo = true
                            infoText = InfoText.priorityIncrement.getText()
                        }){Image(systemName: "info.circle")}
                    }
                }
                /*HStack{
                    Text("priority").containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: 0)
                    VStack{
                        HStack{
                            Picker("priority", selection: Binding(
                                get: {PriorityLevel.get_priorityFromValues(bp: pV.basePriority, pi: pV.priorityIncrement)},
                                set: {
                                    pV.basePriority = $0.get_basePriority() ?? -1
                                    pV.priorityIncrement = $0.get_priorityIncrement() ?? -1
                                    updateView()
                                }
                            )){
                                ForEach(PriorityLevel.allCases, id: \.self) { item in
                                    Text(item.rawValue).tag(item)
                                }
                            }
                            Button(action: {
                                showingInfo = true
                                infoText = InfoText.priority.getText()
                            }){Image(systemName: "info.circle")}
                        }
                        Text("basePriority (ms)")
                        HStack{
                            TextField(
                                "basePriority",
                                value: $pV.basePriority,
                                format: .number
                            )
                            .keyboardType(.numberPad).textFieldStyle(.roundedBorder).disabled(PriorityLevel.get_priorityFromValues(bp: pV.basePriority, pi: pV.priorityIncrement) != .personalized)
                            Button(action: {
                                showingInfo = true
                                infoText = InfoText.basePriority.getText()
                            }){Image(systemName: "info.circle")}
                        }
                        Text("priorityIncrement (ms)")
                        HStack{
                            TextField(
                                "priorityIncrement",
                                value: $pV.priorityIncrement,
                                format: .number
                            )
                            .keyboardType(.numberPad).textFieldStyle(.roundedBorder).disabled(PriorityLevel.get_priorityFromValues(bp: pV.basePriority, pi: pV.priorityIncrement) != .personalized)
                            Button(action: {
                                showingInfo = true
                                infoText = InfoText.priorityIncrement.getText()
                            }){Image(systemName: "info.circle")}
                        }
                    }
                }*/
                Divider().padding(.all, 10)
                HStack{
                    Text("queuePolicy").containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: 0)
                    HStack{
                        Picker("queuePolicy", selection: $pV.queuePolicy){
                            ForEach(QueuePolicy.allCases, id: \.self) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }.pickerStyle(.segmented)
                        Button(action: {
                            showingInfo = true
                            infoText = InfoText.queuePolicy.getText()
                        }){Image(systemName: "info.circle")}
                    }
                    
                }
                if (pV.updateInterval != nil) {
                    Divider().padding(.all, 10)
                    HStack {
                        Text("updateInterval (s)").containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: 0)
                        HStack{
                            TextField(
                                "updateInterval",
                                value: $pV.updateInterval,
                                format: .number
                            )
                            .textFieldStyle(.roundedBorder)
                            Button(action: {
                                showingInfo = true
                                infoText = InfoText.updateInterval.getText()
                            }){Image(systemName: "info.circle")}
                        }
                    }
                }
                if (pV.others != nil) {
                    
                    if pV.others!.contains(where: {$0.key==OtherKeys.FrameColor.rawValue}) {
                        Divider().padding(.all, 10)
                        HStack {
                            Text(OtherKeys.FrameColor.rawValue).containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: 0)
                            Picker(
                                OtherKeys.FrameColor.rawValue,
                                selection: Binding<String>(
                                    get: {pV.others![OtherKeys.FrameColor.rawValue] as! String},
                                    set: {
                                        pV.others![OtherKeys.FrameColor.rawValue] = $0
                                        updateView()
                                    }
                                )
                            ){
                                ForEach(FrameColor.allCases.map{$0.rawValue}, id: \.self) {Text($0).tag($0)}
                            }
                        }
                    }
                    //OtherKeys.PlaneDirection.rawValue
                    if pV.others!.contains(where: {$0.key==OtherKeys.PlaneDirection.rawValue}) {
                        Divider().padding(.all, 10)
                        HStack {
                            Text(OtherKeys.PlaneDirection.rawValue).containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: 0)
                            VStack {
                                let options = [
                                    ARWorldTrackingConfiguration.PlaneDetection.horizontal.rawValue,
                                    ARWorldTrackingConfiguration.PlaneDetection.vertical.rawValue
                                ].map{e in Int(e)}
                                ForEach(options, id: \.self) { option in
                                    var planeDirections = pV.others![OtherKeys.PlaneDirection.rawValue] as! [Int]
                                    let isContained = planeDirections.contains(option)
                                    Button(action: {
                                        if isContained {
                                            planeDirections.removeAll(where: { $0 == option})
                                        } else {
                                            planeDirections.append(option)
                                        }
                                        pV.others![OtherKeys.PlaneDirection.rawValue] = planeDirections
                                        updateView()
                                    }) {
                                        Label(UInt(option).planeDirection_StringDescription, systemImage: isContained ? "checkmark.square.fill" : "square")
                                    }.padding(.all, 10)
                                    //Text("\(option) \((pV.others![OtherKeys.PlaneDirection.rawValue] as! [Int]).contains(option))")
                                }
                            }
                        }
                    }
                }
            }.padding(.all, 10)
            .alert("info", isPresented: $showingInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(infoText)
            }
        }.padding(.all, 10)
    }
    
}
