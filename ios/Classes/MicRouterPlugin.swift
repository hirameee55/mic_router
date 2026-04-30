import Flutter
import UIKit
import AVFoundation

public class MicRouterPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "mic_router", binaryMessenger: registrar.messenger())
        let instance = MicRouterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getMicInfo":
            do {
                try setupAudioSession()
                result(getMicInfo())
            } catch {
                result(FlutterError(code: "AUDIO_SESSION_ERROR", message: error.localizedDescription, details: nil))
            }

        case "setMic":
            guard let args = call.arguments as? [String: Any],
                  let id = args["id"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "id is required", details: nil))
                return
            }

            do {
                try setupAudioSession()
                try setMic(id: id)
                result(true)
            } catch {
                result(FlutterError(code: "SET_MIC_FAILED", message: error.localizedDescription, details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}


extension MicRouterPlugin {

    // セッションのセットアップ（マイク選択前の初期化用）
    func setupAudioSession() throws {
        // 両方のデバイスをavailableInputsに出すため、まずHFPで初期化
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.allowBluetoothHFP, .allowBluetoothA2DP]
        )
        try session.setActive(true)
    }

    // マイク選択時にセッションを最適化して切り替え
    func setupAudioSessionForInput(_ input: AVAudioSessionPortDescription) throws {
        let session = AVAudioSession.sharedInstance()
        let isBluetoothMic = input.portType == .bluetoothHFP

        if isBluetoothMic {
            // BTマイクを使う場合はHFP（BT側で入出力）
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.allowBluetoothHFP]
            )
        } else {
            // 本体 or 有線マイクを使う場合はA2DP（高音質再生 + 本体録音）
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.allowBluetoothA2DP]
            )
        }
        try session.setActive(true)
    }
}

extension MicRouterPlugin {

    func setMic(id: String) throws {
        let session = AVAudioSession.sharedInstance()

        guard let inputs = session.availableInputs else {
            throw NSError(domain: "MicRouter", code: -1, userInfo: [NSLocalizedDescriptionKey: "No inputs available"])
        }

        guard let target = inputs.first(where: { $0.uid == id }) else {
            throw NSError(domain: "MicRouter", code: -2, userInfo: [NSLocalizedDescriptionKey: "Input not found"])
        }

        // 選択されたマイクに合わせてセッションを切り替えてからセット
        try setupAudioSessionForInput(target)
        try session.setPreferredInput(target)
    }
}

extension MicRouterPlugin {

    func getMicInfo() -> [String: Any] {
        let session = AVAudioSession.sharedInstance()

        let availableInputs = session.availableInputs ?? []
        let currentInput = session.currentRoute.inputs.first

        for input in availableInputs {
            print("----")
            print(" type: \(input.portType.rawValue)")
            print(" name: \(input.portName)")
            print(" uid: \(input.uid)")
        }

        if let input = currentInput {
            print("🎤 Current:")
            print(" type: \(input.portType.rawValue)")
            print(" name: \(input.portName)")
            print(" uid: \(input.uid)")
        }

        // ✅ 修正：[availableInputs.map](URL) → availableInputs.map
        return [
            "availableInputs": availableInputs.map { mapInput($0) },
            "currentInput": currentInput.map { mapInput($0) } ?? NSNull()
        ]
    }
}

extension MicRouterPlugin {

    func mapInput(_ input: AVAudioSessionPortDescription) -> [String: Any] {
        return [
            "id": input.uid,
            "name": input.portName,
            "type": input.portType.rawValue
        ]
    }
}
