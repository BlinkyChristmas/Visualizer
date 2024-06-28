// 

import Cocoa
import UniformTypeIdentifiers

@main
class AppDelegate: NSObject, NSApplicationDelegate,NSWindowDelegate {

    @IBOutlet var window: NSWindow!

    @IBOutlet var settingsData:SettingsData!
    @IBOutlet var settingsDialog:SettingsDialog!
    @objc dynamic var seekTime = 0.0
    
    @IBOutlet var musicPlayer:MusicPlayer!
    @IBAction func seekToTime(_ sender: Any?) {
        self.musicPlayer.currentTime = seekTime
    }
    @objc dynamic  var musicTitles = [String]()
    @objc dynamic var musicName:String? {
        didSet{
            guard musicName != nil else {
                self.musicPlayer.loadMusic(url: nil)
                return
            }
            self.musicPlayer.loadMusic(url: settingsData.musicDirectory!.appending(path: musicName!).appendingPathExtension("wav"))
        }
    }
    
    var bundleDictionary = [String:LightBundle]()
    var bundleObserver:NSKeyValueObservation?
    var controllers = [VisualizationController]()

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true 
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        musicPlayer.volume = 0.25
        self.window.delegate = self
        bundleObserver = settingsData.observe(\.bundleFile, changeHandler: { settings, _ in
            self.processBundles()
        })
        do{
            self.processBundles()
            musicTitles = try contentsOf(url: self.settingsData.musicDirectory,with: "wav", includeExtension: false).sorted()
        }
        catch{
            NSAlert(error: GeneralError(errorMessage: "Error on start, most likely dealing with Settings", failure: error.localizedDescription)).beginSheetModal(for: self.window!)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    func processBundles() {
        guard let url = settingsData.completeBundle else {
            NSAlert(error:(GeneralError(errorMessage: "Unable to process bundles", failure: "Bundle file or Base Directory is not set"))).beginSheetModal(for: self.window)
            return
        }
        do{
            bundleDictionary = try Visualizer.processBundles(url: url)
        }
        catch{
            NSAlert(error:(GeneralError(errorMessage: "Unable to process bundles", failure: "Bundle file or Base Directory is not set"))).beginSheetModal(for: self.window)
        }
    }

    func windowWillClose(_ notification: Notification) {
        musicPlayer.stop()
        for controller in controllers {
            controller.masterController = nil
            controller.close()
        }
    }
}

// ============ Controller Management
extension AppDelegate {
    @IBAction func newDocument(_ sender: Any?) {
        self.openDocument(sender)
    }
    @IBAction func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.directoryURL = settingsData.visualizationDirectory
        panel.allowedContentTypes = [UTType.visualization]
        panel.allowsMultipleSelection = true
        panel.beginSheetModal(for: self.window) { response in
            guard response == .OK && !panel.urls.isEmpty else { return }
            do {
                for url in panel.urls {
                    let visualization = try Visualization(url: url, bundles: self.bundleDictionary)
                    let controller = VisualizationController()
                    controller.masterController = self
                    controller.visualization = visualization
                    //controller.loadWindow()
                    controller.showWindow(self)
                    self.controllers.append(controller)
                    controller.window?.setFrameOrigin(visualization.visualOrigin)
                }
            }
            catch {
                NSAlert(error: GeneralError(errorMessage: "Error opening visualization: \(panel.url!.path())" , failure: error.localizedDescription)).beginSheetModal(for: self.window)
            }
        }

    }
    func windowWillClose( controller:VisualizationController) {
        for index in 0..<controllers.count {
            if controller == controllers[index] {
                controllers.remove(at: index)
                break
            }
        }
    }
}
