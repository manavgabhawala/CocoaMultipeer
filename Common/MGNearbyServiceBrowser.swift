//
//  MGNearbyServiceBrowser.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 05/07/15.
//
//

import Foundation

/// Searches (by service type) for services offered by nearby devices using infrastructure Wi-Fi, peer-to-peer Wi-Fi, and Bluetooth, and provides the ability to easily invite those devices to a Cocoa Multipeer session (MGSession). The Browser class combines the advertiser and browser into a single class so invitations will also be sent to the browser.
@objc public class MGNearbyServiceBrowser : NSObject
{
	private let server : NSNetService
	private let browser = NSNetServiceBrowser()
	private let fullServiceType: String
	private var availableServices = [NSNetService : MGPeerID]()
	
	/// The service type to browse for. (read-only)
	public let serviceType : String
	
	/// The local peer ID for this instance. (read-only)
	public let myPeerID : MGPeerID
	
	/// The info dictionary passed when this object was initialized. (read-only)
	public let discoveryInfo: [String : String]?
	
	/// The delegate object that handles browser-related events.
	public weak var delegate: MGNearbyServiceBrowserDelegate?
	
	private let delegateHelper : MGNearbyServiceBrowserHelper
	
	private var pendingInvites = [MGNearbyConnectionResolver]()
	
	/// Initializes the nearby service browser object with the TCP connection protocol.
	/// - Parameter peer: The local peer ID for this instance.
	/// - Parameter discoverInfo: A dictionary of key-value pairs that are made available to browsers. Each key and value must be an NSString object. This data is advertised using a Bonjour TXT record, encoded according to RFC 6763 (section 6). As a result: 
	///  	- The key-value pair must be no longer than 255 bytes (total) when encoded in UTF-8 format with an equals sign (=) between the key and the value.
	///  	- Keys cannot contain an equals sign.
	///  	- For optimal performance, the total size of the keys and values in this dictionary should be no more than about 400 bytes so that the entire advertisement can fit within a single Bluetooth data packet. For details on the maximum allowable length, read Monitoring a Bonjour Service.
	/// - Parameter serviceType: Must be 1–15 characters long. Can contain only ASCII lowercase letters, numbers, and hyphens. This name should be easily distinguished from unrelated services. For example, a Foo app made by Bar company could use the service type `foo-bar`.
	public init(peer myPeerID: MGPeerID, discoveryInfo: [String: String]? = nil, serviceType: String)
	{
		self.serviceType = serviceType
		self.myPeerID = myPeerID
		guard serviceType.characters.count >= 1 && serviceType.characters.count <= 15 && serviceType.lowercaseString == serviceType && !serviceType.characters.contains("_")
		else
		{
			fatalError("Service name size must be between 1 and 15 characters, can only contain ASCII lowercase letters, numbers and hyphens. Length recieved: \(serviceType.characters.count). String recieved: \(serviceType)")
		}
		self.fullServiceType = "_\(serviceType)._tcp"
		server = NSNetService(domain: "", type: fullServiceType, name: myPeerID.displayName, port: 0)
		self.discoveryInfo = discoveryInfo
		server.includesPeerToPeer = true
		browser.includesPeerToPeer = true
		
		delegateHelper = MGNearbyServiceBrowserHelper()
		
		super.init()
		
		updateTXTRecordDataForService(server)
		delegateHelper.ruler = self
		server.delegate = delegateHelper
		browser.delegate = delegateHelper
	}
	
	/// Starts browsing for peers. After this method is called (until you call `stopBrowsingForPeers`), the framework calls your delegate's `browser:foundPeer:withDiscoveryInfo:` and browser:lostPeer: methods as new peers are found and lost. After starting browsing, other devices can discover your device as a device that it can connect to until you call the stop browsing for peers method. However, if the device accepts a connection from another peer the `stopBrowsingForPeers` method is called automatically.
	public func startBrowsingForPeers()
	{
		server.stop()
		MGDebugLog("Attempting to start server")
		MGLog("Attempting to start server")
		server.startMonitoring()
		server.publishWithOptions(NSNetServiceOptions.ListenForConnections)
	}
	
	/// Stops browsing for peers. This will stop the delegate callbacks for discovering peers.
	public func stopBrowsingForPeers()
	{
		server.stop()
		browser.stop()
		server.stopMonitoring()
	}
	
