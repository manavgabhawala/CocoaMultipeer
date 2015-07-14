//
//  MGSession.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 05/07/15.
//
//

import Foundation

@objc public protocol MGSessionDelegate
{
	///  Called when the state of a nearby peer changes. There are no guarantees about which thread this will be called.
	///
	///  - Parameter session: The session that manages the nearby peer whose state changed.
	///  - Parameter peerID:  The ID of the nearby peer whose state changed.
	///  - Parameter state:   The new state of the nearby peer.
	///
	func session(session: MGSession, peer peerID: MGPeerID, didChangeState state: MGSessionState)
	
	///  Indicates that an NSData object has been received from a nearby peer. You can be assured that this will be called on the main queue.
	///
	///  - Parameter session: The session through which the data was received.
	///  - Parameter data:    An object containing the received data.
	///  - Parameter peerID:  The peer ID of the sender.
	func session(session: MGSession, didReceiveData data: NSData, fromPeer peerID: MGPeerID)
}

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
@objc public class MGSession : NSObject
{
	/// The maximum number of peers that a session can support, including the local peer.
	public static var maximumAllowedPeers = 8
	/// The minimum number of peers that a session can support, including the local peer.
	public static var minimumAllowedPeers = 1
	
	internal static let sessionPeerStateUpdatedNotification = "SessionPeerStateUpdatedNotification"
	
	/// A local identifier that represents the device on which your app is currently running. (read-only)
	public let myPeerID: MGPeerID
	
	/// The delegate object that handles session-related events.
	public weak var delegate: MGSessionDelegate?
	
	/// An array of all peers that are currently connected to this session. (read-only)
	public var connectedPeers: [MGPeerID] { return peers.map { $0.peer } }
	
	private var peers = [(peer: MGPeerID, state: MGSessionState, input: NSInputStream, output: NSOutputStream, writeLock: NSCondition)]()
	
	// This property determines how much data is written/read at a time.
	private let packetSize : Int = 255
	
	
	///  Creates a Cocoa Multipeer session.
	///
	///  - Parameter peer: A local identifier that represents the device on which your app is currently running.
	///
	///  - Returns: Returns the initialized session object, or nil if an error occurs.
	public init(peer: MGPeerID)
	{
		myPeerID = peer
		peers = [(peer: MGPeerID, state: MGSessionState, input: NSInputStream, output: NSOutputStream, writeLock: NSCondition)]()
	}
	
