//
//  WaypointFormView.swift
//  Meshtastic
//
//  Copyright Garth Vander Houwen 1/10/23.
//

import SwiftUI
import CoreLocation

struct WaypointFormView: View {
	
	@EnvironmentObject var bleManager: BLEManager
	@Environment(\.dismiss) private var dismiss
	@State var coordinate: CLLocationCoordinate2D
	@State var id: Int = 0
	
	@FocusState private var iconIsFocused: Bool
	
	@State private var name: String = ""
	@State private var description: String = ""
	@State private var icon: String = "📍"
	@State private var expires: Bool = false
	@State private var expire: Date = Date() // = Date.now.addingTimeInterval(60 * 120) // 1 minute * 120 = 2 Hours
	@State private var locked: Bool = false
	
	var body: some View {
		Form {
			let distance = CLLocation(latitude: LocationHelper.currentLocation.latitude, longitude: LocationHelper.currentLocation.longitude).distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
			Section(header: Text((id > 0) ? "Editing Waypoint" : "Create Waypoint")) {
				HStack {
					Text("Location: \(String(format: "%.5f", coordinate.latitude ) + "," + String(format: "%.5f", coordinate.longitude ))")
						.textSelection(.enabled)
						.foregroundColor(Color.gray)
						.font(.caption2)
					if coordinate.latitude != LocationHelper.DefaultLocation.latitude && coordinate.longitude != LocationHelper.DefaultLocation.longitude {
						DistanceText(meters: distance)
							.foregroundColor(Color.gray)
							.font(.caption2)
					}
				}
				HStack {
					Text("Name")
					Spacer()
					TextField(
						"Name",
						text: $name,
						axis: .vertical
					)
					.foregroundColor(Color.gray)
					.onChange(of: name, perform: { value in
						let totalBytes = name.utf8.count
						// Only mess with the value if it is too big
						if totalBytes > 30 {
							let firstNBytes = Data(name.utf8.prefix(30))
							if let maxBytesString = String(data: firstNBytes, encoding: String.Encoding.utf8) {
								// Set the name back to the last place where it was the right size
								name = maxBytesString
							}
						}
					})
				}
				HStack {
					Text("Description")
					Spacer()
					TextField(
						"Description",
						text: $description,
						axis: .vertical
					)
					.foregroundColor(Color.gray)
					.onChange(of: description, perform: { value in
						let totalBytes = description.utf8.count
						// Only mess with the value if it is too big
						if totalBytes > 100 {
							let firstNBytes = Data(description.utf8.prefix(100))
							if let maxBytesString = String(data: firstNBytes, encoding: String.Encoding.utf8) {
								// Set the name back to the last place where it was the right size
								description = maxBytesString
							}
						}
					})
				}
				HStack {
					Text("Icon")
					Spacer()
					EmojiOnlyTextField(text: $icon, placeholder: "Select an emoji")
						.font(.title)
						.focused($iconIsFocused)
						.onChange(of: icon) { value in
							
							// If you have anything other than emojis in your string make it empty
							if !value.onlyEmojis() {
								icon = ""
							}
							// If a second emoji is entered delete the first one
							if value.count >= 1 {
								
								if value.count > 1 {
									let index = value.index(value.startIndex, offsetBy: 1)
									icon = String(value[index])
								}
								iconIsFocused = false
							}
						}
					
				}
				Toggle(isOn: $expires) {
					Label("Expires", systemImage: "clock.badge.xmark")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
				if expires {
					DatePicker("Expire", selection: $expire, in: Date.now...)
						.datePickerStyle(.compact)
						.font(.callout)
				}
				Toggle(isOn: $locked) {
					Label("Locked", systemImage: "lock")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
			}
		}
		HStack {
			Button {

				var newWaypoint = Waypoint()
				
				if id == 0 {

					newWaypoint.id = UInt32.random(in: UInt32(UInt8.max)..<UInt32.max)
				} else {
					newWaypoint.id = UInt32(id)
				}
				newWaypoint.name = name.count < 1 ? "Dropped Pin" : name
				newWaypoint.description_p = description
				newWaypoint.latitudeI = Int32(coordinate.latitude * 1e7)
				newWaypoint.longitudeI = Int32(coordinate.longitude * 1e7)
				// Unicode scalar value for the icon emoji string
				let unicodeScalers = icon.unicodeScalars
				// First element as an UInt32
				let unicode = unicodeScalers[unicodeScalers.startIndex].value
				newWaypoint.icon = unicode
				if locked {
					newWaypoint.lockedTo = UInt32(bleManager.connectedPeripheral!.num)
				}
				if expire.timeIntervalSince1970 > 0 {
					newWaypoint.expire = UInt32(expire.timeIntervalSince1970)
				}
				if bleManager.sendWaypoint(waypoint: newWaypoint) {
					id = 0
					name = ""
					description = ""
					locked = false
					expires = false
					expire = Date.now.addingTimeInterval(60 * 120)
					icon = "📍"
					dismiss()
					
				} else {
					
				}
			} label: {
				Label("Send", systemImage: "arrow.up")
			}
			.buttonStyle(.bordered)
			.buttonBorderShape(.capsule)
			.controlSize(.large)
			.disabled(bleManager.connectedPeripheral == nil)
			.padding()
			
			Button {
				dismiss()
			} label: {
				Label("cancel", systemImage: "xmark")
			}
			.buttonStyle(.bordered)
			.buttonBorderShape(.capsule)
			.controlSize(.large)
			.padding()
		}
		.onAppear {
			if id > 0 {
				let waypoint  = getWaypoint(id: Int64(id), context: bleManager.context!)
				id = Int(waypoint.id)
				name = waypoint.name ?? "Dropped Pin"
				description = waypoint.longDescription ?? ""
				icon = String(UnicodeScalar(Int(waypoint.icon)) ?? "📍")
				if waypoint.expire != nil {
					expires = true
					expire = waypoint.expire ?? Date()
				} else {
					expires = false
				}
			}
		}
	}
}