	/// Invites a discovered peer to join a Cocoa Multipeer session.
	/// - Parameter peerID: The ID of the peer to invite.
	/// - Parameter session: The session you wish the invited peer to join.
	/// - Warning: This function makes no guarantees that a connection will be established to the peer even if the `browser:lostPeer:` method has not yet been called becuase the connection might have dropped between recieving this method call and making the connection request.
	/// - Throws: Multipeer.PeerNotFound error if the peer could not be found. To ensure this error is not thrown make sure you only pass in peers that you have recieved using the `delegate`'s `browser:foundPeer:withDiscoveryInfo:` method and the peer has not yet been sent to the `browser:lostPeer:` method. Throws a `ConnectionAttemptFailed` if the connection can't be established.
	public func invitePeer(peerID: MGPeerID, toSession session: MGSession) throws
	{
		var foundService : NSNetService?
		for (key, value) in availableServices
		{
			if value == peerID
			{
				foundService = key
				break
			}
		}
		guard let service = foundService
		else
		{
			throw MultipeerError.PeerNotFound
		}
		var input : NSInputStream?
		var output : NSOutputStream?
		let status = service.getInputStream(&input, outputStream: &output)
		guard status && input != nil && output != nil
		else
		{
			throw MultipeerError.ConnectionAttemptFailed
		}
		try session.initialConnectToPeer(peerID, inputStream: input!, outputStream: output!)
		let newInvite = MGNearbyConnectionResolver(ruler: self, inputStream: input!, outputStream: output!, remotePeer: peerID, session: session)
		pendingInvites.append(newInvite)
		MGLog("Inviting new peer to session")
		MGDebugLog("Inviting new peer \(peerID) to session \(session)")
		delegate?.browser(self, lostPeer: availableServices.removeValueForKey(service)!)
	}
}

// MARK: - NetService Callbacks
extension MGNearbyServiceBrowser
{
	private func netServiceDidPublish(sender: NSNetService)
	{
		assert(sender === server)
		MGLog("Server started")
		MGDebugLog("Server started and resolved name to \(sender.name)")
		myPeerID.name = sender.name
		browser.stop()
		MGDebugLog("Attempting to browse for nearby devices")
		browser.searchForServicesOfType(fullServiceType, inDomain: "")
		delegate?.browserDidStartSuccessfully?(self)
	}
	private func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber])
	{
		assert(sender === server)
		MGLog("Server could not start")
		MGDebugLog("Server could not start with error \(errorDict)")
		delegate?.browser?(self, didNotStartBrowsingForPeers: errorDict)
	}
	private func netServiceDidStop(sender: NSNetService)
	{
		MGDebugLog("Server stopped")
	}
	private func netServiceDidResolveAddress(sender: NSNetService)
	{
		guard let peer = availableServices[sender]
			else
		{
			let peer = MGPeerID(displayName: sender.name)
			availableServices[sender] = peer
			MGLog("Found new peer \(peer)")
			MGDebugLog("Found new peer \(peer)")
			delegate?.browser(self, foundPeer: availableServices[sender]!, withDiscoveryInfo: NSNetService.dictionaryWithTXTData(sender.TXTRecordData()))
			return
		}
		MGLog("Updating peer's TXT dictionary")
		MGDebugLog("Updating peer \(peer)'s dictionary")
		delegate?.browser?(self, didUpdatePeer: peer, withDiscoveryInfo: NSNetService.dictionaryWithTXTData(sender.TXTRecordData()))
	}
	private func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber])
	{
		guard let peer = availableServices[sender]
			else
		{
			MGDebugLog("Could not \(sender.name) resolve with error \(errorDict)")
			return
		}
		MGLog("Could not resolve the service")
		MGDebugLog("Could not resolve the service with error \(errorDict)")
		delegate?.browser?(self, couldNotResolvePeer: peer, withError: errorDict)
	}
	private func netService(sender: NSNetService, didAcceptConnectionWithInputStream inputStream: NSInputStream, outputStream: NSOutputStream)
	{
		stopBrowsingForPeers()
		let newInvite = MGNearbyConnectionResolver(ruler: self, inputStream: inputStream, outputStream: outputStream)
		pendingInvites.append(newInvite)
	}
	private func netService(sender: NSNetService, didUpdateTXTRecordData data: NSData)
	{
		guard let peer = availableServices[sender]
			else
		{
			return
		}
		delegate?.browser?(self, didUpdatePeer: peer, withDiscoveryInfo: NSNetService.dictionaryWithTXTData(sender.TXTRecordData()))
	}
}

