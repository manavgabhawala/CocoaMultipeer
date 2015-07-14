//
//  MGBrowserViewController.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 05/07/15.
//
//

import UIKit

protocol MGBrowserTableViewControllerDelegate : NSObjectProtocol
{
	var minimumPeers: Int { get }
	var maximumPeers: Int { get }
}

@objc internal class MGBrowserTableViewController: UITableViewController
{
	/// The browser passed to the initializer for which this class is presenting a UI for. (read-only)
	internal let browser: MGNearbyServiceBrowser
	
	/// The session passed to the initializer for which this class is presenting a UI for. (read-only)
	internal let session: MGSession
	
	internal weak var delegate: MGBrowserTableViewControllerDelegate!
	
	private var availablePeers = [MGPeerID]()
	private var connectedPeers = [MGPeerID]()
	
	/// Initializes a browser view controller with the provided browser and session.
	/// - Parameter browser: An object that the browser view controller uses for browsing. This is usually an instance of MGNearbyServiceBrowser. However, if your app is using a custom discovery scheme, you can instead pass any custom subclass that calls the methods defined in the MCNearbyServiceBrowserDelegate protocol on its delegate when peers are found and lost.
	/// - Parameter session: The multipeer session into which the invited peers are connected.
	/// Returns: An initialized browser.
	/// - Warning: If you want the browser view controller to manage the browsing process, the browser object must not be actively browsing, and its delegate must be nil.
	internal init(browser: MGNearbyServiceBrowser, session: MGSession)
	{
		self.browser = browser
		self.session = session
		super.init(style: .Grouped)
		self.browser.delegate = self
	}
	required internal init?(coder aDecoder: NSCoder)
	{
		let peer = MGPeerID()
		self.browser = MGNearbyServiceBrowser(peer: peer, serviceType: "custom-server")
		self.session = MGSession(peer: peer)
		super.init(coder: aDecoder)
		self.browser.delegate = self
	}
	
