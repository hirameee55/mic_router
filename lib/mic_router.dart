import 'mic_router_platform_interface.dart';

class MicRouter {
  Future<Map<String, dynamic>> getMicInfo() {
    return MicRouterPlatform.instance.getMicInfo();
  }

  Future<bool> setMic(String id) {
    return MicRouterPlatform.instance.setMic(id);
  }
}
