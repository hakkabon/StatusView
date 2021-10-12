# StatusView

This package provides a display mechanism of simple status messages for iOS written in Swift. The status views can be positioned to appear at 6 different positions, top and bottom center, and the four corners of the screen. The status views appear in white or grayish colors. The text message is aligned left, center or right, and may optionally display an image on either side of the text. An example is shown in the animation below.
![stacked notifications look like this](https://github.com/hakkabon/Assets/blob/master/notifications.gif)

## Import Statement
First, add an import statement to *StatusView* like so:

```swift
import UIKit
import StatusView
```

## Position and animation style
You probably want to customize your notifications depending on the device type being used:
