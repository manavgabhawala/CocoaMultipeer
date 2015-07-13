//
//  MGSessionState.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 13/07/15.
//
//

import Foundation

@objc public enum MGSessionState : Int
{
	case NotConnected
	case Connecting
	case Connected
}
extension MGSessionState : CustomStringConvertible
{
	public var description: String
	{
		switch self
		{
		case NotConnected:
			return "Declined"
		case Connecting:
			return "Connecting"
		case Connected:
			return "Connected"
		}
	}
}