// MARK: - Browser Callbacks
extension MGNearbyServiceBrowser
{
	private func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber])
	{
		assert(browser === self.browser)
		MGLog("Browser error. Could not start.")
		MGDebugLog("Browser could not start with error \(errorDict)")
		delegate?.browser?(self, didNotStartBrowsingForPeers: errorDict)
	}
	
	private func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool)
	{
		assert(browser === self.browser)
		guard service != server && service.name != server.name
		else
		{
			return
		}
		MGLog("Found new peer \(service.name)")
		MGDebugLog("Found new peer \(service.name)")
		MGDebugLog("Attempting to resolve \(service.name) with domain \(service.domain) and type \(service.type)")
		service.delegate = delegateHelper
		service.resolveWithTimeout(1.0)
		let peer = MGPeerID(displayName: service.name)
		availableServices[service] = peer
		delegate?.browser(self, foundPeer: peer, withDiscoveryInfo: NSNetService.dictionaryWithTXTData(service.TXTRecordData()))
	}
	
	private func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool)
	{
		assert(browser === self.browser)
		guard let peer = availableServices[service]
		else
		{
			return
		}
		MGLog("Lost peer \(service.name)")
		MGDebugLog("Browser lost peer \(service.name) on port \(service.port) and host \(service.hostName)")
		availableServices.removeValueForKey(service)
		delegate?.browser(self, lostPeer: peer)
	}
}

// MARK: - CustomStringConvertible
extension MGNearbyServiceBrowser
{
	public override var description : String { return "Browser for peer \(myPeerID). Searching for services named \(serviceType)" }
	
	private func updateTXTRecordDataForService(service: NSNetService)
	{
		guard let discovery = self.discoveryInfo
		else
		{
			return
		}
		var dict = [String: NSData]()
		for (key, value) in discovery
		{
			guard let val = value.dataUsingEncoding(NSUTF8StringEncoding)
			else
			{
				continue
			}
			dict[key] = val
		}
		server.setTXTRecordData(NSNetService.dataFromTXTRecordDictionary(dict))
	}
}

// MARK: - 
// MARK: - NetServiceHelper
/// This class is a helper to handle delegate callbacks privately.
@objc private class MGNearbyServiceBrowserHelper : NSObject
{
	weak var ruler: MGNearbyServiceBrowser?
	var openStreamsCount = 0
	var remotePeer: MGPeerID?
	var inputStream: NSInputStream?
	var outputStream: NSOutputStream?
}
// MARK: - NSNetServiceBrowserDelegate
extension MGNearbyServiceBrowserHelper : NSNetServiceBrowserDelegate
{
	@objc func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser)
	{
		MGDebugLog("Browser stopped searching for nearby devices.")
	}
	@objc private func netServiceBrowserWillSearch(browser: NSNetServiceBrowser)
	{
		MGDebugLog("Browser started searching for nearby devices")
	}
	@objc func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber])
	{
		ruler?.netServiceBrowser(browser, didNotSearch: errorDict)
	}
	
	@objc func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool)
	{
		ruler?.netServiceBrowser(browser, didFindService: service, moreComing: moreComing)
	}
	
	@objc func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool)
	{
		ruler?.netServiceBrowser(browser, didRemoveService: service, moreComing: moreComing)
	}
}
// MARK: - NSNetServiceDelegate
extension MGNearbyServiceBrowserHelper : NSNetServiceDelegate
{
	@objc func netServiceDidPublish(sender: NSNetService)
	{
		ruler?.netServiceDidPublish(sender)
	}
	@objc func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber])
	{
		ruler?.netService(sender, didNotPublish: errorDict)
	}
	@objc func netServiceDidStop(sender: NSNetService)
	{
		ruler?.netServiceDidStop(sender)
	}
	@objc func netServiceDidResolveAddress(sender: NSNetService)
	{
		ruler?.netServiceDidResolveAddress(sender)
	}
	@objc func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber])
	{
		ruler?.netService(sender, didNotResolve: errorDict)
	}
	@objc func netService(sender: NSNetService, didAcceptConnectionWithInputStream inputStream: NSInputStream, outputStream: NSOutputStream)
	{
		ruler?.netService(sender, didAcceptConnectionWithInputStream: inputStream, outputStream: outputStream)
	}
	@objc func netService(sender: NSNetService, didUpdateTXTRecordData data: NSData)
	{
		ruler?.netService(sender, didUpdateTXTRecordData: data)
	}
}

