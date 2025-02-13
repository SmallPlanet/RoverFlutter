## Usage

```dart
import 'package:rover_flutter/rover_flutter.dart';

// To interact with a Rover collector you provide a RoverDelegate. A minimal
// delegate would know when the collection is finished (either successfully or
// as a result of an error) and be able to process any receipts collected.
//
// IMPORTANT NOTE: Some delegate methods provide a callback. Collection will not continue
// until the callback is made.
class MyRoverDelegate extends RoverDelegate {
  @override
  void roverDidFinish(String sessionUUID, String? error, String? userError,
      String? verboseError) {
    debugPrint("MyRoverDelegate: roverDidFinish: $error");
  }

  @override
  void roverDidCollect(String sessionUUID, List<ReceiptStruct> receipts) {
    debugPrint("MyRoverDelegate: roverDidCollect: ${receipts.length} receipts");
  }
}
```

```dart
final rover = RoverFlutter();

// Note: You will need to call configure to provide your license key
// and receive the list of merchants you will be able to collect from.
// Each merchant will be an int identifier and a user facing name
// You may call configure multiple times if you wish.
try {
  roverMerchants = await rover.configure(
      licenseKey: "MY_ROVER_LICENSE_KEY",
      deviceId: null,
      environment: rover.staging,
      maxConcurrentCollections: 4);
} catch (e, stackTrace) {
  debugPrint("Exception caught: $e");
  debugPrint("StackTrace: $stackTrace");
}

// When you are ready to connect and collect from a merchant, call 
// Rover.collect() with the desired merchant id, the date back to
// which Rover should collect from, and your delegate instance
// to collect the results with
DateTime date = DateTime.parse('2023-01-01T00:00:00Z');

MyRoverDelegate delegate = MyRoverDelegate();
try {
  await rover.collect(
      account: null,
      merchantId: merchant.merchantId,
      fromDate: date,
      isEphemeral: false,
      allowUserInteractionRequired: true,
      delegate: delegate);
} catch (e, stackTrace) {
  debugPrint("Exception caught: $e");
  debugPrint("StackTrace: $stackTrace");
}

// 2. List current merchant connections
// connections: array of existing merchant connections
List<ConnectionStruct> roverConnections = await rover.connections();

// 3. Recollect from an existing connection
MyRoverDelegate delegate = MyRoverDelegate();
try {
  await rover.collect(
      account: connection.account,
      merchantId: merchant.merchantId,
      fromDate: date,
      isEphemeral: false,
      allowUserInteractionRequired: true,
      delegate: delegate);
} catch (e, stackTrace) {
  debugPrint("Exception caught: $e");
  debugPrint("StackTrace: $stackTrace");
}

// 4. Remove a connection
rover.remove(account: connection.account, merchantId: connection.merchantId);


```

## Android

In your Android project, please add the following overrides to a custom subclass of Application.

```kotlin
import com.smallplanet.rover_flutter.RoverFlutterPlugin
import io.flutter.app.FlutterApplication

// Create a custom subclass of Application and provide the following overrides
class MyApplication(): FlutterApplication() {
    override fun getPackageName(): String? {
        return RoverFlutterPlugin.getPackageName() ?: super.getPackageName()
    }

    override fun getPackageManager(): PackageManager {
        return RoverFlutterPlugin.getPackageManager(
            super.getPackageName(),
            super.getPackageManager()
        ) ?: super.getPackageManager()
    }
}

// In your AndroidManifest.xml:
// <application android:name=".MyApplication"
```

### Proguard

If your Android app has proguard enabled, please add the following rules:

```
-keep class com.smallplanet.** { *; }
-keep class com.rover.** { *; }
```

## macOS

Ensure your application has **Outgoing Connections** enabled in **Signing & Capabilities** section in Xcode.

## SDK Integration

To use Rover in your Flutter application add the following dependency to your pubspec.yaml:

```sh
dependencies:
  rover_flutter:
    git:
      url: https://github.com/SmallPlanet/RoverFlutter.git
      ref: main
```



Latest version: v0.0.4
