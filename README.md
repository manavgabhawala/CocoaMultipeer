# CocoaMultipeer

[![Latest Release](https://img.shields.io/badge/release-0.0.1--beta-blue.svg)](https://github.com/manavgabhawala/CocoaMultipeer)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/manavgabhawala/CocoaMultipeer)
[![License](https://img.shields.io/badge/license-Apache%20License-blue.svg)](https://github.com/manavgabhawala/CocoaMultipeer)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20OS%20X%20%7C%20watchOS-000000.svg)](https://github.com/manavgabhawala/CocoaMultipeer)

## Introduction
This repository is a peer to peer framework for OS X, iOS and watchOS 2 that presents a similar interface to the MultipeerConnectivity framework (which is iOS only) that lets you connect any 2 devices from any platform. This framework works with peer to peer networks like bluetooth and ad hoc wifi networks when available it also falls back onto using a wifi router when necessary. It is built on top of CFNetwork and NSNetService. It uses the newest Swift 2's features like error handling and protocol extensions.

## Why build this?
With Apple introducing features like continuity and handoff, being able to stream data back and forth between devices would be a natural next step. Using airdrop like technology this allows you to send `NSData` instances back and forth between connected peers using `NSStream`s for output and input. This is easy to setup, literally 0 configuration and easy to send and recieve data. It is thread safe and never blocks the main thread by using callbacks to a delegate. It also includes a default UI for the interfaces so that its super easy to just plug and play and start sending your data. The best part about this is that it even supports peer to peer networks so data can be sent really fast instead of sending it over onto the internet using services like iCloud, Dropbox or even a web server. The high level of abstraction provides a great interface for any app developer.

## Installation
**[Download Beta Frameworks](https://github.com/manavgabhawala/CocoaMultipeer/releases/download/v0.0.1-beta/CocoaMultipeer.zip)**

This framework is now in beta most of the functionality that will be present in the first official release is now present in this beta. The framework will leave beta as soon as Xcode 7 is officially released. Cocoapods support will come with the first release.
To test and try out the beta you can download all the frameworks from [here](https://github.com/manavgabhawala/CocoaMultipeer/releases/download/v0.0.1-beta/CocoaMultipeer.zip).
After downloading the frameworks, drag the ones you want into your xcode project and make sure that the `Copy Items if needed` is checked and **no** targets are checked. Then, go into each target you want to add the framework in the xcode project file and under `General` -> `Embedded Binaries` click the plus and select the relevant framework. For instance for an iOS app choose the CocoaMultipeeriOS.framework. Doing this will ensure that the files are properly installed. Then finally, import it in the Swift or Objective C files you wish to as follows:

```swift
import CocoaMultipeeriOS // or Mac or WatchOS depending on the target.
```

```objc
@import CocoaMultipeeriOS; // or Mac, or WatchOS depending on the target.
```

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
- [x] watchOS 2 sample code which shows you how to accept invitations, recieve and send data to available peers. **Note**: Using the watch as a server is currently unsupported due to hardware limitations presented by the watch. Using the frameworks it is programmatically possible to let the watch behave as a server however, I highly do not recommend you do this because of the unpredicitability of termination of watch apps.
- [x] Example of how to use the frameworks. Currently, the xcode project does have a Demos folder with Watch, iOS and Mac targets which have enough code to get you started using these frameworks however, they are not as well developed as they can be and will be fully commented and better coded in the first official release of the framework.
- [ ] Test cases

## Comparison To Apple's MultipeerConnectivity framework

Here's a list of differences between this framework and Apple's framework. In general I tried to make it as easy as posisble to port code using Apple's framework to this one. For the most part everything else is similar to Apple's framework and has similar features.

### What we have?

- [x] Supports all platforms.
- [x] Single interface for client and server so no need to ask the user to choose whether they want to be the host or the client. In general, the way the framework works is everyone is a host and a client. If the device accepts a connection, it stops being a host and becomes a client.
- [x] Easy to setup and use quickly.

### What we don't have? 
- [ ] No direct file transferring capability
- [ ] No encryption support in this framework
- [ ] No Reliable and Unreliable modes
- [ ] No custom browsing logic using C CoreFoundation APIs -  we do all the browsing for you and expose you to the found/lost peers using the delegate's methods.

P.S. Hopefully I can add support for these features in the near future.

## How To Use - API

If you are stuck anywhere check out [Apple's MultipeerConnectivity framework reference](https://developer.apple.com/library/prerelease/ios/documentation/MultipeerConnectivity/Reference/MultipeerConnectivityFramework/index.html#//apple_ref/doc/uid/TP40013328). This framework closely resembles that one and in fact it is possible to port almost all your code from using that framework to this one by simply changing the prefix from MC to MG. The major differences between the two frameworks is listed above. With the official release, this section will be fleshed out a bit more but for now you can check out the demos and use the header docs to understand how the framework works.


## License

Licensed under the [Apache License](http://www.apache.org/licenses/LICENSE-2.0). See the LICENSE file for more details.

## Conclusion

Want to contribute to this project? Make a pull request. Facing a problem? Report an issue. 
If you want to show your love for this project star it, clone it or even fork it.
