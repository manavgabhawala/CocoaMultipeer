//
//  MGBrowserViewController.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 14/07/15.
//
//

import Foundation


/// The MGBrowserViewController class presents nearby devices to the user and enables the user to invite nearby devices to a session. To use this class, call methods from the underlying UIViewController class presentViewController:animated:completion: and dismissViewControllerAnimated:completion: to present and dismiss the view controller.
/// #### Discussion
/// You can create this class inside the storyboard by creating a Navigation View Controller (with no root view controller) and assiging it the `MGBrowserViewController` class. Then, the browser object will be created and managed for you but you must keep a strong reference to the session object and set its delegate to recieve events.
@objc public class MGBrowserViewController: UINavigationController
{
	/// Set this to the name of the service you want when setting up using storyboards.
	@IBInspectable public var serviceName : String = "custom-service"
	
	/// The browser passed to the initializer for which this class is presenting a UI for. (read-only)
	public let browser: MGNearbyServiceBrowser
	
	/// The session passed to the initializer for which this class is presenting a UI for. (read-only)
	public let session: MGSession
	
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
		}
	}
	
	/// Initializes a browser view controller with the provided browser and session.
	/// - Parameter browser: An object that the browser view controller uses for browsing. This is usually an instance of MGNearbyServiceBrowser. However, if your app is using a custom discovery scheme, you can instead pass any custom subclass that calls the methods defined in the MCNearbyServiceBrowserDelegate protocol on its delegate when peers are found and lost.
	/// - Parameter session: The multipeer session into which the invited peers are connected.
	/// - Returns: An initialized browser.
	/// - Warning: If you want the browser view controller to manage the browsing process, the browser object must not be actively browsing, and its delegate must be nil.
	public init(browser: MGNearbyServiceBrowser, session: MGSession)
	{
		self.browser = browser
		self.session = session
		serviceName = browser.serviceType
		super.init(nibName: nil, bundle: nil)
	}
	
	///  When initialized from a storyboard this initializer is used. This will create a peer whose name is nil and will be assigned by the framework. See `browserDidStartSuccessfully`. The name of the server is assigned using the serverName property which is inspectable in Interface Builder. This must follow the naming conventions. See `serviceName` on the `MGNearbyServiceBrowser` class. Do not use this initializer directly.
	required public init?(coder aDecoder: NSCoder)
	{
		let peer = MGPeerID()
		self.browser = MGNearbyServiceBrowser(peer: peer, serviceType: serviceName)
		self.session = MGSession(peer: peer)
		super.init(coder: aDecoder)
	}
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?)
	{
		let peer = MGPeerID()
		self.browser = MGNearbyServiceBrowser(peer: peer, serviceType: serviceName)
		self.session = MGSession(peer: peer)
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	override public func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		let vc = MGBrowserTableViewController(browser: browser, session: session, delegate: self)
		pushViewController(vc, animated: true)
	}
}
extension MGBrowserViewController : MGBrowserTableViewControllerDelegate
{}