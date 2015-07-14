//
//  AppDelegate.swift
//  Mac
//
//  Created by Manav Gabhawala on 14/07/15.
//
//

import Cocoa
import MultipeerCocoaMac

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: NSWindow!
	@IBOutlet var textView : NSTextView!
	let session = MGSession(peer: MGPeerID())
	let browser = MGNearbyServiceBrowser(peer: MGPeerID(), discoveryInfo: nil, serviceType: "peer-demo")
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
		if session.connectedPeers.count == 0
		{
			showConnections()
		}
		
		
	}
	func showConnections()
	{
		let vc = MGBrowserViewController(session: session, browser: browser)!
		let wind = NSWindow(contentViewController: vc)
		wind.animationBehavior = .AlertPanel
		window.beginSheet(wind, completionHandler: { _ in
			if self.session.connectedPeers.count == 0
			{
				self.showConnections()
			}
		})
	}
	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}


}