	///  Sends a message encapsulated in an NSData object to nearby peers. For best results keep the NSData size to 255 bytes. However, larger instances are supported, but handling this larger data being recieved is left up to you. See the delegate's `session:didRecieveData:fromPeer` method. This method only blocks for very very large NSData instances, for such cases do not call this method on the main thread, otherwise calling it on the main thread is fine.
	///
	///  - Parameter data:    An object containing the message to send.
	///  - Parameter peerIDs: An array of peer ID objects representing the peers that should receive the message.
	public func sendData(data: NSData, toPeers peerIDs: [MGPeerID]) throws
	{
		for peer in peers.filter({ peerIDs.contains($0.peer) })
		{
			guard (peer.state == .Connected)
			else
			{
				throw MultipeerError.NotConnected
			}
			// First lets setup our packets.
			var packet = [UInt8]()
			packet.reserveCapacity(self.packetSize)
			let packets = Array(count: data.length / self.packetSize, repeatedValue: packet)
			for (i, var packet) in packets.enumerate()
			{
				let location = i * packetSize
				let range: NSRange
				// Push as much of data as possible onto a single packet
				if data.length < location + packetSize
				{
					range = NSRange(location: location, length: data.length - location)
				}
				else
				{
					range = NSRange(location: location, length: packetSize)
				}
				data.getBytes(&packet, range: range)
				if packet.count == 0
				{
					var bytes = UnsafePointer<UInt8>(data.bytes)
					for _ in 0..<data.length
					{
						packet.append(bytes.memory)
						bytes = bytes.successor()
					}
				}
				// Send the packet in the background while we continue creating the other packets.
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
					peer.writeLock.lock()
					while !peer.output.hasSpaceAvailable
					{
						peer.writeLock.wait()
					}
					// Now we know there is space on the outputStream so write to it.
					let len = peer.output.write(&packet, maxLength: packet.count)
					peer.writeLock.unlock()
					// If no data could be written the connection was probably lost.
					guard len > 0
					else
					{
						try! self.disconnectFromPeer(peer.peer)
						return
					}
					// Guard against spuriously waking up other threads.
					guard peer.output.hasSpaceAvailable
					else { return }
					peer.writeLock.signal()
				})
			}
		}
	}
	
	internal func connectToPeer(peer: MGPeerID, inputStream: NSInputStream, outputStream: NSOutputStream)
	{
		assert(peers.count < MGSession.maximumAllowedPeers, "Attempting to add to many peers to the session. Currently, \(peers.count) peers exist. The maximum allowed number of peers is \(MGSession.maximumAllowedPeers)")
		
		inputStream.delegate = self
		inputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
		
		outputStream.delegate = self
		outputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
		
		peers.append((peer: peer, state: .Connecting, input: inputStream, output: outputStream, writeLock: NSCondition()))
		delegate?.session(self, peer: peer, didChangeState: .Connecting)
		
		inputStream.open()
		outputStream.open()
	}
	
	///  Use this function to introspect a peer and get its state.
	///
	///  - Parameter peer: The peer whose state is wanted.
	///
	///  - Returns: The state of the peer. See `MGSessionState`
	public func stateForPeer(peer: MGPeerID) throws -> MGSessionState
	{
		guard let index = peers.indexOf({ $0.peer == peer })
		else
		{
			throw MultipeerError.PeerNotFound
		}
		return peers[index].state
	}
	
	///  Disconnects the remote peer from the session. Usually, you would call this on the server and not the client. See `disconnect` for client side disconnects.
	///
	///  - Parameter peer: The peer to disconnect from the server.
	public func disconnectFromPeer(peer: MGPeerID) throws
	{
		guard let index = peers.indexOf({ $0.peer == peer })
		else
		{
			throw MultipeerError.PeerNotFound
		}
		lostPeer(index)
	}
	
	///  Disconnects the local peer from the session.
	public func disconnect()
	{
		for i in 0..<peers.count
		{
			lostPeer(i)
		}
		guard peers.count != 0
		else
		{
			return
		}
		disconnect()
	}
}
// MARK: - Stream handlers.
extension MGSession : NSStreamDelegate
{
	public func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent)
	{
		switch eventCode
		{
		case NSStreamEvent.OpenCompleted:
			streamCompletedOpening(aStream)
			break
		case NSStreamEvent.HasBytesAvailable:
			streamHasBytes(aStream)
			break
		case NSStreamEvent.HasSpaceAvailable:
			streamHasSpace(aStream)
			break
		case NSStreamEvent.ErrorOccurred, NSStreamEvent.EndEncountered:
			print("Stream error \(aStream.streamError)")
			streamEncounteredEnd(aStream)
			break
		case NSStreamEvent.None:
			print("Stream status \(aStream.streamStatus)") // Who knows what is happening here.
			assertionFailure("Debugging a None stream event.")
			break
		default:
			break
		}
	}
}
// MARK: - Private helpers
extension MGSession
{
	private func streamCompletedOpening(stream: NSStream)
	{
		for var peer in peers
		{
			guard stream == peer.input || stream == peer.output
			else { continue }
			if (peer.input.streamStatus == .Open || peer.input.streamStatus == .Reading) &&
				(peer.output.streamStatus == .Open || peer.output.streamStatus == .Writing)
			{
				peer.state = .Connected
				delegate?.session(self, peer: peer.peer, didChangeState: peer.state)
				NSNotificationCenter.defaultCenter().postNotificationName(MGSession.sessionPeerStateUpdatedNotification, object: self, userInfo: nil)
				return
			}
		}
		assertionFailure("Could not find the peer whose stream was opened. Invalid state.")
	}
	private func streamHasBytes(stream: NSStream)
	{
		guard let inputStream = stream as? NSInputStream
		else { fatalError("We expect only input streams to have bytes.") }
		for (i, peer) in peers.enumerate()
		{
			guard inputStream == peer.input
			else
			{
				continue
			}
			let data = NSMutableData()
			var buf = [UInt8]()
			buf.reserveCapacity(packetSize)
			var len = 0
			while inputStream.hasBytesAvailable
			{
				len = inputStream.read(&buf, maxLength: packetSize)
				if len > 0
				{
					data.appendBytes(buf, length: len)
				}
				else
				{
					lostPeer(i)
				}
			}
			dispatch_async(dispatch_get_main_queue(), {
				self.delegate?.session(self, didReceiveData: data, fromPeer: peer.peer)
			})
			return
		}
		assertionFailure("Could not find the peer whose stream data was read from. Invalid state.")
	}
	private func streamHasSpace(stream: NSStream)
	{
		guard let stream = stream as? NSOutputStream
		else { fatalError("We expected only the output stream to have space") }
		for peer in peers
		{
			guard peer.output == stream
			else { continue }
			peer.writeLock.signal() // Signal that there is space to write now.
			return
		}
		assertionFailure("Could not find the peer whose stream has space available. Invalid state.")
	}
	private func streamEncounteredEnd(stream: NSStream)
	{
		// Remote side died, tell the delegate that connection was lost.
		for (i, peer) in peers.enumerate()
		{
			guard stream == peer.output || stream == peer.input
			else { continue }
			lostPeer(i)
			return
		}
		assertionFailure("Could not find the peer whose stream died. Invalid state.")
	}
	private func lostPeer(peerIndex: Int)
	{
		if peers.count > peerIndex
		{
			peers[peerIndex].input.close()
			peers[peerIndex].output.close()
			peers[peerIndex].state = .NotConnected
			delegate?.session(self, peer: peers[peerIndex].peer, didChangeState: peers[peerIndex].state)
			NSNotificationCenter.defaultCenter().postNotificationName(MGSession.sessionPeerStateUpdatedNotification, object: self, userInfo: nil)
			peers.removeAtIndex(peerIndex)
		}
	}
}
extension MGSession
{
	public override var description: String { return "Session for \(myPeerID) connected to \(connectedPeers)" }
}