// MARK: -
// MARK: - Connection Resolution Helper
@objc private class MGNearbyConnectionResolver: NSObject
{
	var openStreamsCount = 0
	
	var remotePeer: MGPeerID?
	var session: MGSession?
	
	var inputStream: NSInputStream
	var outputStream: NSOutputStream
	
	weak var ruler: MGNearbyServiceBrowser?
	
	let writeLock = NSCondition()
	
	private init(ruler: MGNearbyServiceBrowser, inputStream: NSInputStream, outputStream: NSOutputStream)
	{
		self.ruler = ruler
		self.inputStream = inputStream
		self.outputStream = outputStream
		super.init()
		setup()
	}
	
	private init(ruler: MGNearbyServiceBrowser, inputStream: NSInputStream, outputStream: NSOutputStream, remotePeer: MGPeerID, session: MGSession)
	{
		self.ruler = ruler
		self.outputStream = outputStream
		self.inputStream = inputStream
		self.remotePeer = remotePeer
		self.session = session
		super.init()
		setup()
	}
	
	private func setup()
	{
		self.inputStream.delegate = self
		self.outputStream.delegate = self
		
		self.inputStream.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
		self.outputStream.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
		
		self.inputStream.open()
		self.outputStream.open()
	}

}
// MARK: - NSStreamDelegate
extension MGNearbyConnectionResolver : NSStreamDelegate
{
	@objc private func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent)
	{
		switch eventCode
		{
		case NSStreamEvent.OpenCompleted:
			MGLog("Opened new stream")
			MGDebugLog("Opened new stream")
			++openStreamsCount
			guard openStreamsCount == 2
			else
			{
				break
			}
			MGLog("Both streams opened.")
			guard remotePeer != nil
			else
			{
				break
			}
			MGLog("Opened all streams sending handshake")
			MGDebugLog("Opened all streams sending handshake")
			sendHandshake()
			break
		case NSStreamEvent.HasBytesAvailable:
			guard let input = aStream as? NSInputStream
				else
			{
				fatalError("Expected only input streams to have bytes avaialble")
			}
			guard let JSON = readDataFromStream(input)
				else
			{
				MGDebugLog("No JSON found. Throwing away garbage data.")
				return
			}
			parseJSON(JSON)
			break
		case NSStreamEvent.HasSpaceAvailable:
			MGDebugLog("Stream has space available to write data.")
			break
		case NSStreamEvent.ErrorOccurred, NSStreamEvent.EndEncountered:
			MGLog("Stream error \(aStream.streamError)")
			MGDebugLog("Stream \(aStream) encountered an error \(aStream.streamError?.localizedDescription) with NSError object \(aStream.streamError) and stream's status is \(aStream.streamStatus)")
			closeConnection()
			break
		case NSStreamEvent.None:
			MGLog("Stream status \(aStream.streamStatus)") // Who knows what is happening here.
			MGDebugLog("Stream status \(aStream.streamStatus)") // Who knows what is happening here.
			assertionFailure("Debugging a None stream event.")
			break
		default:
			break
		}
	}
	
	private func closeConnection()
	{
		MGDebugLog("An error occurred closing the connection.")
		self.inputStream.delegate = nil
		self.outputStream.delegate = nil
		self.outputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
		self.inputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
		self.outputStream.close()
		self.inputStream.close()
		self.ruler?.pendingInvites.removeElement(self)
		if remotePeer == nil
		{
			self.ruler?.startBrowsingForPeers()
		}
	}
	private func sendSmallDataPacket(data: NSData)
	{
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),  {
			var bytes = [UInt8]()
			bytes.reserveCapacity(data.length)
			var dataBytes = UnsafePointer<UInt8>(data.bytes)
			for _ in 0..<data.length
			{
				bytes.append(dataBytes.memory)
				dataBytes = dataBytes.successor()
			}
			assert(bytes.count == data.length)
			self.writeLock.lock()
			while !self.outputStream.hasSpaceAvailable
			{
				self.writeLock.wait()
			}
			defer { self.writeLock.unlock() }
			let len = self.outputStream.write(bytes, maxLength: data.length)
			guard len > 0
			else
			{
				if let peer = self.remotePeer
				{
					do
					{
						try self.session?.rejectConnectionToPeer(peer)
					}
					catch
					{
						MGLog("Error \(error)")
						MGDebugLog("An error occurred for remote \(peer) with error \(error)")
					}
				}
				return
			}
		})
	}
	private func sendHandshake()
	{
		let data = try! NSJSONSerialization.dataWithJSONObject(["n" : ruler?.myPeerID.displayName ?? ""], options: [])
		sendSmallDataPacket(data)
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
			var buf = [UInt8]()
			buf.reserveCapacity(MGSession.packetSize)
			while self.inputStream.hasBytesAvailable
			{
				let len = self.inputStream.read(&buf, maxLength: MGSession.packetSize)
				guard len >= 0
					else
				{
					sleep(3)
					continue
				}
				guard let JSON = self.parseData(NSData(bytes: buf, length: len))
					else
				{
					continue
				}
				self.parseJSON(JSON)
				break
			}
			
		})
	}
	private func sendAckPacket(acknowledge: Bool)
	{
		MGDebugLog("Sending acknowledge packet. Acknowledged? \(acknowledge)")
		let ackPacket = ["ack": acknowledge]
		let data = try! NSJSONSerialization.dataWithJSONObject(ackPacket, options: [])
		sendSmallDataPacket(data)
	}
	private func readDataFromStream(stream: NSInputStream) -> [NSObject: AnyObject]?
	{
		guard stream.hasBytesAvailable && stream.streamStatus != .AtEnd
			else
		{
			return nil
		}
		let data = NSMutableData()
		var bytes = [UInt8]()
		bytes.reserveCapacity(255)
		while stream.hasBytesAvailable
		{
			let len = stream.read(&bytes, maxLength: 255)
			guard len > 0
			else
			{
				break
			}
			data.appendBytes(bytes, length: len)
		}
		return parseData(data)
	}
	private func parseData(data: NSData) -> [NSObject: AnyObject]?
	{
		do
		{
			let JSON = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [NSObject: AnyObject]
			return JSON
		}
		catch
		{
			return nil
		}
	}
	private func parseJSON(JSON: [NSObject: AnyObject])
	{
		if let name = JSON["n"] as? String
		{
			let peer = MGPeerID(displayName: name)
			MGDebugLog("Recieved an invitation from peer \(peer). Asking for user input.")
			MGLog("Recieved new invitation")
			ruler?.delegate?.browser(ruler!, didReceiveInvitationFromPeer: peer, invitationHandler: { accept, session in
				guard self.inputStream.isAlive && self.outputStream.isAlive
				else
				{
					MGDebugLog("Could not finalize connection due to internal state. Force closing so that the other side doesn't keep waiting for a response.")
					MGLog("Connection establishing failed. Closing connection.")
					self.closeConnection()
					return
				}
				do
				{
					self.sendAckPacket(accept)
					guard accept
					else
					{
						// We didn't accept the connection. Close it.
						self.closeConnection()
						return
					}
					try session.initialConnectToPeer(peer, inputStream: self.inputStream, outputStream: self.outputStream)
					try session.finalizeConnectionToPeer(peer)
				}
				catch
				{
					MGDebugLog("Failed to connect to peer with error \(error)")
					MGLog("Connection attempt failed")
					self.closeConnection()
				}
			})
		}
		else if let accepted = JSON["ack"] as? Bool, let remote = remotePeer, let session = session
		{
			do
			{
				MGLog("Recievied acknowledge packet")
				if accepted
				{
					MGDebugLog("Peer \(remote) accepted the connection attempt.")
					try session.finalizeConnectionToPeer(remote)
				}
				else
				{
					MGDebugLog("Peer \(remote) declined the connection attempt.")
					try session.rejectConnectionToPeer(remote)
				}
			}
			catch
			{
				closeConnection()
			}
		}
		else
		{
			MGDebugLog("Recieved unknown data packet before authentication: \(JSON)")
			MGDebugLog("Recieved invalid data. Closing up connection to for security reasons.")
			closeConnection()
		}
	}
}

