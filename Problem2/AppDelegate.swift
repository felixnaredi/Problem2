//
//  AppDelegate.swift
//  Problem2
//
//  Created by Felix Naredi on 2019-08-13.
//  Copyright © 2019 Felix Naredi. All rights reserved.
//

import Cocoa
import MetalKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var textureView: MTKView!

  var renderer: TextureRenderer?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let device = MTLCreateSystemDefaultDevice()!

    renderer = TextureRenderer(device: device)

    textureView.delegate = renderer
    textureView.device = device

    Thread(block: {
      for permutation in sequence(first: [0, 1, 2, 3, 4, 5], next: { $0.map({ ($0 + 5) % 6 }) }) {
        self.renderer?.textureSource = HorizontalSplitTexture(
          device: device,
          colors:
            permutation.map({
            [[0, 0, 1, 1], [0, 1, 1, 1], [0, 1, 0, 1], [1, 1, 0, 1], [1, 0, 0, 1], [1, 0, 1, 1]][$0]
          }))
        Thread.sleep(forTimeInterval: 0.128)
      }
    }).start()
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

}

