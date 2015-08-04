//
//  MGBrowserViewController.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 05/07/15.
//
//

import AppKit

public class MGBrowserViewController: NSViewController
{
	/// Set this to the name of the service you want when setting up using storyboards.
	@IBInspectable public var serviceName : String = "custom-service"
	
	/// The browser passed to the initializer for which this class is presenting a UI for. (read-only)
	public let browser: MGNearbyServiceBrowser
	
	/// The session passed to the initializer for which this class is presenting a UI for. (read-only)
	public let session: MGSession
	
	@IBOutlet var connectButton: NSButton!
	@IBOutlet var cancelButton: NSButton!
	@IBOutlet var tableView : NSTableView!
	@IBOutlet var infoLabel: NSTextField!
	@IBOutlet var finishButton: NSButton!
	
	private var peers = [MGPeerID]()
	private var selectedRow : Int?
	
	/// The minimum number of peers that need to be in a session, including the local peer. The default value is the `minimumAllowedPeers` value from `MGSession`. If set to more than `MGSession.maximumAllowedPeers` or less than `MGSession.minimumAllowedPeers` it will automatically be set to the maximum or minimum allowed peers respectively. If set to more than the `maximumPeers`, a fatalError will be raised.
	@IBInspectable public var minimumPeers : Int = MGSession.minimumAllowedPeers
	{
		didSet
		{
			guard maximumPeers >= minimumPeers
			else
			{
				fatalError("The maximum number of peers cannot be less than the minimum number of peers")
			}
			if minimumPeers > MGSession.maximumAllowedPeers
			{
				minimumPeers = MGSession.maximumAllowedPeers
			}
			if minimumPeers < MGSession.minimumAllowedPeers
			{
				minimumPeers = MGSession.minimumAllowedPeers
			}
			updateInfoLabel()
		}
	}
	
	/// The maximum number of peers allowed in a session, including the local peer. The default value is the `maximumAllowedPeers` value from `MGSession`. If set to more than `MGSession.maximumAllowedPeers` or less than `MGSession.minimumAllowedPeers` it will automatically be set to the maximum or minimum allowed peers respectively. If set to less than the `minimumPeers`, a fatalError will be raised.
	@IBInspectable public var maximumPeers : Int = MGSession.maximumAllowedPeers
	{
		didSet
		{
			guard maximumPeers >= minimumPeers
			else
			{
				fatalError("The maximum number of peers cannot be less than the minimum number of peers")
			}
			if maximumPeers > MGSession.maximumAllowedPeers
			{
				maximumPeers = MGSession.maximumAllowedPeers
			}
			if maximumPeers < MGSession.minimumAllowedPeers
			{
				maximumPeers = MGSession.minimumAllowedPeers
			}
			updateInfoLabel()
		}
	}
	
	public init?(session: MGSession, browser: MGNearbyServiceBrowser)
	{
		self.session = session
		self.browser = browser
		self.serviceName = browser.serviceType
		super.init(nibName: "MGBrowserViewController", bundle: NSBundle(forClass: MGBrowserViewController.self))
		browser.delegate = self
	}
	required public init?(coder: NSCoder)
	{
		let peer = MGPeerID()
		self.browser = MGNearbyServiceBrowser(peer: peer, serviceType: serviceName)
		self.session = MGSession(peer: peer)
		super.init(nibName: "MGBrowserViewController", bundle: NSBundle(forClass: MGBrowserViewController.self))
		browser.delegate = self
	}
	// MARK: - Lifecycle
	public override func viewDidLoad()
	{
		super.viewDidLoad()
		connectButton.target = self
		connectButton.action = "connect:"
		cancelButton.target = self
		cancelButton.action = "cancel:"
		finishButton.target = self
		finishButton.action = "finish:"
		tableView.setDelegate(self)
		tableView.setDataSource(self)
		updateInfoLabel()
		connectButton.enabled = false
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionUpdated:", name: MGSession.sessionPeerStateUpdatedNotification, object: session)
	}
	public override func viewDidAppear()
	{
		browser.startBrowsingForPeers()
	}
	public override func viewDidDisappear()
	{
		browser.stopBrowsingForPeers()
	}
	
	// MARK: - Actions
	func connect(sender: NSButton)
	{
		guard selectedRow != nil && selectedRow >= 0 && selectedRow < peers.count && session.connectedPeers.indexOf(peers[selectedRow!]) == nil
		else
		{
			sender.enabled = false
			return
		}
		do
		{
			try browser.invitePeer(peers[selectedRow!], toSession: session)
		}
		catch
		{
			print(error)
		}
	}
	func cancel(sender: NSButton)
	{
		session.disconnect()
		browser.stopBrowsingForPeers()
		view.window!.sheetParent!.endSheet(view.window!, returnCode: NSModalResponseCancel)
	}
	func finish(sender: NSButton)
	{
		browser.stopBrowsingForPeers()
		view.window!.sheetParent!.endSheet(view.window!, returnCode: NSModalResponseOK)
	}
	
