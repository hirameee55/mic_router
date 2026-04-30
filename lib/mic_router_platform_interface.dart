import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mic_router_method_channel.dart';

abstract class MicRouterPlatform extends PlatformInterface {
  MicRouterPlatform() : super(token: _token);

  static final Object _token = Object();

  static MicRouterPlatform _instance = MethodChannelMicRouter();
  static MicRouterPlatform get instance => _instance;

  static set instance(MicRouterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Map<String, dynamic>> getMicInfo() async {
    throw UnimplementedError('getMicInfo() has not been implemented.');
  }

  Future<bool> setMic(String id) async {
    throw UnimplementedError('setMic() has not been implemented.');
  }
}
