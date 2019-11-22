# Sample Code

There is one example project provided:

- `GestureExample` provides a simple example of how to use the Bose Gesture library.

### GestureExample Dependencies:

The example relies on `BoseWearable` frameworks for connecting to a Bose device and receiving orientation information from the device. 

* BoseWearable.framework
* BLECore.framework
* Logging.framework

CocoaPods is used to integrate the `BoseWearable` dependencies. Instructions to install CocoaPods are available [here](https://github.com/CocoaPods/CocoaPods).
### GestureExample Installation

Open a Terminal in the root of the BoseWearable-GestureLib-iOS project. Run the following commands:

```shell
$ cd Examples/GestureExample

$ pod install

$ open GestureExample.xcworkspace
```

1. Change the project target's signing team to your team.
1. Build and run. You must run on a physical device to be able to use Bluetooth and connect to a Bose device.
