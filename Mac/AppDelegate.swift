//
//  AppDelegate.swift
//  Mac
//
//  Created by Manav Gabhawala on 14/07/15.
//
//

import Cocoa
import MultipeerCocoaMac

let peer = MGPeerID()

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: NSWindow!
	@IBOutlet var textView : NSTextView!
	
	// Passing in the same peer object to the browser and the session is crucial. Not doing so is a big programming error and can result in undefined results.
	let session = MGSession(peer: peer)
	let browser = MGNearbyServiceBrowser(peer: peer, discoveryInfo: nil, serviceType: "peer-demo")
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
		session.delegate = self
		if session.connectedPeers.count == 0
		{
			showConnections()
		}
		textView.delegate = self
	}
	func showConnections()
	{
		let vc = MGBrowserViewController(session: session, browser: browser)!
		let wind = NSWindow(contentViewController: vc)
		wind.animationBehavior = .AlertPanel
		window.beginSheet(wind, completionHandler: { response in
			// response == NSModalResponseOK if the user pressed Finish.
			// response == NSModalResponseCancel if the user pressed Cancel.
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

extension AppDelegate : NSTextViewDelegate
{
	func textView(textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool
	{
		if commandSelector == "insertNewline:"
		{
			guard let stringToSend = textView.string?.componentsSeparatedByString("\n").last
			else
			{
				return false
			}
			do
			{
				try session.sendData(stringToSend.dataUsingEncoding(NSUTF8StringEncoding)!, toPeers: session.connectedPeers)
			}
			catch
			{
				// In the real world you would want some real error handling here. But we are just going to print the error for the demo.
				print(error)
			}
		}
		return false
	}
}
extension AppDelegate : MGSessionDelegate
{
	func session(session: MGSession, peer peerID: MGPeerID, didChangeState state: MGSessionState)
	{
		print("State of \(peer) changed to \(state)")
		
	}
	func session(session: MGSession, didReceiveData data: NSData, fromPeer peerID: MGPeerID)
	{
		guard let recievedText = NSString(data: data, encoding: NSUTF8StringEncoding)
		else
		{
			print("Could not parse data \(data)")
			return
		}
		let empty = ""
		textView.string = "\(textView.string ?? empty)\n\(recievedText)"
	}
}
