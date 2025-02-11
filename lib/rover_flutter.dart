import 'package:rover_flutter/rover_flutter_receipt.dart';
import 'package:rover_flutter/rover_flutter_delegate.dart';

export 'package:rover_flutter/rover_flutter_receipt.dart';
export 'package:rover_flutter/rover_flutter_delegate.dart';

import 'rover_flutter_platform_interface.dart';

String? iso8601(DateTime? dt) {
  if (dt == null) {
    return null;
  }
  String iso8601WithMilliseconds = dt.toIso8601String();
  if (iso8601WithMilliseconds.contains("Z")) {
    iso8601WithMilliseconds.split('.')[0];
  }
  // ignore: prefer_interpolation_to_compose_strings
  return iso8601WithMilliseconds.split('.')[0] + "Z";
}

class RoverFlutter {
  final String staging = "ROVER_STAGING";
  final String production = "ROVER_PRODUCTION";

  Future<String> version() {
    return RoverFlutterPlatform.instance.version();
  }

  Future<String> coreVersion() {
    return RoverFlutterPlatform.instance.coreVersion();
  }

  Future<List<String>> featureFlags() {
    return RoverFlutterPlatform.instance.featureFlags();
  }

  /// When you call configure, you supply the license key associated with your Rover account. Rover will then
  /// confirm your license key is valid, and return to you the list of Merchants authorized by your license key.
  /// It is advisable that you use this array of merchants to drive the merchants available in your app, as
  /// opposed to hard coding merchants in your app. By doing this, your Rover installation can automatically
  /// use new merchants as they are released without needing a native update to your app.
  ///
  /// Configure may be safely called multiple times and as often as you like. Actually checks to the license
  /// server will be throttled to once every 30 seconds when a cached version is available.
  ///
  /// [Optional] Set enviroment to .production when building the production version of your app.
  /// [Optional] Set deviceId to a "unique identifier" for this app installation
  /// [Optional] Set maxConcurrentCollections to the number of concurrent collections to allow
  /// Callback will return an array of merchants and an optional error.
  Future<List<MerchantStruct>> configure({
    required String licenseKey,
    String environment = "ROVER_STAGING",
    String? deviceId,
    int? maxConcurrentCollections,
  }) {
    return RoverFlutterPlatform.instance.configure({
      'licenseKey': licenseKey,
      'environment': environment,
      'deviceId': deviceId,
      'maxConcurrentCollections': maxConcurrentCollections,
    });
  }

