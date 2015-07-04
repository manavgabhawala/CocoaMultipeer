//
//  Generics.swift
//  CocoaMultipeer
//
//  Created by Manav Gabhawala on 05/07/15.
//
//

import Foundation

extension Array where T : Equatable
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