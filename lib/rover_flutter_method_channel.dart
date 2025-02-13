import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rover_flutter/rover_flutter_delegate.dart';
import 'package:rover_flutter/rover_flutter_receipt.dart';

import 'rover_flutter_platform_interface.dart';
import 'dart:convert';

class MethodChannelRoverFlutter extends RoverFlutterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('smallplanet.com/rover_flutter');

  Map<String, RoverDelegate> delegates = {};

  MethodChannelRoverFlutter() {
    methodChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == "callDelegate") {
        String argsJson = call.arguments["argsJson"];
        Map<String, dynamic> args = jsonDecode(argsJson);

        String? hookUUID = call.arguments["hookUUID"];
        if (hookUUID == null) {
          throw StateError('hookUUID $hookUUID does not exist');
        }

        String delegateUUID = args["delegateUUID"];
        String delegateFunc = args["delegateFunc"];

        RoverDelegate? delegate = delegates[delegateUUID];
        if (delegate == null) {
          throw StateError('delegate $delegateUUID does not exist');
        }

        try {
          switch (delegateFunc) {
            case "roverDidFinish":
              delegate.roverDidFinish(args["sessionUUID"], args["error"],
                  args["userError"], args["verboseError"]);
              RoverFlutterPlatform.instance
                  .sendResult(hookUUID, delegate.uuid, null, null);
              delegates.remove(delegateUUID);
              break;
            case "roverDidInit":
              delegate.roverDidInit(args["sessionUUID"], args["scrapeRequest"],
                  (scrapeRequest, error) {
                RoverFlutterPlatform.instance.sendResult(
                    hookUUID, delegate.uuid, jsonEncode(scrapeRequest), error);
              });
              break;
            case "roverDidCollect":
              delegate.roverDidCollect(
                  args["sessionUUID"], args["receipts"].cast<ReceiptStruct>());
              RoverFlutterPlatform.instance
                  .sendResult(hookUUID, delegate.uuid, null, null);
              break;
            case "roverHasStatus":
              delegate.roverHasStatus(
                  args["sessionUUID"],
                  args["progress"].toDouble(),
                  args["stepProgress"].toDouble(),
                  args["currentStep"],
                  args["maxSteps"],
                  args["merchantVersion"],
                  args["tagLog"].cast<String>(),
                  args["userTag"]);
              RoverFlutterPlatform.instance
                  .sendResult(hookUUID, delegate.uuid, null, null);
              break;
            case "roverAccountDidLogin":
              delegate.roverAccountDidLogin(
                  args["sessionUUID"],
                  args["oldAccount"],
                  args["newAccount"],
                  args["password"],
                  args["cookiesBase64"], (error, appInfo) {
                RoverFlutterPlatform.instance
                    .sendResult(hookUUID, delegate.uuid, appInfo, error);
              });
              break;
          }
        } catch (e, stackTrace) {
          debugPrint("Exception caught: $e");
          debugPrint("StackTrace: $stackTrace");
        }
      }
    });
  }

  @override
  Future<void> sendResult(String hookUUID, String delegateUUID,
      String? argsJson, String? error) async {
    await methodChannel.invokeMethod<String>(
        'sendResult',
        jsonEncode({
          "hookUUID": hookUUID,
          "delegateUUID": delegateUUID,
          "argsJson": argsJson,
          "error": error
        }));
  }

  @override
  Future<String> version() async {
    final value = await methodChannel.invokeMethod<String>('version');
    if (value == null) {
      throw StateError('configure returned null');
    }
    return value;
  }

  @override
  Future<String> coreVersion() async {
    final value = await methodChannel.invokeMethod<String>('coreVersion');
    if (value == null) {
      throw StateError('configure returned null');
    }
    return value;
  }

  @override
  Future<List<String>> featureFlags() async {
    final value = await methodChannel.invokeMethod<String>('featureFlags');
    if (value == null) {
      throw StateError('configure returned null');
    }
    return List<String>.from(jsonDecode(value));
  }

  @override
  Future<List<MerchantStruct>> configure(Map<String, dynamic> args) async {
    final value =
        await methodChannel.invokeMethod<String>('configure', jsonEncode(args));
    if (value == null) {
      throw StateError('configure returned null');
    }
    return (jsonDecode(value) as List)
        .map((merchant) => MerchantStruct.fromJson(merchant))
        .toList();
  }

  @override
  Future<void> collect(
      Map<String, dynamic> args, RoverDelegate delegate) async {
    delegates[delegate.uuid] = delegate;
    args["delegateUUID"] = delegate.uuid;
    await methodChannel.invokeMethod<String>('collect', jsonEncode(args));
  }

  @override
  Future<void> cancel(Map<String, dynamic> args) async {
    await methodChannel.invokeMethod<String>('cancel', jsonEncode(args));
  }

  @override
  Future<void> cancelAll() async {
    await methodChannel.invokeMethod<String>('cancelAll', "{}");
  }

  @override
  Future<Map<String, dynamic>> preconfig(
      Map<String, dynamic> args, RoverDelegate delegate) async {
    delegates[delegate.uuid] = delegate;
    args["delegateUUID"] = delegate.uuid;
    final value =
        await methodChannel.invokeMethod<String>('preconfig', jsonEncode(args));
    if (value == null) {
      throw StateError('preconfig returned null');
    }
    return jsonDecode(value);
  }

  @override
  Future<List<ConnectionStruct>> connections() async {
    final value = await methodChannel.invokeMethod<String>('connections', "{}");
    if (value == null) {
      throw StateError('connections returned null');
    }
    return (jsonDecode(value) as List)
        .map((connection) => ConnectionStruct.fromJson(connection))
        .toList();
  }

  @override
  Future<void> remove(Map<String, dynamic> args) async {
    await methodChannel.invokeMethod<String>('remove', jsonEncode(args));
  }
}
