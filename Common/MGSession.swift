//
//  MGSession.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 05/07/15.
//
//

import Foundation

/**
#### Abstract:
A MGSession facilitates communication among all peers in a multipeer
session.

#### Discussion:

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
	public var connectedPeers: [MGPeerID]
	{
		var connectedPeers = [MGPeerID]()
		connectedPeers.reserveCapacity(peers.count)
		for peer in peers
		{
			guard peer.state == .Connected
			else
			{
				continue
			}
			connectedPeers.append(peer.peer)
		}
		return connectedPeers
	}
	
	/// An array of a tuple of all the values needed for a proper connection to a peer.
	internal var peers = [(peer: MGPeerID, state: MGSessionState, input: NSInputStream, output: NSOutputStream, writeLock: NSCondition)]()
	
	/// This property determines how much data is written/read at a time.
	internal static let packetSize : Int = 255
	
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
	
	/// Sends a message encapsulated in an NSData object to nearby peers. For best results keep the NSData size to 255 bytes. However, larger instances are supported, but handling recieivng this larger data is left up to you. See the delegate's `session:didRecieveData:fromPeer` method. 
	///
	/// - Warning: This method blocks for very very large NSData instances, for such cases do not call this method on the main thread, otherwise calling it on the main thread is fine. In general, we move the data into packets on the thread that this method is called on but send data over the network on a background thread. If you think the copying is going to be an expensive operation dispatch this on a concurrent/serial background queue using Grand Central Dispatch.
	///
	///  - Parameter data:    An object containing the message to send.
	///  - Parameter peerIDs: An array of peer ID objects representing the peers that should receive the message.
	///  - Throws: MultipeerError.NotConnected error if you are attempting to send data to a peer that is not connected. Try checking the status of the peer again, reestablishing the connection by allowing the user to reinvite the lost device.
	///  - SeeAlso: `session:didRecieveData:fromPeer`
	public func sendData(data: NSData, toPeers peerIDs: [MGPeerID]) throws
	{
		guard data.length > 0
		else
		{
			// If there is no data to write why bother wasting time early exit.
			return
		}
		// First lets setup our packets.
		var packet = [UInt8]()
		packet.reserveCapacity(MGSession.packetSize)
		var packets = Array<[UInt8]>()
		let numberOfPackets = Int(ceil(Double(data.length) / Double(MGSession.packetSize)))
		packets.reserveCapacity(numberOfPackets)
		for i in 0..<numberOfPackets
		{
			let location = i * MGSession.packetSize
			let range: NSRange
			// Push as much of data as possible onto a single packet
			if data.length < location + MGSession.packetSize
			{
				range = NSRange(location: location, length: data.length - location)
			}
			else
			{
				range = NSRange(location: location, length: MGSession.packetSize)
			}
			var bytes = UnsafePointer<UInt8>(data.bytes).advancedBy(range.location)
			if range.length < packet.count
			{
				// Only empty the packet so that we don't get bad data if the new data we are writing has a shorter length than the exisiting data. Otherwise we just overwrite the data. This is a nifty little speed optimization to reduce memory allocations.
				packet.removeAll(keepCapacity: true)
			}
			for j in 0..<range.length
			{
				if j >= packet.count
				{
					packet.append(bytes.memory)
				}
				else
				{
					packet[j] = bytes.memory
				}
				bytes = bytes.successor()
			}
		}
		for (i, peer) in peers.filter({ peerIDs.contains($0.peer) }).enumerate()
		{
			guard (peer.state == .Connected)
			else
			{
				throw MultipeerError.NotConnected
			}
			
			// Send the packet in the background while we continue creating the other packets and also sending to the other peers.
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
				guard peer.state == .Connected
				else
				{
					self.lostPeer(i)
					return
				}
				peer.writeLock.lock()
				while !peer.output.hasSpaceAvailable
				{
					peer.writeLock.wait()
				}
				defer
				{
					peer.writeLock.unlock()
				}
				// Now we know there is space on the outputStream so write to it.
				let len = peer.output.write(&packet, maxLength: packet.count)
				
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
	
	///  Sets up an initial connection to the peer.
	///
	///  - parameter peer:         The peer to whom a connection is being established.
	///  - parameter inputStream:  The inputStream over which data can be recieved.
	///  - parameter outputStream: The outputStream over which data can be sent.
	///
	///  - throws: Throws a ConnectionAttemptFailed if there are too many connected peers.
	internal func initialConnectToPeer(peer: MGPeerID, inputStream: NSInputStream, outputStream: NSOutputStream) throws
	{
		guard peers.count < MGSession.maximumAllowedPeers
		else
		{
			throw MultipeerError.ConnectionAttemptFailed
		}
		peers.append((peer: peer, state: .Connecting, input: inputStream, output: outputStream, writeLock: NSCondition()))
		delegate?.session?(self, peer: peer, didChangeState: .Connecting)
		NSNotificationCenter.defaultCenter().postNotificationName(MGSession.sessionPeerStateUpdatedNotification, object: self)
	}
	
	///  Finalizes the connection to the peer.
	///
	///  - parameter peer: The peer to which the connection is now open.
	///  - throws: Throws a PeerNotFound error if the peer doesn't exist or a connection attempt failed if the peer's streams aren't alive.
	internal func finalizeConnectionToPeer(peer: MGPeerID) throws
	{
		guard let index = peers.indexOf( { $0.peer == peer })
		else
		{
			throw MultipeerError.PeerNotFound
		}
		guard peers[index].output.isAlive && peers[index].input.isAlive
		else
		{
			throw MultipeerError.ConnectionAttemptFailed
		}
		peers[index].input.delegate = self
		peers[index].output.delegate = self
		peers[index].state = .Connected
		delegate?.session?(self, peer: peers[index].peer, didChangeState: peers[index].state)
		NSNotificationCenter.defaultCenter().postNotificationName(MGSession.sessionPeerStateUpdatedNotification, object: self)
	}
	
	///  Rejects the connection to the peer.
	///
	///  - parameter peer: The peer to reject the connection to.
	///  - throws: A peer not found error if the peer passed couldn't be found.
	internal func rejectConnectionToPeer(peer: MGPeerID) throws
	{
		guard let index = peers.indexOf( { $0.peer == peer })
		else
		{
			throw MultipeerError.PeerNotFound
		}
		lostPeer(index)
	}
	
	///  Disconnects the remote peer from the session. Usually, you would call this on the server and not the client. See `disconnect` for client side disconnects.
	///
	///  - Parameter peer: The peer to disconnect from the server.
	///  - Throws: A `MultipeerError.PeerNotFound` error if the peer doesn't exist in the list of peers returned by `connectedPeers`.
	public func disconnectFromPeer(peer: MGPeerID) throws
	{
		guard let index = peers.indexOf({ $0.peer == peer })
		else
		{
			throw MultipeerError.PeerNotFound
		}
		lostPeer(index)
	}
	
	///  Disconnects the local peer from the session. This will close all connections on the `peer` whether its acting as a client or a server.
	public func disconnect()
	{
		for i in 0..<peers.count
		{
			lostPeer(i)
		}
		peers.removeAll()
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
			MGDebugLog("Session's stream completed opening. Ignoring notification.")
			break
		case NSStreamEvent.HasBytesAvailable:
			streamHasBytes(aStream)
			break
		case NSStreamEvent.HasSpaceAvailable:
			streamHasSpace(aStream)
			break
		case NSStreamEvent.ErrorOccurred, NSStreamEvent.EndEncountered:
			MGLog("Stream error: \(aStream.streamError)")
			MGDebugLog("A stream error occurred on \(aStream) with error \(aStream.streamError) with status \(aStream.streamStatus)")
			streamEncounteredEnd(aStream)
			break
		case NSStreamEvent.None:
			MGDebugLog("Stream status \(aStream.streamStatus)") // Who knows what is happening here.
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
			buf.reserveCapacity(MGSession.packetSize)
			var len = 0
			while inputStream.hasBytesAvailable
			{
				len = inputStream.read(&buf, maxLength: MGSession.packetSize)
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
				self.delegate?.session?(self, didReceiveData: data, fromPeer: peer.peer)
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
		guard let index = peers.indexOf({ $0.output == stream || $0.input == stream })
		else
		{
			fatalError("Could not find the peer whose stream died. Invalid state.")
		}
		lostPeer(index)
	}
	private func lostPeer(peerIndex: Int)
	{
		guard peerIndex >= 0 && peers.count > peerIndex
		else
		{
			return
		}
		peers[peerIndex].input.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
		peers[peerIndex].output.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
		peers[peerIndex].input.close()
		peers[peerIndex].output.close()
		peers[peerIndex].state = .NotConnected
		delegate?.session?(self, peer: peers[peerIndex].peer, didChangeState: peers[peerIndex].state)
		NSNotificationCenter.defaultCenter().postNotificationName(MGSession.sessionPeerStateUpdatedNotification, object: self)
		peers.removeAtIndex(peerIndex)
	}
}
extension MGSession
{
	public override var description: String { return "Session for \(myPeerID) connected to \(connectedPeers)" }
}