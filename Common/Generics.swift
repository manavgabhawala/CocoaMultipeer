//
//  Generics.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 05/07/15.
//
//

import Foundation

extension Array where Element : Equatable
{
	mutating func removeElement(element: Generator.Element)
	{
		self = filter({ $0 != element })
	}
}
extension NSNetService
{
	class func dictionaryWithTXTData(data: NSData?) -> [String: String]?
	{
		guard let data = data
		else
		{
			return nil
		}
		let TXT = NSNetService.dictionaryFromTXTRecordData(data)
		var dict = [String: String]()
		for (key, value) in TXT
		{
			guard let str = NSString(data: value, encoding: NSUTF8StringEncoding) as? String
			else
			{
				continue
			}
			dict[key] = str
		}
		return dict
	}
}

extension Int
{
	internal var peerText : String
	{
		return self == 1 ? "\(self) peer" : "\(self) peers"
	}
}

extension NSStream
{
	internal var isAlive: Bool { return streamStatus == .Open || streamStatus == .Writing || streamStatus == .Reading }
}

/// Change this value to true to get a normal log of the details of the server. If debug log is on normal logging doesn't occur but the debug logging logs all the output that normal log would with more detail. By default this is true.
public var normalLog = true
/// Change this value to true in order to get a detailed log of everything happening under the covers. By default this is true.
public var debugLog = true

internal func MGLog<Item>(item: Item)
{
	guard normalLog && !debugLog
	else
	{
		return
	}
	print(item)
}
internal func MGLog<Item>(item: Item?)
{
	guard normalLog && !debugLog
	else
	{
		return
	}
	print(item)
}

internal func MGDebugLog<Item>(item: Item)
{
	guard debugLog
	else
	{
		return
	}
	debugPrint(item)
}
internal func MGDebugLog<Item>(item: Item?)
{
	guard normalLog
	else
	{
		return
	}
	debugPrint(item)
}