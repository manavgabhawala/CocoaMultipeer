//
//  MGPeerID.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 05/07/15.
//
//

import Foundation

/// The MGPeerID class represents a peer in a multipeer session.
/// The Cocoa Multipeer framework is responsible for creating peer objects that represent other devices. Your app is responsible for creating a single peer object that represents the instance of your app that is running on the local device.
///  To create a new peer ID for the local app and associate a display name with that ID, call initWithDisplayName:. The peer’s name must be no longer than 63 bytes in UTF-8 encoding.
@objc public class MGPeerID: NSObject
{
	internal var name: String?
	{
		didSet
		{
			MGDebugLog("Updated the peer's name to \(name) from \(oldValue)")
		}
	}
	
	/// The display name for this peer. (read-only). If you passed nil into the initalizer this will be an empty string until the framework sets everything up and assigns a name to the Peer. In order to track this property try accessing it after 
	/// For other peer objects provided to you by the framework, this property is provided by the peer and cannot be changed.
	@objc public var displayName: String
	{
		return name ?? ""
	}
	
	/// Initializes a peer.
	/// - Parameter displayName: The display name for the local peer. If you use the multipeer browser view controller, this name is shown.
	/// The display name is intended for use in UI elements, and should be short and descriptive of the local peer. The maximum allowable length is 63 bytes in UTF-8 encoding. The displayName parameter may be nil, if it is nil the framework will assign a name for you based on the device's name set by the user. Until the name is assgined the name returned by the `displayName` paramter will be an empty String.
	/// - Returns: Returns an initialized object.
	@objc public init(displayName: String? = nil)
	{
		name = displayName
	}
}
// MARK: - CustomStringConvertible
extension MGPeerID
{
	public override var description : String { return displayName }
}
// MARK: - Hashable
extension MGPeerID
{
	public override var hashValue: Int { return displayName.hashValue }
}
// MARK: - Equatable
public func ==(lhs: MGPeerID, rhs: MGPeerID) -> Bool
{
	return lhs.name == rhs.name
}
