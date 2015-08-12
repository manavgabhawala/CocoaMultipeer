//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by Manav Gabhawala on 08/08/15.
//
//

import WatchKit
import Foundation
import MultipeerCocoaWatchOS

let peer = MGPeerID(displayName: WKInterfaceDevice.currentDevice().name)

class InterfaceController: WKInterfaceController {

	var browser: MGNearbyServiceBrowser!
	var session: MGSession!
	
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
		
		browser = MGNearbyServiceBrowser(peer: peer, serviceType: "peer-demo")
		session = MGSession(peer: peer)
		session.delegate = self
		browser.delegate = self
		browser.startBrowsingForPeers()
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
		browser.stopBrowsingForPeers()
    }

}
extension InterfaceController: MGNearbyServiceBrowserDelegate, MGSessionDelegate
{
	func browser(browser: MGNearbyServiceBrowser, didReceiveInvitationFromPeer peerID: MGPeerID, invitationHandler: (Bool, MGSession) -> Void)
	{
		let acceptAction = WKAlertAction(title: "Accept", style: WKAlertActionStyle.Default) {
			invitationHandler(true, self.session)
		}
		let declineAction = WKAlertAction(title: "Decline", style: WKAlertActionStyle.Destructive) {
			invitationHandler(false, self.session)
		}
		dispatch_async(dispatch_get_main_queue(), {
			self.presentAlertControllerWithTitle("\(peerID.displayName) wants to connect?", message: nil, preferredStyle: .SideBySideButtonsAlert, actions: [acceptAction, declineAction])
		})
	}
	
	// Since the watch should not act as a server but only a client.
	func browser(browser: MGNearbyServiceBrowser, foundPeer peerID: MGPeerID, withDiscoveryInfo info: [String : String]?)
	{ }
	func browser(browser: MGNearbyServiceBrowser, lostPeer peerID: MGPeerID)
	{ }
	
	func session(session: MGSession, didReceiveData data: NSData, fromPeer peerID: MGPeerID)
	{
		let str = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
		print("Recieved data from \(peerID): \(str)")
	}
}