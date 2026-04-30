import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mic_router_platform_interface.dart';

class MethodChannelMicRouter extends MicRouterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('mic_router');

  @override
  Future<Map<String, dynamic>> getMicInfo() async {
    final result = await methodChannel.invokeMethod('getMicInfo');
    if (result == null) return {};

    return Map<String, dynamic>.from(result);
  }

  @override
  Future<bool> setMic(String id) async {
    final result = await methodChannel.invokeMethod('setMic', {'id': id});
    return result == true;
  }
}
