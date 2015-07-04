//
//  MGSession.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 05/07/15.
//
//

import Foundation

/**
#### Abstract
A MGSession facilitates communication among all peers in a multipeer
session.

#### Discussion

To start a multipeer session with remote peers, a MGPeerID that
represents the local peer needs to be supplied to the init method.

Once a peer is added to the session on both sides, the delegate
callback -session:peer:didChangeState: will be called with
MGSessionStateConnected state for the remote peer.

Data messages can be sent to a connected peer with the -sendData:
toPeers:withMode:error: method.

The receiver of data messages will receive a delegate callback
-session:didReceiveData:fromPeer:.

Resources referenced by NSURL (e.g. a file) can be sent to a connected
peer with the -sendResourceAtURL:toPeer:withTimeout:completionHandler:
method. The completionHandler will be called when the resource is fully
received by the remote peer, or if an error occurred during
transmission. The receiver of data messages will receive a delegate
callbacks -session:didStartReceivingResourceWithName:fromPeer:
withProgress: when it starts receiving the resource and -session:
didFinishReceivingResourceWithName:fromPeer:atURL:withError:
when the resource has been fully received.

A byte stream can be sent to a connected peer with the
-startStreamWithName:toPeer:error: method. On success, an
NSOutputStream  object is returned, and can be used to send bytes to
the remote peer once the stream is properly set up. The receiver of the
byte stream will receive a delegate callback -session:didReceiveStream:
withName:fromPeer:

Delegate calls occur on the main thread. If your app needs to
perform a long running action on a particular run loop or operation queue, its
delegate method should explicitly dispatch or schedule that work. Only small tasks and UI updates should exist in the delegate methods.
*/
@objc public class MGSession
{
	let localPeer: MGPeerID
	
	init(peer: MGPeerID)
	{
		localPeer = peer
	}
	func cancelConnectPeer(peerID: MGPeerID)
	{}
}
