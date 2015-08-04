//
//  MGSessionDelegate.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 04/08/15.
//
//

import Foundation

/// The MGSessionDelegate protocol defines methods that a delegate of the MGSession class can implement to handle session-related events. For more information, see MGSession Class Reference.
@objc public protocol MGSessionDelegate
{
	///  Called when the state of a nearby peer changes. There are no guarantees about which thread this will be called on.
	///
	///  - Parameter session: The session that manages the nearby peer whose state changed.
	///  - Parameter peerID:  The ID of the nearby peer whose state changed.
	///  - Parameter state:   The new state of the nearby peer.
	///
	optional func session(session: MGSession, peer peerID: MGPeerID, didChangeState state: MGSessionState)
	
	///  Indicates that an NSData object has been received from a nearby peer. You can be assured that this will be called on the main thread.
	///
	///  - Parameter session: The session through which the data was received.
	///  - Parameter data:    An object containing the received data.
	///  - Parameter peerID:  The peer ID of the sender.
	optional func session(session: MGSession, didReceiveData data: NSData, fromPeer peerID: MGPeerID)
}
