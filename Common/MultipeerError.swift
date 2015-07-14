//
//  MGErrors.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 13/07/15.
//
//

import Foundation

///  Error codes found in MultipeerErrorDomain error domain NSError objects returned by methods in the Multipeer Connectivity framework.
public enum MultipeerError : Int, ErrorType
{
    /// The peer sent wasn't recognized or found.
	case PeerNotFound
	
	///  Attempting to do something with a peer that isn't connected to the session.
	case NotConnected
}
extension MultipeerError : CustomStringConvertible
{
	public var description: String
	{
		switch self
		{
		case .PeerNotFound:
			return "The peer sent to the method wasn't found."
		case .NotConnected:
			return "Attempting to work with a peer that isn't connected"
		}
	}
}