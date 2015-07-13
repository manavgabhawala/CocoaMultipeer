//
//  MGSessionState.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 13/07/15.
//
//

import Foundation

///  Indicates the current state of a given peer within a session.
///
///  - NotConnected: The peer is not (or is no longer) in this session.
///  - Connecting:   A connection to the peer is currently being established.
///  - Connected:    The peer is connected to this session.
@objc public enum MGSessionState : Int
{
	/// The peer is not (or is no longer) in this session.
	case NotConnected
	/// A connection to the peer is currently being established.
	case Connecting
	/// The peer is connected to this session.
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