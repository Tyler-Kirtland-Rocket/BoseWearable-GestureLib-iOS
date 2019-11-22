# Installation Guide

The Bose Gesture Library for iOS is distributed as a binary framework via direct download or as a CocoaPod.

## CocoaPods

In order to install the Bose Gesture Library as a pod in your project, add it to your `PodFile`:

```swift
platform :ios, '12.0'
use_frameworks!

source 'git@github.com:Bose/BoseWearableSpecs.git'

target 'MyApp' do
    pod 'BoseGesture'
end

```

## Manual Integration

In the example given below, we will assume you have put the contents of the zip file downloaded from GitHub at `$PROJECT_DIR/Libraries/BoseGesture`, but you may place them anywhere in your source tree. We recommend committing this to source control with the rest of your project.

- Open the folder in which you place the unzipped distribution folder. Drag the `Frameworks` folder into the Project Navigator of your application's Xcode project, dropping it under the target's source folder. In the ensuing sheet, select "Copy items if needed", "Create groups", and select your app target under "Add to targets". This will create the following item in your project:
    - `Frameworks/BoseGesture.framework`
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- The newly-included `framework` will appear.
- Select the frameworks: `BoseGesture.framework`.
- Go to your target's "Build Settings" panel and search for 'Framework Search Paths'.
- Set the value to $(SRCROOT)/../Libraries/Frameworks. Note that your individual project structure may differ, you should set this value to be where the 'Frameworks' folder you unzipped is located.
- Build and run your project to verify this all worked.

> The `BoseGesture` framework is automatically added to Target Dependencies, Link Binary with Libraries, and Embed Frameworks in your app's Build Phases. This is all you need to build and run in the simulator or on a device.

The frameworks included in the manual integration contain code for all supported architectures (x86_64 and arm64). This allows you to run your app in the iOS simulator even though the simulator does not support Bluetooth communication (required for the BoseWearable SDK).

A binary that contains the simulator architecture will be rejected by Apple when submitting to the App Store or TestFlight. To remedy this, you need to add a script to your build process that strips unused frameworks from your app's build.

On the "Build Phases" tab of your app target, add a "Run Script" phase with the command:

```shell
bash "${PROJECT_DIR}/Libraries/BoseGesture/bin/strip-frameworks.sh"
```

Check the "Run script only when installing" checkbox.

This phase should be the last phase for your target.
