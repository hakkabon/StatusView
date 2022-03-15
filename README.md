# StatusView

This package provides a display mechanism of simple status messages for iOS written in Swift. The displayed text is meant to be short. Only title and subtitle, occupying one line each. The status views can be positioned to appear at 6 different positions, top and bottom center, and the four corners of the screen. The status views appear in white or grayish colors. The text message is aligned left, center or right, and may optionally display an image on either side of the text.

## Import Statement
First, add an import statement to *StatusView* like so:

```swift
import UIKit
import StatusView
```

## Position and animation style
You probably want to customize your notifications depending on the device type being used:

```swift
struct iPadCustomOptions : StatusOptions {
    var exitType: StatusView.ExitType { return StatusView.ExitType.slide }
    var position: StatusView.Position { return StatusView.Position.topRight }
}

struct iPhoneCustomOptions : StatusOptions {
    var exitType: StatusView.ExitType { return StatusView.ExitType.pop }
    var position: StatusView.Position { return StatusView.Position.top }
}

let customOptions: StatusOptions = UIDevice.current.userInterfaceIdiom == . pad ? iPadCustomOptions() : iPhoneCustomOptions()
```

## Display the notification
Display your notification where it is appropriate by using the `StatusView` API with the neccessary parameters supplied to . 

```swift
StatusView(title: "ERROR", subtitle: "some meaningful error message", options: customOptions).show()
```

## License
MIT