  /// Call collect when you are ready for a collection to take place. Override the specific options
  /// you need to achieve the behaviour your want.
  ///
  /// userId: a unique identifier to reference this user of your app. This is typically a value from
  ///         your own backend services and is used to perform troubleshooting at your request.
  ///         (ie "our user 12345 experienced this issue please help")
  /// account: (override) the account name for the merchant you want to connect to. If this is a new connection
  ///          then leave this value as nil.
  /// password: (override) the password for the account you want to connect to. If this is unknown then leave as nil.
  /// cookiesBase64: (override) the cookies session used for this connection. If this is unknown then leave as nil.
  /// merchantId: the integer id for the merchant you want to connect to. As Rover supports adding new merchants dynamically,
  ///             you should send the raw value you receive from the Merchants array return of configure call
  /// javascript: (override) the logic specific to this merchant. If this is unknown then leave as nil.
  /// javascriptUrl: (override) url to the logic specific to this merchant. If this is unknown then leave as nil.
  /// javascriptVersion: (override) specify a specific version of this merchant to use. If this is unknown then leave as nil. Set to 0 to use local version.
  /// fromDate: (required) specify how far back in the account you want to collect from.
  /// toDate: (optional) don't return data for dates >= this value
  /// serviceGroupRequests: (optional) service group specific continuation data. If this is unknown then leave as nil.
  /// tier1BatchSize: (default) how many T1 data results to return at a time. What "T1" means is specific to each merchant.
  /// tier2BatchSize: (default) how many T2 data results to return at a time. What "T2" means is specific to each merchant.
  /// tier3BatchSize: (default) how many T3 data results to return at a time. What "T3" means is specific to each merchant.
  /// receiptsBatchSize: (default) how many receipts should be returned to your delegate at a time
  /// collectItemInfo: (optional) instruct Rover to collect detailed item info. "Item info" is specific to each merchant. Collecting item info can negatively impact collection times and is disabled by default.
  /// collectSourceData: (optional) instruct Rover to return the sourceData used to create the normalized data. This is typically JSON specific to each merchant. Source data can increase data payloads and is disabled by default.
  /// isEphemeral: (default false) If false then a encrypted connection data will be stored to this device. This connection can then be reused in the future to re-collect from the same account.
  /// hasBackend: (default false) For simple integrations Rover will perform all of the collection locally. More advanced integrations might want to integrate with server-side services to store collection state at various points in the collection process. Set to true to enable the various roverPull/roverPush delegate callbacks.
  /// allowUserInteractionRequired (default true) Collection might encounter an error for which the user needs to resolve (for example, signing in). If allowUserInteractionRequired is enabled then Rover will automatically display a modal for the user to interact with. If you want Rover to collect solely in the background, then set this value to false.
  /// appInfo: (optional) application specific info for this specific merchant. If this is unknown then leave as nil.
  /// overrideMimicDesktopIfPossible: (optional) If this is unknown then leave as nil.
  /// overrideWebviewBlockImageLoading: (optional) If this is unknown then leave as nil.
  /// delegate: (required) An instance of RoverDelegate() to service this collection.
  Future<void> collect(
      {String? userId,
      String? account,
      String? password,
      String? cookiesBase64,
      required int merchantId,
      String? javascriptUrl,
      int? javascriptVersion,
      required DateTime fromDate,
      DateTime? toDate,
      int? tier1BatchSize,
      int? tier2BatchSize,
      int? tier3BatchSize,
      int? receiptsBatchSize,
      bool? collectItemInfo,
      bool? collectSourceData,
      bool? isEphemeral,
      bool? hasBackend,
      bool? allowUserInteractionRequired,
      String? appInfo,
      List<String>? featureFlags,
      bool? overrideMimicDesktopIfPossible,
      bool? overrideWebviewBlockImageLoading,
      required RoverDelegate delegate}) {
    return RoverFlutterPlatform.instance.collect({
      'delegateUUID': delegate.uuid,
      'userId': userId,
      'account': account,
      'password': password,
      'cookiesBase64': cookiesBase64,
      'merchantId': merchantId,
      'javascriptUrl': javascriptUrl,
      'javascriptVersion': javascriptVersion,
      'fromDate': iso8601(fromDate),
      'toDate': iso8601(toDate),
      'tier1BatchSize': tier1BatchSize,
      'tier2BatchSize': tier2BatchSize,
      'tier3BatchSize': tier3BatchSize,
      'receiptsBatchSize': receiptsBatchSize,
      'collectItemInfo': collectItemInfo,
      'collectSourceData': collectSourceData,
      'isEphemeral': isEphemeral,
      'hasBackend': hasBackend,
      'allowUserInteractionRequired': allowUserInteractionRequired,
      'appInfo': appInfo,
      'featureFlags': featureFlags,
      'overrideMimicDesktopIfPossible': overrideMimicDesktopIfPossible,
      'overrideWebviewBlockImageLoading': overrideWebviewBlockImageLoading
    }, delegate);
  }

  /// Cancel a collection session. sessionUUID is returned in the RoverDelegate
  /// Pass in the sessionUUID of the active collection
  Future<void> cancel({required String sessionUUID}) {
    return RoverFlutterPlatform.instance.cancel({
      'sessionUUID': sessionUUID,
    });
  }

  /// Cancel all collection sessions
  Future<void> cancelAll() {
    return RoverFlutterPlatform.instance.cancelAll();
  }

  /// Retrieve the preconfig for a specific merchant
  Future<Map<String, dynamic>> preconfig(
      {String? userId,
      int? merchantId,
      String? javascriptUrl,
      int? javascriptVersion,
      required RoverDelegate delegate}) {
    return RoverFlutterPlatform.instance.preconfig({
      'userId': userId,
      'merchantId': merchantId,
      'javascriptUrl': javascriptUrl,
      'javascriptVersion': javascriptVersion,
    }, delegate);
  }

  /// Retrieve a list of connections. When a successful connection is made during a collection where isEphemeral set to false,
  /// the connection information is stored locally and encrypted.
  Future<List<ConnectionStruct>> connections() {
    return RoverFlutterPlatform.instance.connections();
  }

  /// Removes a connection stored locally to this device.
  /// Pass in account and merchantid
  Future<void> remove({required String account, required int merchantId}) {
    return RoverFlutterPlatform.instance.remove({
      'account': account,
      'merchantId': merchantId,
    });
  }
}
