//
//  MGBrowserViewController.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 05/07/15.
//
//

import UIKit

@objc public class MGBrowserViewController: UIViewController
{
	/// Initializes a browser view controller with the provided browser and session.
	
	private let tableView : UITableView
	public let browser: MGNearbyServiceBrowser
	public let session: MGSession
	
	private var connectedPeers = [MGPeerID]()
	private var availablePeers = [MGPeerID]()
	
	/// Initializes a browser view controller with the provided browser and session.
	/// - Parameter browser: An object that the browser view controller uses for browsing. This is usually an instance of MGNearbyServiceBrowser. However, if your app is using a custom discovery scheme, you can instead pass any custom subclass that calls the methods defined in the MCNearbyServiceBrowserDelegate protocol on its delegate when peers are found and lost.
	/// - Parameter session: The multipeer session into which the invited peers are connected.
	/// Returns: An initialized browser.
	/// - Warning: If you want the browser view controller to manage the browsing process, the browser object must not be actively browsing, and its delegate must be nil.
	public init(browser: MGNearbyServiceBrowser, session: MGSession)
	{
		tableView = UITableView(frame: CGRectZero, style: .Grouped)
		self.browser = browser
		self.session = session
		super.init(nibName: nil, bundle: nil)
	
	}
	required public init(coder aDecoder: NSCoder)
	{
		tableView = UITableView()
		let peer = MGPeerID(displayName: nil)
		self.browser = MGNearbyServiceBrowser(peer: peer, discoveryInfo: nil, serviceType: "custom-server")
		self.session = MGSession(peer: peer)
		super.init(coder: aDecoder)
	}
	public override func loadView()
	{
		super.loadView()
		tableView.frame = view.frame
		let topConstraint = NSLayoutConstraint(item: tableView, attribute: .Top, relatedBy: .Equal, toItem: topLayoutGuide, attribute: .Top, multiplier: 1.0, constant: 0.0)
		let bottomConstraint = NSLayoutConstraint(item: tableView, attribute: .Bottom, relatedBy: .Equal, toItem: bottomLayoutGuide, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
		let rightConstraint = NSLayoutConstraint(item: tableView, attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .Right, multiplier: 1.0, constant: -16.0)
		let leftConstraint = NSLayoutConstraint(item: tableView, attribute: .Left, relatedBy: .Equal,
			toItem: view, attribute: .Left, multiplier: 1.0, constant: -16.0)
		tableView.addConstraint(topConstraint)
		tableView.addConstraint(bottomConstraint)
		tableView.addConstraint(rightConstraint)
		tableView.addConstraint(leftConstraint)
		navigationItem.title = nil
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "donePressed:")
		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelPressed:")
		view.addSubview(tableView)
	}
	
	// MARK: - Actions
	func donePressed(sender: UIBarButtonItem)
	{
		
	}
	func cancelPressed(sender: UIBarButtonItem)
	{
		
	}
}
//MARK: - TableViewStuff
extension MGBrowserViewController : UITableViewDelegate, UITableViewDataSource
{
	public func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
		return 2
	}
	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return section == 0 ? connectedPeers.count : availablePeers.count
	}
	
	public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
		//TODO: Setup cell here
		return cell
	}
	public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		tableView.cellForRowAtIndexPath(indexPath)!.highlighted = false
		if indexPath.section == 1
		{
			// TODO: Connect to selected peer.
		}
		else
		{
			let peer = connectedPeers[indexPath.row]
			let alertController = UIAlertController(title: "Disconnect From \(peer.displayName)", message: "Are you sure you want to disconnect from \(peer.displayName)", preferredStyle: .ActionSheet)
			alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
			alertController.addAction(UIAlertAction(title: "Disconnect", style: .Destructive, handler: { action in
				self.connectedPeers.removeElement(peer)
				self.session.cancelConnectPeer(peer)
				self.tableView.reloadSections(NSIndexSet(indexesInRange: NSRange(location: 0, length: 2)), withRowAnimation: .Automatic)
			}))
		}
		
	}
	public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		return section == 0 ? "Connected Peers" : "Available Peers"
	}
	
}
// MARK: - Browser stuff
extension MGBrowserViewController : MGNearbyServiceBrowserDelegate
{
	public func browser(browser: MGNearbyServiceBrowser, foundPeer peerID: MGPeerID, withDiscoveryInfo info: [String : String]?)
	{
		assert(browser === self.browser)
		guard peerID != session.localPeer && peerID != browser.myPeerID
		else { return }
		availablePeers.append(peerID)
		tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
	}
	public func browser(browser: MGNearbyServiceBrowser, lostPeer peerID: MGPeerID)
	{
		assert(browser === self.browser)
		guard peerID != session.localPeer && peerID != browser.myPeerID
		else
		{
			assertionFailure("We lost the browser to our own peer. Something went wrong in the browser.")
			return
		}
		availablePeers.removeElement(peerID)
		tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
	}
	public func browser(browser: MGNearbyServiceBrowser, didReceiveInvitationFromPeer peerID: MGPeerID, withContext context: NSData?, invitationHandler: (Bool, MGSession) -> Void)
	{
		// TODO: Impelment
	}
}