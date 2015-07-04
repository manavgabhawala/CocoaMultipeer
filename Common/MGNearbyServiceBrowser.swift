//
//  MGNearbyServiceBrowser.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 05/07/15.
//
//

import Foundation


/** The MGNearbyServiceBrowserDelegate protocol defines methods that a MGNearbyServiceBrowser object’s delegate can implement to handle browser-related and invitation events.
*/
@objc public protocol MGNearbyServiceBrowserDelegate
{
	/// The browser object that failed to start browsing.
	/// - Parameter browser: The browser object that failed to start browsing.
	/// - Parameter error: An error object indicating what went wrong.
	optional func browser(browser: MGNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError)
	
	/// Called when a nearby peer is found. The peer ID provided to this delegate method can be used to invite the nearby peer to join a session.
	/// - Parameter browser: The browser object that found the nearby peer.
	/// - Parameter peerID: The unique ID of the peer that was found.
	/// - Parameter info: The info dictionary advertised by the discovered peer. For more information on the contents of this dictionary, see the documentation for `initWithPeer:discoveryInfo:serviceType:` in `MGNearbyServiceAdvertiser` Class Reference.
	func browser(browser: MGNearbyServiceBrowser, foundPeer peerID: MGPeerID, withDiscoveryInfo info: [String : String]?)
	
	/// Called when a nearby peer is lost. This callback informs your app that invitations can no longer be sent to a peer, and that your app should remove that peer from its user interface.
	/// - Parameter browser: The browser object that lost the nearby peer.
	/// - Parameter peerID: The unique ID of the nearby peer that was lost.
	func browser(browser: MGNearbyServiceBrowser, lostPeer peerID: MGPeerID)
	
	/// Called when an invitation to join a session is received from a nearby peer.
	/// - Parameter browser: The browser object that was invited to join the session.
	/// - Parameter peerID: The peer ID of the nearby peer that invited your app to join the session.
	/// - Parameter context: An arbitrary piece of data received from the nearby peer. This can be used to provide further information to the user about the nature of the invitation.
	/// - Parameter invitationHandler: A block that your code **must** call to indicate whether the advertiser should accept or decline the invitation, and to provide a session with which to associate the peer that sent the invitation.
	func browser(browser: MGNearbyServiceBrowser,
		didReceiveInvitationFromPeer peerID: MGPeerID,
		withContext context: NSData?, invitationHandler: (Bool, MGSession) -> Void)
}

/// Searches (by service type) for services offered by nearby devices using infrastructure Wi-Fi, peer-to-peer Wi-Fi, and Bluetooth, and provides the ability to easily invite those devices to a Cocoa Multipeer session (MGSession). The Browser class combines the advertiser and browser into a single class so invitations will also be sent to the browser.
@objc public class MGNearbyServiceBrowser
{
	/// The service type to browse for. (read-only)
	public let serviceType : String
	
	/// The local peer ID for this instance. (read-only)
	public let myPeerID : MGPeerID
	
	/// The `info` dictionary passed when this object was initialized. (read-only)
	public let discoveryInfo: [String: String]?
	
	/// The delegate object that handles browser-related events.
	public weak var delegate: MGNearbyServiceBrowserDelegate?
	
	/// Initializes the nearby service browser object.
	/// - Parameter peer: The local peer ID for this instance.
	/// - Parameter info: A dictionary of key-value pairs that are made available to browsers. Each key and value must be a String.
	/// This data is advertised using a Bonjour TXT record, encoded according to RFC 6763 (section 6). As a result:
	/// The key-value pair must be no longer than 255 bytes (total) when encoded in UTF-8 format with an equals sign (=) between the key and the value.
	/// Keys cannot contain an equals sign.
	/// For optimal performance, the total size of the keys and values in this dictionary should be no more than about 400 bytes so that the entire advertisement can fit within a single Bluetooth data packet. For details on the maximum allowable length, read Monitoring a Bonjour Service.
	/// - Parameter serviceType: Must be 1–15 characters long. Can contain only ASCII lowercase letters, numbers, and hyphens. This name should be easily distinguished from unrelated services. For example, a Foo app made by Bar company could use the service type `foo-bar`.
	public init(peer myPeerID: MGPeerID, discoveryInfo info: [String : String]?, serviceType: String)
	{
		self.serviceType = serviceType
		self.myPeerID = myPeerID
		self.discoveryInfo = info
	}
	
	/** Starts browsing for peers. After this method is called (until you call stopBrowsingForPeers), the framework calls your delegate's browser:foundPeer:withDiscoveryInfo: and browser:lostPeer: methods as new peers are found and lost. Also after starting browsing, other devices can discover your device until you call the stop browsing for peers method.
	*/
	public func startBrowsingForPeers()
	{
		
	}
	
	/** Stops browsing for peers.
	*/
	public func stopBrowsingForPeers()
	{
		
	}
	/// Invites a discovered peer to join a Cocoa Multipeer session.
	/// - Parameter peerID: The ID of the peer to invite.
	/// - Parameter session: The session you wish the invited peer to join.
	/// - Parameter context: An arbitrary piece of data that is passed to the nearby peer. This can be used to provide further information to the user about the nature of the invitation.
	/// - Parameter timeout: The amount of time to wait for the peer to respond to the invitation. This timeout is measured in seconds, and must be a positive value. If a negative value or zero is specified, the default timeout (30 seconds) is used.
	public func invitePeer(peerID: MGPeerID, toSession session: MGSession, withContext context: NSData?, var timeout: NSTimeInterval)
	{
		if timeout <= 0
		{
			timeout = 30
		}
	}
	
}