	//  MARK: - Model Updates
	func updateInfoLabel()
	{
		infoLabel.stringValue = "This device will appear as \(browser.myPeerID.displayName). You must connect to at least \(minimumPeers.peerText) and no more than \(maximumPeers.peerText)."
	}
	func sessionUpdated(notification: NSNotification)
	{
		if session.connectedPeers.filter ({
			do
			{
				return try self.session.stateForPeer($0) == .Connected
			}
			catch
			{
				return false
			}
		}).count >= minimumPeers
		{
			finishButton.enabled = true
		}
		else
		{
			finishButton.enabled = false
		}
		dispatch_async(dispatch_get_main_queue(), {
			self.tableView.reloadData()
		})
	}
}
// MARK: - Table view stuff
extension MGBrowserViewController : NSTableViewDataSource, NSTableViewDelegate
{
	public func numberOfRowsInTableView(tableView: NSTableView) -> Int
	{
		return peers.count + session.connectedPeers.count
	}
	public func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView?
	{
		let sessionCount = session.connectedPeers.count
		if tableColumn?.identifier == "connection"
		{
			let cellView = tableView.makeViewWithIdentifier("connection_cell", owner: self) as! NSTableCellView
			if row >= 0 && row < sessionCount
			{
				cellView.textField!.stringValue = session.connectedPeers[row].displayName
				return cellView
			}
			if (row >= sessionCount && row < peers.count + sessionCount)
			{
				cellView.textField!.stringValue = peers[row - sessionCount].displayName
				return cellView
			}
			return nil
		}
		else if tableColumn?.identifier == "status"
		{
			let cellView = tableView.makeViewWithIdentifier("status_cell", owner: self) as! NSTableCellView
			if row >= 0 && row < sessionCount
			{
				do
				{
					cellView.textField!.stringValue = try session.stateForPeer(session.connectedPeers[row]).description
				}
				catch
				{
					cellView.textField!.stringValue = ""
				}
				return cellView
			}
			cellView.textField!.stringValue = ""
			return cellView
		}
		fatalError("The table colum wasn't created.")
	}
	public func tableViewSelectionDidChange(notification: NSNotification)
	{
		if tableView.selectedRow >= session.connectedPeers.count && tableView.selectedRow < session.connectedPeers.count + peers.count
		{
			selectedRow = tableView.numberOfSelectedRows > 0 ? tableView.selectedRow : nil
		}
		else
		{
			selectedRow = nil
		}
		connectButton.enabled = selectedRow != nil
	}
}
// MARK: - Browser stuff
extension MGBrowserViewController : MGNearbyServiceBrowserDelegate
{
	public func browserDidStartSuccessfully(browser: MGNearbyServiceBrowser)
	{
		updateInfoLabel()
	}
	public func browser(browser: MGNearbyServiceBrowser, didNotStartBrowsingForPeers error: [String : NSNumber])
	{
		print(error)
		assertionFailure()
	}
	public func browser(browser: MGNearbyServiceBrowser, foundPeer peerID: MGPeerID, withDiscoveryInfo info: [String : String]?)
	{
		assert(browser === self.browser)
		guard peerID != session.myPeerID && peerID != browser.myPeerID
			else { return } // This should never happen but its better to check
		peers.append(peerID)
		dispatch_async(dispatch_get_main_queue(), tableView.reloadData)
	}
	public func browser(browser: MGNearbyServiceBrowser, lostPeer peerID: MGPeerID)
	{
		assert(browser === self.browser)
		guard peerID != session.myPeerID && peerID != browser.myPeerID
			else
		{
			fatalError("We lost the browser to our own peer. Something went wrong in the browser.")
		}
		peers.removeElement(peerID)
		dispatch_async(dispatch_get_main_queue(), tableView.reloadData)
	}
	public func browser(browser: MGNearbyServiceBrowser, didReceiveInvitationFromPeer peerID: MGPeerID, invitationHandler: (Bool, MGSession) -> Void)
	{
		let alert = NSAlert()
		alert.messageText = "\(peerID) wants to connect?"
		alert.addButtonWithTitle("Accept")
		alert.addButtonWithTitle("Decline")
		alert.beginSheetModalForWindow(view.window!, completionHandler: { response in
			if response == NSAlertFirstButtonReturn
			{
				invitationHandler(true, self.session)
				self.view.window!.sheetParent!.endSheet(self.view.window!, returnCode: NSModalResponseOK)
			}
			else
			{
				invitationHandler(false, self.session)
			}
		})
		
		
	}
}