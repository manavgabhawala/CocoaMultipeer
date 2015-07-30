//
//  MGNearbyServiceBrowserDelegate.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 25/07/15.
//
//

import Foundation


/** The MGNearbyServiceBrowserDelegate protocol defines methods that a MGNearbyServiceBrowser object’s delegate can implement to handle browser-related and invitation events. Since all activity is asynchronous in nature, you cannot make any assumptions of the thread on which the delegate's methods will be called.
*/
@objc public protocol MGNearbyServiceBrowserDelegate
{
	/// The browser object that failed to start browsing.
	/// - Parameter browser: The browser object that failed to start browsing.
	/// - Parameter error: An error object indicating what went wrong.
	optional func browser(browser: MGNearbyServiceBrowser, didNotStartBrowsingForPeers error: [String: NSNumber])
	
	///  The browser object that started browsing. Track this property if you passed nil to the local peer ID's name. The assigned name will now be available through the `myPeerID` property of the browser.
	///
	///  - Parameter browser: The browser object that started browsing and who resolved the local peer's name.
	///
	optional func browserDidStartSuccessfully(browser: MGNearbyServiceBrowser)
	
	/// Called when a nearby peer is found. The peer ID provided to this delegate method can be used to invite the nearby peer to join a session.
	/// - Parameter browser: The browser object that found the nearby peer.
	/// - Parameter peerID: The unique ID of the peer that was found.
	/// - Parameter info: The info dictionary advertised by the discovered peer. For more information on the contents of this dictionary, see the documentation for `initWithPeer:discoveryInfo:serviceType:` in `MGNearbyServiceAdvertiser` Class Reference.
	func browser(browser: MGNearbyServiceBrowser, foundPeer peerID: MGPeerID, withDiscoveryInfo info: [String : String]?)
	
	/// Called when a nearby peer is lost. This callback informs your app that invitations can no longer be sent to a peer, and that your app should remove that peer from its user interface.
	/// - Parameter browser: The browser object that lost the nearby peer.
	/// - Parameter peerID: The unique ID of the nearby peer that was lost.
	func browser(browser: MGNearbyServiceBrowser, lostPeer peerID: MGPeerID)
	
	/// Called when a nearby peer's discovery info is updated. The peer has already been discovered and the peer ID provided to this delegate method can be used to invite the nearby peer to join a session.
	/// - Parameter browser: The browser object that updated the nearby peer.
	/// - Parameter peerID: The unique ID of the peer that was updated.
	/// - Parameter info: The info dictionary advertised by the discovered peer. For more information on the contents of this dictionary, see the documentation for `initWithPeer:discoveryInfo:serviceType:` in `MGNearbyServiceAdvertiser` Class Reference.
	optional func browser(browser: MGNearbyServiceBrowser, didUpdatePeer peerID: MGPeerID, withDiscoveryInfo: [String: String]?)
	
	/// Called when a nearby peer could not be resolved. The peer could not be resolved and you probably cannot connect to this peer. Handle the error appropriately.
	/// - Parameter browser: The browser object that updated the nearby peer.
	/// - Parameter peerID: The unique ID of the peer that was updated.
	/// - Parameter errorDict: The error dictionary giving reason as to why the peer could not be resolved.
	optional func browser(browser: MGNearbyServiceBrowser, couldNotResolvePeer peerID: MGPeerID, withError errorDict: [String: NSNumber])
	
	/// Called when an invitation to join a session is received from a nearby peer.
	/// - Parameter browser: The browser object that was invited to join the session.
	/// - Parameter peerID: The peer ID of the nearby peer that invited your app to join the session.
	/// - Parameter context: An arbitrary piece of data received from the nearby peer. This can be used to provide further information to the user about the nature of the invitation.
	/// - Parameter invitationHandler: A block that your code **must** call to indicate whether the advertiser should accept or decline the invitation, and to provide a session with which to associate the peer that sent the invitation.
	func browser(browser: MGNearbyServiceBrowser, didReceiveInvitationFromPeer peerID: MGPeerID, invitationHandler: (Bool, MGSession) -> Void)
}