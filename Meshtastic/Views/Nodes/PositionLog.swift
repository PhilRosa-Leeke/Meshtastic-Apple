//
//  LocationHistory.swift
//  Meshtastic
//
//  Copyright(c) Garth Vander Houwen 7/5/22.
//
import SwiftUI

struct PositionLog: View {
	
	@Environment(\.managedObjectContext) var context
	@EnvironmentObject var bleManager: BLEManager
	
	@State var isExporting = false
	@State var exportString = ""
	
	var node: NodeInfoEntity
	
	@State private var isPresentingClearLogConfirm = false

	var body: some View {
		
		NavigationStack {
			let localeDateFormat = DateFormatter.dateFormat(fromTemplate: "yyMMddjmma", options: 0, locale: Locale.current)
			let dateFormatString = (localeDateFormat ?? "MM/dd/YY j:mma")
						
			if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac {
				//Add a table for mac and ipad
				Table(node.positions!.reversed() as! [PositionEntity]) {
					TableColumn("SeqNo") { position in
						Text(String(position.seqNo))
					}
					TableColumn("Latitude") { position in
						Text(String(format: "%.5f", position.latitude ?? 0))
					}
					TableColumn("Longitude") { position in
						Text(String(format: "%.5f", position.longitude ?? 0))
					}
					TableColumn("Altitude") { position in
						Text(String(position.altitude))
					}
					TableColumn("Sats") { position in
						Text(String(position.satsInView))
					}
					TableColumn("Speed") { position in
						Text(String(position.speed))
					}
					TableColumn("Heading") { position in
						Text(String(position.heading))
					}
					TableColumn("SNR") { position in
						Text("\(String(format: "%.2f", position.snr)) dB")
					}
					TableColumn("Time Stamp") { position in
						Text(position.time?.formattedDate(format: dateFormatString) ?? NSLocalizedString("unknown.age", comment: ""))
					}
				}
				
			} else {
				
				ScrollView {
					// Use a grid on iOS as a table only shows a single column
					let columns = [
						GridItem(spacing: 0.1),
						GridItem(spacing: 0.1),
						GridItem(.flexible(minimum: 35, maximum: 40), spacing: 0.1),
						GridItem(.flexible(minimum: 30, maximum: 35), spacing: 0.1),
						GridItem(spacing: 0)
					]
					LazyVGrid(columns: columns, alignment: .leading, spacing: 1) {
						
						GridRow {
							
							Text("Latitude")
								.font(.caption2)
								.fontWeight(.bold)
							Text("Longitude")
								.font(.caption2)
								.fontWeight(.bold)
							Text("Sats")
								.font(.caption2)
								.fontWeight(.bold)
							Text("Alt")
								.font(.caption2)
								.fontWeight(.bold)
							Text("timestamp")
								.font(.caption2)
								.fontWeight(.bold)
						}
						ForEach(node.positions!.reversed() as! [PositionEntity], id: \.self) { (mappin: PositionEntity) in
							GridRow {
								Text(String(format: "%.5f", mappin.latitude ?? 0))
									.font(.caption2)
								Text(String(format: "%.5f", mappin.longitude ?? 0))
									.font(.caption2)
								Text(String(mappin.satsInView))
									.font(.caption2)
								Text(String(mappin.altitude))
									.font(.caption2)
								Text(mappin.time?.formattedDate(format: dateFormatString) ?? "Unknown time")
									.font(.caption2)
							}
						}
					}
				}
				.padding(.leading)
			}

			HStack {

				Button(role: .destructive) {
					isPresentingClearLogConfirm = true
				} label: {
					Label("Clear Log", systemImage: "trash.fill")
				}
				.buttonStyle(.bordered)
				.buttonBorderShape(.capsule)
				.controlSize(.large)
				.padding()
				.confirmationDialog(
					"are.you.sure",
					isPresented: $isPresentingClearLogConfirm,
					titleVisibility: .visible
				) {
					Button("Delete all positions?", role: .destructive) {
						if clearPositions(destNum: node.num, context: context) {
							print("Successfully Cleared Position Log")
							
						} else {
							print("Clear Position Log Failed")
						}
					}
				}
				
				Button {
								
					exportString = PositionToCsvFile(positions: node.positions!.array as! [PositionEntity])
					isExporting = true
					
					} label: {
						
						Label("save", systemImage: "square.and.arrow.down")
					}
					.buttonStyle(.bordered)
					.buttonBorderShape(.capsule)
					.controlSize(.large)
					.padding()
				}
				.fileExporter(
				isPresented: $isExporting,
				document: CsvDocument(emptyCsv: exportString),
				contentType: .commaSeparatedText,
				defaultFilename: String("\(node.user?.longName ?? "Node") Position Log"),
				onCompletion: { result in

					if case .success = result {
						
						print("Position log download succeeded.")
						self.isExporting = false
						
					} else {
						
						print("Position log download failed: \(result).")
					}
				}
			)
		}
		.navigationTitle("Position Log \(node.positions?.count ?? 0) Points")
		.navigationBarItems(trailing:

			ZStack {

			ConnectedDevice(bluetoothOn: bleManager.isSwitchedOn, deviceConnected: bleManager.connectedPeripheral != nil, name: (bleManager.connectedPeripheral != nil) ? bleManager.connectedPeripheral.shortName : "????")
		})
		.onAppear {

			self.bleManager.context = context
		}
	}
}
