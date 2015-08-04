# CocoaMultipeer

## Introduction
This repository is a peer to peer framework for OS X, iOS and watchOS 2 that presents a similar interface to the MultipeerConnectivity framework (which is iOS only) that lets you connect any 2 devices from any platform. This framework works with peer to peer networks like bluetooth and ad hoc wifi networks when available it also falls back onto using a wifi router when necessary. It is built on top of CFNetwork and NSNetService. It uses the newest Swift 2's features like error handling and protocol extensions.

## Why build this?
With Apple introducing features like continuity and handoff, being able to stream data back and forth between devices would be a natural next step. Using airdrop like technology this allows you to send `NSData` instances back and forth between connected peers using `NSStream`s for output and input. This is easy to setup, literally 0 configuration and easy to send and recieve data. It is thread safe and never blocks the main thread by using callbacks to a delegate. It also includes a default UI for the interfaces so that its super easy to just plug and play and start sending your data. The best part about this is that it even supports peer to peer networks so data can be sent really fast instead of sending it over onto the internet using services like iCloud, Dropbox or even a web server. The high level of abstraction provides a great interface for any app developer.

## Installation
The usual. Download the frameworks and drag and drop. Adding cocoa pods support soon.

## Features

Note this framework is still under development and is not complete yet. Here's a list of completed features and expected soon features:

- [x] Session, Peer and Browser objects to interact with the API as expected.
- [x] Properties on the above objects to allow for introspection and customization.
- [x] Header docs for all public methods and variables that you should be interacting with.
- [x] Objective-C and Swift support
- [x] Zero-conf browser and invitations.
- [x] Error handling availability
- [x] Assertions and fatal errors for weird unusual circumstances so that you can trace the stack.
- [x] Thread safety and non-blocking (through the use of delegates)
- [x] iOS Browser and Advertieser UI which handles everything from accepting invitations to showing available connections.
- [x] Mac OS X Browser and Advertieser UI which handles everything from accepting invitations to showing available connections.
- [ ] watchOS 2 Browser and Advertiser UI which handles everything from accepting invitations to showing available connections.
- [ ] Example of how to use the frameworks
- [ ] Test cases

## Comparison To Apple's MultipeerConnectivity framework

Here's a list of differences between this framework and Apple's framework. In general I tried to make it as easy as posisble to port code using Apple's framework to this one. For the most part everything else is similar to Apple's framework and has similar features.

### What we have?

- [x] Supports all platforms.
- [x] Single interface for client and server so no need to ask the user to choose whether they want to be the host or the client. In general, the way the framework works is everyone is a host and a client. If the device accepts a connection, it stops being a host and becomes a client.
- [x] Easy to setup and use quickly.

### What we don't have? 
- [ ] No direct file transferring capability.
- [ ] No encryption support in this framework
- [ ] No Reliable and Unreliable modes
- [ ] No custom browsing logic using C CoreFoundation APIs.

P.S. Hopefully I can add support for these features in the near future.

## How To Use - API

Coming soon but it will be well documented.

## Conclusion

Want to contribute to this project? Make a pull request. Facing a problem? Report an issue. 
If you want to show your love for this project star it, clone it or even fork it.
