import Cocoa

class DismissSegue: NSStoryboardSegue {
    
    var nextViewControllerIdentifier:String?
    
    override func perform() {
        let src = self.sourceController as NSViewController
        let windowController = src.view.window!.windowController() as TopLevelWindowController
        
        src.view.removeFromSuperview()
        src.removeFromParentViewController()
        
        if let identifier = nextViewControllerIdentifier {
            windowController.setNewViewController(identifier)
        }
    }
}

class TopLevelWindowController: NSWindowController {
    
    /// This is the view and controller under which the various app subviews will be loaded.
    /// Connects themselves automatically - see MainContentViewController.viewDidAppear()
    var containerView: NSView!
    var containerViewController: ContainerViewController! {
        didSet {
            // setNewViewController depends on containerViewController being set.
            setNewViewController("OptionsView")
        }
    }
    
    // MARK: Setting a new view controller
    
    func setNewViewController(identifier: String) {
        // Create and set up the new view controller and view.
        let viewController = storyboard!.instantiateControllerWithIdentifier(identifier) as NSViewController
        let view = viewController.view
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(viewController.view)
        containerViewController.addChildViewController(viewController)
        containerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: nil, metrics: nil, views: ["view": view]))
        containerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: nil, metrics: nil, views: ["view": view]))
    }
}

// This class just immediately connects itself to the top level window controller
class ContainerViewController: NSViewController {
    
    @IBOutlet var containerView: NSView!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        if let window = view.window {
            if let topLevelWindowController = window.windowController() as? TopLevelWindowController {
                topLevelWindowController.containerView = containerView
                topLevelWindowController.containerViewController = self
            }
        }
    }
}