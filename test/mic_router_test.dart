import 'package:flutter_test/flutter_test.dart';
import 'package:mic_router/mic_router.dart';
import 'package:mic_router/mic_router_method_channel.dart';
import 'package:mic_router/mic_router_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMicRouterPlatform
    with MockPlatformInterfaceMixin
    implements MicRouterPlatform {
  @override
  Future<Map<String, dynamic>> getMicInfo() => Future.value({});

  @override
  Future<bool> setMic(String id) {
    throw UnimplementedError();
  }
}

void main() {
  final MicRouterPlatform initialPlatform = MicRouterPlatform.instance;

  test('$MethodChannelMicRouter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMicRouter>());
  });

  test('getPlatformVersion', () async {
    MicRouter micRouterPlugin = MicRouter();
    MockMicRouterPlatform fakePlatform = MockMicRouterPlatform();
    MicRouterPlatform.instance = fakePlatform;

    expect(await micRouterPlugin.getMicInfo(), '42');
  });
}
