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
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		let peer = MGPeerID()
		session = MGSession(peer: peer)
		session.delegate = self
		browser = MGNearbyServiceBrowser(peer: peer, serviceType: "peer-demo")
	}
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		let browserVC = MGBrowserViewController(browser: browser, session: session)
		presentViewController(browserVC, animated: true, completion: nil)
	}
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
extension ViewController : MGSessionDelegate
{
	func session(session: MGSession, peer peerID: MGPeerID, didChangeState state: MGSessionState)
	{
		
	}
	func session(session: MGSession, didReceiveData data: NSData, fromPeer peerID: MGPeerID)
	{
		
	}
}
