//
//  ViewController.swift
//  iOS
//
//  Created by Manav Gabhawala on 13/07/15.
//
//

import UIKit
import MultipeerCocoaiOS

class ViewController: UIViewController
{
	var session : MGSession!
	var browser: MGNearbyServiceBrowser!
	
	@IBOutlet var textView : UITextView!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		let peer = MGPeerID(displayName: UIDevice.currentDevice().name)
		session = MGSession(peer: peer)
		session.delegate = self
		browser = MGNearbyServiceBrowser(peer: peer, serviceType: "peer-demo")
	}
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		if session.connectedPeers.count == 0
		{
			displayPicker()
		}
	}
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	private func displayPicker()
	{
		let browserVC = MGBrowserViewController(browser: browser, session: session)
		presentViewController(browserVC, animated: true, completion: nil)
	}
}
extension ViewController : MGSessionDelegate
{
	func session(session: MGSession, peer peerID: MGPeerID, didChangeState state: MGSessionState)
	{
		print("State of connection to \(peerID) is \(state)")
		if session.connectedPeers.count == 0
		{
			displayPicker()
		}
	}
	func session(session: MGSession, didReceiveData data: NSData, fromPeer peerID: MGPeerID)
	{
		guard let recievedText = NSString(data: data, encoding: NSUTF8StringEncoding)
		else
		{
			print("Could not parse data \(data)")
			return
		}
		textView.text = "\(textView.text)\n\(recievedText)"
	}
}
