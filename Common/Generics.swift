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
		guard let index = self.indexOf(element)
		else
		{
			fatalError("Could not find the element inside the reciever type. To silently exit when the element is not found use `removeElementSafely:` instead.")
		}
		self.removeAtIndex(index)
	}
	mutating func removeElementSafely(element: Generator.Element)
	{
		guard let index = self.indexOf(element)
			else
		{
			return
		}
		self.removeAtIndex(index)
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