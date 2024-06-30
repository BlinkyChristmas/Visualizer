// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class VisualizationView : NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.autoresizingMask = [.width,.height]
        self.autoresizesSubviews = true
        self.wantsLayer = true
        self.clipsToBounds = true
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.autoresizingMask = [.width,.height]
        self.autoresizesSubviews = true
        self.wantsLayer = true
        self.clipsToBounds = true
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard self.window != nil else { return }
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.black.cgColor
        guard self.superview?.window?.windowController != nil else { return }
        let controller = self.superview!.window!.windowController! as! VisualizationController
        let origin = controller.visualization!.visualOrigin
        self.window?.setFrameOrigin(origin)
    }
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        if newWindow == nil {
            // we need to close
            let controller = self.superview!.window!.windowController! as! VisualizationController
            controller.masterController?.windowWillClose(controller: controller)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        (self.window?.windowController as? VisualizationController)?.draw(dirtyRect)
    }
}
