[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey)]()
[![Swift Version](https://img.shields.io/badge/Swift-5.3-green.svg)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)]()

# AYOOModalBottomSheet

A custom modal presentation supporting **top offset**, **snap** and **drag**.

[TOC]

------------

# Installation

### Swift Package
Adding to project:
> File > Swift Packages > Add Package Dependency

`https://github.com/andriyyezerskiy/modalbottomsheet`

Adding as dependancy to Swift Package:

`.package(url: "https://github.com/andriyyezerskiy/modalbottomsheet", from: "1.0.0")`

# Usage

Implement following extension in the presenting ViewController:

```swift
extension MyViewController: UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return ModalBottomSheet(presentedViewController: presented, presenting: presenting, blurEffectStyle: .dark)
    }
    
}
```

Initialise and present modal ViewController:

```swift
let viewController = ModalViewController()
viewController.modalPresentationStyle = .custom
viewController.transitioningDelegate = self
self.present(viewController, animated: true)
```
