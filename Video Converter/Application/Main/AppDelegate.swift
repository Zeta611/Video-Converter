//
//  AppDelegate.swift
//  Video Converter
//
//  Created by Jay Lee on 2020/04/04.
//  Copyright © 2020 Jay Lee. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate : NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let contentView = ContentView()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }
}
