//
//  DeviceHome.swift
//  MeshtasticClient
//
//  Created by Garth Vander Houwen on 8/7/21.
//

// Abstract:
//  A view showing a list of devices that have been seen on the mesh network from the perspective of the connected device.

import SwiftUI

struct NodeList: View {
    @EnvironmentObject var bleManager: BLEManager
    @EnvironmentObject var meshData: MeshData
    
    @State private var showLocationOnly = false
    
    var filteredDevices: [NodeInfoModel] {
        meshData.nodes.filter { node in
            (!showLocationOnly || node.position.coordinate != nil)
        }
    }

    var body: some View {
        NavigationView {
           
            List {

                if meshData.nodes.count == 0 {
                    Text("Scan for Radios").font(.largeTitle).listRowSeparator(.hidden)
                    Text("No LoRa Mesh Nodes Found").font(.title2).listRowSeparator(.hidden)
                    Text("Go to the bluetooth section in the bottom right menu and click the Start Scanning button to scan for nearby radios and find your Meshtastic device. Make sure your device is powered on and near your phone or tablet.")
                        .font(.body)
                        .listRowSeparator(.hidden)
                    Text("Once the device shows under Available Devices touch the device you want to connect to and it will pull node information over BLE and populate the node list and mesh map in the Meshtastic app.")
                        .listRowSeparator(.hidden)
                    Text("Views with bluetooth functionality will show an indicator in the upper right hand corner show if bluetooth is on, and if a device is connected.")
                        .listRowSeparator(.hidden)
                    Spacer().listRowSeparator(.hidden)
                }
                else {
                    Toggle(isOn: $showLocationOnly) {
                        Text("Nodes with location only")
                    }
                    ForEach(filteredDevices.sorted(by: { $0.lastHeard > $1.lastHeard })) { node in
                        NavigationLink(destination: NodeDetail(node: node)) {
                            NodeRow(node: node, index : 0)
        
                        }
                        .swipeActions {
                            Button {
                                let nodeIndex = meshData.nodes.firstIndex(where: { $0.id == node.id })
                                meshData.nodes.remove(at: nodeIndex!)
                                meshData.save()
                            } label: {
                                VStack {
                                    Label("Delete from app", systemImage: "trash")
                                }
                            }
                            .tint(.red)
                        }
                    }
                }
             }
            .navigationTitle("All Nodes")
        }
        .ignoresSafeArea(.all, edges: [.leading, .trailing])
        .onAppear{
            meshData.load()
        }
    }
}

struct NodeList_Previews: PreviewProvider {
    static var previews: some View {
        NodeList()
            .environmentObject(MeshData())
    }
}