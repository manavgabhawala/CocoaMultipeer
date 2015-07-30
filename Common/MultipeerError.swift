//
//  MGErrors.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 13/07/15.
//
//

import Foundation

///  Error codes found in MultipeerErrorDomain error domain NSError objects returned by methods in the Multipeer Connectivity framework.
public enum MultipeerError : Int, ErrorType, Hashable, CustomStringConvertible
{
    /// The peer sent wasn't recognized or found.
	case PeerNotFound
	
	/// The attempt to connect to the peer failed. This means that the peer was lost between the `invitePeer` call and actually establishing the connection. 
	case ConnectionAttemptFailed
	
	///  Attempting to do something with a peer that isn't connected to the session.
	case NotConnected
	
	public var description: String
	{
		switch self
		{
		case .PeerNotFound:
			return "The peer sent to the method wasn't found."
		case .ConnectionAttemptFailed:
			return "The attempt to connect to the peer failed. This means that the peer was lost between the `invitePeer` call and actually establishing the connection."
		case .NotConnected:
			return "Attempting to work with a peer that isn't connected"
		}
	}
	
}