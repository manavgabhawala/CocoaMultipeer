# CocoaMultipeer

## Introduction
This repository is a peer to peer framework for OS X, iOS and watchOS 2 that presents a similar interface to the MultipeerConnectivity framework (which is iOS only) that lets you connect any 2 devices from any platform. This framework works with peer to peer networks like bluetooth and ad hoc wifi networks when available it also falls back onto using a wifi router when necessary. It is built on top of CFNetwork and NSNetService. It uses the newest Swift 2's features like error handling and protocol extensions.

## Why build this?
With Apple introducing features like continuity and handoff, being able to stream data back and forth between devices would be a natural next step. Using airdrop like technology this allows you to send `NSData` instances back and forth between connected peers using `NSStream`s for output and input. This is easy to setup, literally 0 configuration and easy to send and recieve data. It is thread safe and never blocks the main thread by using callbacks to a delegate. It also includes a default UI for the interfaces so that its super easy to just plug and play and start sending your data. The best part about this is that it even supports peer to peer networks so data can be sent really fast instead of sending it over onto the internet using services like iCloud, Dropbox or even a web server. The high level of abstraction provides a great interface for any app developer.

## Installation
The usual. Download the frameworks and drag and drop. Adding cocoa pods support soon.


## How To Use - API
Coming soon but it will be well documented.

## Conclusion

Want to contribute to this project? Make a pull request. Facing a problem? Report an issue. 
If you want to show your love for this project star it, clone it or even fork it.