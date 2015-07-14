//
//  MGNearbyServiceBrowser.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 05/07/15.
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
	
	/// Initializes the nearby service browser object with the TCP connection protocol.
	/// - Parameter peer: The local peer ID for this instance.
	/// - Parameter serviceType: Must be 1–15 characters long. Can contain only ASCII lowercase letters, numbers, and hyphens. This name should be easily distinguished from unrelated services. For example, a Foo app made by Bar company could use the service type `foo-bar`.
	public init(peer myPeerID: MGPeerID, discoveryInfo: [String: String]? = nil, serviceType: String)
	{
		self.serviceType = serviceType
		self.myPeerID = myPeerID
		self.fullServiceType = "_\(serviceType)._tcp"
		server = NSNetService(domain: "", type: fullServiceType, name: myPeerID.displayName, port: 0)
		self.discoveryInfo = discoveryInfo
		server.includesPeerToPeer = true
		if let discovery = self.discoveryInfo
		{
			var dict = [String: NSData]()
			for (key, value) in discovery
			{
				dict[key] = value.dataUsingEncoding(NSUTF8StringEncoding)!
			}
			server.setTXTRecordData(NSNetService.dataFromTXTRecordDictionary(dict))
		}
		browser.includesPeerToPeer = true
		super.init()
		server.delegate = self
		browser.delegate = self
	}
	
	/** Starts browsing for peers. After this method is called (until you call `stopBrowsingForPeers`), the framework calls your delegate's `browser:foundPeer:withDiscoveryInfo:` and browser:lostPeer: methods as new peers are found and lost. After starting browsing, other devices can discover your device as a device that it can connect to until you call the stop browsing for peers method. However, if the device accepts a connection from another peer the `stopBrowsingForPeers` method is called automatically.
	*/
	public func startBrowsingForPeers()
	{
		server.stop()
		server.startMonitoring()
		server.publishWithOptions(NSNetServiceOptions.ListenForConnections)
	}
	
	/** Stops browsing for peers.
	*/
	public func stopBrowsingForPeers()
	{
		server.stop()
		browser.stop()
		server.stopMonitoring()
	}
	
	/// Invites a discovered peer to join a Cocoa Multipeer session.
	/// - Parameter peerID: The ID of the peer to invite.
	/// - Parameter session: The session you wish the invited peer to join.
	///
	/// - Warning: Throws a Peer Not Found error if the peer could not be found.
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
		assert(status, "Could not create streams. This is not a network error so we fail with an assertion to trace the stack.")
		session.connectToPeer(peerID, inputStream: input!, outputStream: output!)
		availableServices.removeValueForKey(service)
	}
	
}
// MARK: - NSNetServiceBrowserDelegate
extension MGNearbyServiceBrowser : NSNetServiceBrowserDelegate
{

	public func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser)
	{}
	
	public func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber])
	{
		assert(browser === self.browser)
		delegate?.browser?(self, didNotStartBrowsingForPeers: errorDict)
	}
	
	public func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool)
	{
		assert(browser === self.browser)
		guard service != server
		else
		{
			return
		}
		service.delegate = self
		service.resolveWithTimeout(10.0)
//		guard availableServices[service] == nil
//		else
//		{
//			return
//		}
//		let peer = MGPeerID(displayName: service.name)
//		availableServices[service] = peer
//		if let discovery = NSNetService.dictionaryWithTXTData(service.TXTRecordData())
//		{
//			delegate?.browser(self, foundPeer: peer, withDiscoveryInfo: discovery)
//		}
//		else
//		{
//			delegate?.browser(self, foundPeer: peer, withDiscoveryInfo: nil)
//			service.resolveWithTimeout(5.0)
//		}
	}
	
	public func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool)
	{
		assert(browser === self.browser)
		guard let peer = availableServices[service]
		else
		{
			return
		}
		availableServices.removeValueForKey(service)
		delegate?.browser(self, lostPeer: peer)
	}
}
// MARK: - NSNetServiceDelegate
extension MGNearbyServiceBrowser : NSNetServiceDelegate
{
	
	public func netServiceDidPublish(sender: NSNetService)
	{
		assert(sender === server)
		myPeerID.name = sender.name
		browser.stop()
		browser.searchForServicesOfType(fullServiceType, inDomain: "")
		delegate?.browserDidStartSuccessfully?(self)
	}
	public func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber])
	{
		assert(sender === server)
		delegate?.browser?(self, didNotStartBrowsingForPeers: errorDict)
	}
	public func netServiceDidStop(sender: NSNetService)
	{
	}
	public func netServiceDidResolveAddress(sender: NSNetService)
	{
		guard availableServices[sender] == nil
		else
		{
			return
		}
		let peer = MGPeerID(displayName: sender.name)
		availableServices[sender] = peer
		delegate?.browser(self, foundPeer: peer, withDiscoveryInfo: NSNetService.dictionaryWithTXTData(sender.TXTRecordData()))
		//delegate?.browser?(self, didUpdatePeer: peer, withDiscoveryInfo: NSNetService.dictionaryWithTXTData(sender.TXTRecordData()))
	}
	public func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber])
	{
		guard let peer = availableServices[sender]
		else
		{
			return
		}
		delegate?.browser?(self, couldNotResolvePeer: peer, withError: errorDict)
	}
	public func netService(sender: NSNetService, didAcceptConnectionWithInputStream inputStream: NSInputStream, outputStream: NSOutputStream)
	{
		let peer = MGPeerID(displayName: sender.name)
		stopBrowsingForPeers()
		delegate?.browser(self, didReceiveInvitationFromPeer: peer, invitationHandler: { (accept, session) in
			if (!accept)
			{
				// Reject the connection.
				outputStream.open()
				inputStream.open()
				outputStream.close()
				inputStream.close()
				self.startBrowsingForPeers()
			}
			else
			{
				// Accept the connection and stop looking for more peers to connect to.
				self.stopBrowsingForPeers()
				session.connectToPeer(peer, inputStream: inputStream, outputStream: outputStream)
			}
		})
	}
	public func netService(sender: NSNetService, didUpdateTXTRecordData data: NSData)
	{
		guard let peer = availableServices[sender]
		else
		{
			return
		}
		delegate?.browser?(self, didUpdatePeer: peer, withDiscoveryInfo: NSNetService.dictionaryWithTXTData(sender.TXTRecordData()))
	}
}

extension MGNearbyServiceBrowser
{
	public override var description : String { return "Browser for peer \(myPeerID). Searching for services named \(serviceType)" }
}
// MARK: - Private helpers
extension MGNearbyServiceBrowser
{
	
}
