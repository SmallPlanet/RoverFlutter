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

// 1. Create a new connection to a merchant
// userId: [optional] identifier you provide and passed through by Rover
// account: [optional] account name for this merchant to connect to (nil for new connection)
// merchantId: the identifier for the merchant to connect to (passed back in configure merchants array)
// fromDate: how far back you'd like to collect receipts
// collectItemInfo: [optional] collect extra information about items when possible (like UPC)
// isEphemeral: [optional] encrypt and store this connection locally to reconnect at later date
// note: see header for full list of parameters

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

## Background Collection

[Rover iOS](https://github.com/SmallPlanet/RoveriOS) supports BGProcessingTask and [Rover Android](https://github.com/SmallPlanet/RoverAndroid) supports WorkManager for performing periodic collections without user interaction.

- In your Dart code you will add the logic for which connections to collect from when the time for periodic collection happens. Both WorkManager on Android and BGProcessingTask on iOS will call this method for scheduling collections.

```dart
final rover = RoverFlutter();

@pragma('vm:entry-point')
void scheduleBackgroundCollections() {
	WidgetsFlutterBinding.ensureInitialized();
	
	rover.scheduleBackgroundCollections(
	    collectionWillStart: (taskIdentifier) async {
	        // When the time comes to collect in the background this code will run.
	        // You should call collect() for the connections you would like to refresh.
	        // This allows you to implement custom logic to fit your business needs (for example,
	        // if one connection is higher priority than another or needs to be refreshed more
	        // often than another). Note that the amount of time allowed to collections is
	        // typically limited to a few minutes.
	
	        // Be certain to call configure() here as there is no guarantee it will
	        // be run elsewhere when running from the background.
	        await rover.configure(
	            licenseKey: "MY_ROVER_LICENSE_KEY",
	            environment: rover.staging,
	        );
	        final connections = await rover.connections();
	        for (final connection in connections) {
	            final delegate = MyRoverBackgroundDelegate();
	            await rover.collect(
	                account: connection.account,
	                merchantId: connection.merchantId,
	                fromDate: connection.fromDate ?? DateTime.parse('2023-01-01T00:00:00Z'),
	                isEphemeral: false,
	                allowUserInteractionRequired: false,
	                delegate: delegate,
	            );
	            debugPrint('background collection scheduled for '
	                '[${connection.merchantId}] ${connection.account}');
	        }
	    },
	    collectionWillFinish: (taskIdentifier, connections) {
	        debugPrint('background collection finished for ${connections.length} connections');
	    }
	);
}
```

### iOS

- Follow the instructions on [Rover iOS](https://github.com/SmallPlanet/RoveriOS) for enabling background capabilities and adding **com.smallplanet.rover.processing** to your Info.plist.
- Add the initialization call to your iOS AppDelegate's didFinishLaunchingWithOptions callback.

```swift
import rover_flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Add this call to initilize periodic background collection every 24 hours
    RoverFlutterPlugin.initBackgroundCollection(interval: 60 * 60 * 24)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Android

- Create a Worker class in which you will call `RoverFlutterPlugin.scheduleBackgroundCollections()`
- Call RoverFlutterPlugin.initBackgroundCollection(applicationContext) in your application onCreate
- Schedule your Worker class for periodic work via the WorkManager API

```kotlin
class MyApplication(): FlutterApplication() {
    override fun onCreate() {
        super.onCreate()

		 // Creates a background FlutterEngine
        RoverFlutterPlugin.initBackgroundCollection(applicationContext)

        // Schedule periodic background collections
        val constraints = Constraints.Builder()
          .setRequiredNetworkType(NetworkType.CONNECTED)
          .setRequiresBatteryNotLow(true)
          .build()
        val request = PeriodicWorkRequestBuilder<BackgroundCollectionWorker>(24, TimeUnit.HOURS)
          .setInitialDelay(24, TimeUnit.HOURS)
          .setConstraints(constraints)
          .build()
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "BackgroundCollectionWorker",
            ExistingPeriodicWorkPolicy.UPDATE,
            request
        )
    }
}

// WorkManager worker subclass; call RoverFlutterPlugin.scheduleBackgroundCollections(context)
class BackgroundCollectionWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): ListenableWorker.Result {
        return RoverFlutterPlugin.scheduleBackgroundCollections(context)
    }
}
```

## iOS Setup

RoveriOS supports iOS 13.4 and above; you may need to set this in your ios/Podfile:

```
platform :ios, '13.4'
```

On Dec 2 2026 CocoaPods trunk is being made read only. To help bridge the gap as we transition from CocoaPods to Swift Package Manager we are publishing Rover iOS on our own CocoaPods spec repo. Add these lines to the top of your `ios/Podfile`:

```ruby
source 'https://github.com/SmallPlanet/RoverPods.git'
source 'https://cdn.cocoapods.org/'
```

## Android Setup

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

### FlutterFragmentActivity

Rover requires the use of Fragments; ensure that the Activity you are using with Rover is a subclass of FlutterFragmentActivity

```
class MainActivity: FlutterFragmentActivity()
```

### Webkit

If you Android project lists a dependency for **androidx.webkit:webkit** please ensure it is version ** 1.14.0** or higher.
```kotlin
dependencies {
	// Rover supports features added in 1.14.0 and above; please ensure you specify at least this version of androidx.webkit
	implementation 'androidx.webkit:webkit:1.14.0'
}
```

### Proguard

If your Android app has proguard enabled, please add the following rules:

```
-keep class com.smallplanet.** { *; }
-keep class com.rover.** { *; }
```

## SDK Integration

To use Rover in your Flutter application add the following dependency to your pubspec.yaml:

```sh
# To reference the latest Rover Flutter
dependencies:
  rover_flutter:
    git:
      url: https://github.com/SmallPlanet/RoverFlutter.git
      ref: main

# To reference a specific version of Rover Flutter
dependencies:
  rover_flutter:
    git:
      url: https://github.com/SmallPlanet/RoverFlutter.git
      ref: v0.0.4
```



Latest version: v0.1.4