	internal override func viewDidLoad()
	{
		navigationItem.title = ""
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "donePressed:")
		navigationItem.rightBarButtonItem?.enabled = false
		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelPressed:")
	}
	internal override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		browser.startBrowsingForPeers()
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionUpdated:", name: MGSession.sessionPeerStateUpdatedNotification, object: session)
		tableView.reloadData()
	}
	internal override func viewDidDisappear(animated: Bool)
	{
		super.viewDidDisappear(animated)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: MGSession.sessionPeerStateUpdatedNotification, object: session)
		browser.stopBrowsingForPeers()
	}
	internal func sessionUpdated(notification: NSNotification)
	{
		guard notification.name == MGSession.sessionPeerStateUpdatedNotification
		else
		{
			return
		}
		dispatch_async(dispatch_get_main_queue(), {
			var connectedPeersCount = 0
			var indicesToAdd = [Int]()
			var indicesToRemove = [Int]()
			for (i, peer) in self.session.connectedPeers.enumerate()
			{
				guard self.connectedPeers.count > i
				else
				{
					self.connectedPeers.append(peer)
					indicesToAdd.append(i)
					continue
				}
				if self.connectedPeers[i] != peer
				{
					self.connectedPeers[i] = peer
					self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)], withRowAnimation: .Automatic)
				}
				do
				{
					let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0))
					let state = try self.session.stateForPeer(peer)
					if (state == .Connected)
					{
						++connectedPeersCount
					}
					cell?.detailTextLabel!.text = state.description
				}
				catch
				{
					print(error)
				}
			}
			if indicesToAdd.count > 0
			{
				self.tableView.insertRowsAtIndexPaths(indicesToAdd.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Left)
			}
			for i in self.session.connectedPeers.count..<self.connectedPeers.count
			{
				self.connectedPeers.removeAtIndex(i)
				indicesToRemove.append(i)
			}
			if indicesToRemove.count > 0
			{
				self.tableView.deleteRowsAtIndexPaths(indicesToRemove.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Left)
			}
			if connectedPeersCount >= self.delegate?.minimumPeers
			{
				self.navigationItem.rightBarButtonItem?.enabled = true
			}
			else
			{
				self.navigationItem.rightBarButtonItem?.enabled = false
			}
		})
	}
	
	// MARK: - Actions
	internal func donePressed(sender: UIBarButtonItem)
	{
		guard connectedPeers.count >= delegate.minimumPeers && connectedPeers.count <= delegate.maximumPeers
		else
		{
			return
		}
		dismissViewControllerAnimated(true, completion: nil)
	}
	internal func cancelPressed(sender: UIBarButtonItem)
	{
		session.disconnect()
		dismissViewControllerAnimated(true, completion: nil)
	}
}
// MARK: - TableViewStuff
extension MGBrowserTableViewController
{
	internal override func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
		return 2
	}
	internal override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return section == 0 ? connectedPeers.count : availablePeers.count
	}
	
	internal override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell : UITableViewCell
		if indexPath.section == 0
		{
			cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "connected")
			cell.textLabel!.text = session.connectedPeers[indexPath.row].displayName
			do
			{
				cell.detailTextLabel!.text = try session.stateForPeer(connectedPeers[indexPath.row]).description
			}
			catch
			{
				print(error)
			}
			cell.selectionStyle = .None
		}
		else
		{
			cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "available")
			cell.textLabel!.text = availablePeers[indexPath.row].displayName
			cell.selectionStyle = .Default
		}
		return cell
	}
	internal override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		tableView.cellForRowAtIndexPath(indexPath)!.setHighlighted(false, animated: true)
		guard indexPath.section == 1 && delegate.maximumPeers > session.connectedPeers.count
		else { return }
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			do
			{
				try self.browser.invitePeer(self.availablePeers[indexPath.row], toSession: self.session)
			}
			catch
			{
				print(error)
				self.availablePeers.removeAtIndex(indexPath.row)
				// Couldn't find the peer so let's reload the table.
				self.tableView.reloadData()
			}
		})
	}
	internal override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		return section == 0 ? "Connected Peers" : "Available Peers"
	}
	internal override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String?
	{
		return section == 0 ? nil : "This device will appear as \(browser.myPeerID.displayName). You must connect to at least \(delegate.minimumPeers.peerText) and no more than \(delegate.maximumPeers.peerText)."
	}
	
}
// MARK: - Browser stuff
extension MGBrowserTableViewController : MGNearbyServiceBrowserDelegate
{
	internal func browserDidStartSuccessfully(browser: MGNearbyServiceBrowser)
	{
		tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
	}
	internal func browser(browser: MGNearbyServiceBrowser, didNotStartBrowsingForPeers error: [String : NSNumber])
	{
		print(error)
		assertionFailure()
	}
	internal func browser(browser: MGNearbyServiceBrowser, foundPeer peerID: MGPeerID, withDiscoveryInfo info: [String : String]?)
	{
		assert(browser === self.browser)
		guard peerID != session.myPeerID && peerID != browser.myPeerID
		else { return } // This should never happen but its better to check
		availablePeers.append(peerID)
		dispatch_async(dispatch_get_main_queue(), {
			self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
		})
		
	}
	internal func browser(browser: MGNearbyServiceBrowser, lostPeer peerID: MGPeerID)
	{
		assert(browser === self.browser)
		guard peerID != session.myPeerID && peerID != browser.myPeerID
		else
		{
			fatalError("We lost the browser to our own peer. Something went wrong in the browser.")
		}
		availablePeers.removeElement(peerID)
		dispatch_async(dispatch_get_main_queue(), {
			self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
		})
	}
	internal func browser(browser: MGNearbyServiceBrowser, didReceiveInvitationFromPeer peerID: MGPeerID, invitationHandler: (Bool, MGSession) -> Void)
	{
		guard session.connectedPeers.count == 0
		else
		{
			// We are already connected to some peers so we can't accept any other connections.
			invitationHandler(false, session)
			return
		}
		let alertController = UIAlertController(title: "\(peerID.displayName) wants to connect?", message: nil, preferredStyle: .Alert)
		alertController.addAction(UIAlertAction(title: "Decline", style: .Destructive, handler: { action  in
			invitationHandler(false, self.session)
		}))
		alertController.addAction(UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default, handler: {action in
			invitationHandler(true, self.session)
			// Remove self since we accepted the connection.
			self.dismissViewControllerAnimated(true, completion: nil)
		}))
		presentViewController(alertController, animated: true, completion: nil)
	}
}