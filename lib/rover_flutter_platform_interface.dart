import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rover_flutter/rover_flutter_delegate.dart';
import 'package:rover_flutter/rover_flutter_receipt.dart';

import 'rover_flutter_method_channel.dart';

abstract class RoverFlutterPlatform extends PlatformInterface {
  RoverFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static RoverFlutterPlatform _instance = MethodChannelRoverFlutter();

  static RoverFlutterPlatform get instance => _instance;

  static set instance(RoverFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> sendResult(
      String hookUUID, String delegateUUID, String? argsJson, String? error) {
    throw UnimplementedError('to be implemented');
  }

  Future<String> version() {
    throw UnimplementedError('to be implemented');
  }

  Future<String> coreVersion() {
    throw UnimplementedError('to be implemented');
  }

  Future<List<String>> featureFlags() {
    throw UnimplementedError('to be implemented');
  }

  Future<List<MerchantStruct>> configure(Map<String, dynamic> args) {
    throw UnimplementedError('to be implemented');
  }

  Future<void> collect(Map<String, dynamic> args, RoverDelegate delegate) {
    throw UnimplementedError('to be implemented');
  }

  Future<void> cancel(Map<String, dynamic> args) {
    throw UnimplementedError('to be implemented');
  }

  Future<void> cancelAll() {
    throw UnimplementedError('to be implemented');
  }

  Future<Map<String, dynamic>> preconfig(
      Map<String, dynamic> args, RoverDelegate delegate) {
    throw UnimplementedError('to be implemented');
  }

  Future<List<ConnectionStruct>> connections() {
    throw UnimplementedError('to be implemented');
  }

  Future<void> remove(Map<String, dynamic> args) {
    throw UnimplementedError('to be implemented');
  }
}
