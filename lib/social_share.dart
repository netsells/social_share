import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ShareResult {
  final String response;

  const ShareResult._(this.response);

  static const success = ShareResult._('success');
  static const error = ShareResult._('error');
  static const appNotFound = ShareResult._('not_found');

  factory ShareResult({required String? response}) {
    switch (response) {
      case 'success':
        return ShareResult.success;
      case 'error':
        return ShareResult.error;
      case 'not_found':
        return ShareResult.appNotFound;
      default:
        return ShareResult.error;
    }
  }

  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? success,
    TResult Function()? error,
    TResult Function()? appNotFound,
    required TResult orElse(),
  }) {
    switch (this) {
      case ShareResult.success:
        if (success != null) return success();
        break;
      case ShareResult.error:
        if (error != null) return error();
        break;
      case ShareResult.appNotFound:
        if (appNotFound != null) return appNotFound();
        break;
    }

    return orElse();
  }
}

class SocialShare {
  static const MethodChannel _channel = const MethodChannel('social_share');

  static Future<ShareResult?> shareInstagramPost(String imagePath) async {
    if (Platform.isIOS) {
      final String? response =
          await _channel.invokeMethod('shareInstagramPost');
      return ShareResult(response: response);
    } else if (Platform.isAndroid) {
      final response = await _channel.invokeMethod(
        'shareInstagramPost',
        <String, dynamic>{
          "stickerImage": imagePath,
        },
      );
      return ShareResult(response: response);
    }
  }

  static Future<ShareResult?> shareInstagramStory(
    String imagePath, {
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? attributionURL,
    String? backgroundImagePath,
  }) async {
    Map<String, dynamic> args;
    if (Platform.isIOS) {
      args = <String, dynamic>{
        "stickerImage": imagePath,
        "backgroundImage": backgroundImagePath,
        "backgroundTopColor": backgroundTopColor,
        "backgroundBottomColor": backgroundBottomColor,
        "attributionURL": attributionURL
      };
    } else {
      final tempDir = await getTemporaryDirectory();

      File file = File(imagePath);
      Uint8List bytes = file.readAsBytesSync();
      var stickerData = bytes.buffer.asUint8List();
      String stickerAssetName = 'stickerAsset.png';
      final Uint8List stickerAssetAsList = stickerData;
      final stickerAssetPath = '${tempDir.path}/$stickerAssetName';
      file = await File(stickerAssetPath).create();
      file.writeAsBytesSync(stickerAssetAsList);

      String? backgroundAssetName;
      if (backgroundImagePath != null) {
        File backgroundImage = File(backgroundImagePath);
        Uint8List backgroundImageData = backgroundImage.readAsBytesSync();
        backgroundAssetName = 'backgroundAsset.jpg';
        final Uint8List backgroundAssetAsList = backgroundImageData;
        final backgroundAssetPath = '${tempDir.path}/$backgroundAssetName';
        File backFile = await File(backgroundAssetPath).create();
        backFile.writeAsBytesSync(backgroundAssetAsList);
      }

      args = <String, dynamic>{
        "stickerImage": stickerAssetName,
        "backgroundImage": backgroundAssetName,
        "backgroundTopColor": backgroundTopColor,
        "backgroundBottomColor": backgroundBottomColor,
        "attributionURL": attributionURL,
      };
    }
    final String? response = await _channel.invokeMethod(
      'shareInstagramStory',
      args,
    );
    return ShareResult(response: response);
  }

  static Future<ShareResult?> shareFacebookStory(
      String imagePath,
      String backgroundTopColor,
      String backgroundBottomColor,
      String attributionURL,
      {String? appId}) async {
    Map<String, dynamic> args;
    if (Platform.isIOS) {
      args = <String, dynamic>{
        "stickerImage": imagePath,
        "backgroundTopColor": backgroundTopColor,
        "backgroundBottomColor": backgroundBottomColor,
        "attributionURL": attributionURL,
      };
    } else {
      File file = File(imagePath);
      Uint8List bytes = file.readAsBytesSync();
      var stickerdata = bytes.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      String stickerAssetName = 'stickerAsset.png';
      final Uint8List stickerAssetAsList = stickerdata;
      final stickerAssetPath = '${tempDir.path}/$stickerAssetName';
      file = await File(stickerAssetPath).create();
      file.writeAsBytesSync(stickerAssetAsList);
      args = <String, dynamic>{
        "stickerImage": stickerAssetName,
        "backgroundTopColor": backgroundTopColor,
        "backgroundBottomColor": backgroundBottomColor,
        "attributionURL": attributionURL,
        "appId": appId
      };
    }
    final String? response =
        await _channel.invokeMethod('shareFacebookStory', args);
    return ShareResult(response: response);
  }

  static Future<ShareResult?> shareTwitter(String captionText,
      {List<String>? hashtags, String? url, String? trailingText}) async {
    Map<String, dynamic> args;
    String modifiedUrl;
    if (Platform.isAndroid) {
      modifiedUrl = Uri.parse(url!).toString().replaceAll('#', "%23");
    } else {
      modifiedUrl = Uri.parse(url!).toString();
    }
    if (hashtags != null && hashtags.isNotEmpty) {
      String tags = "";
      hashtags.forEach((f) {
        tags += ("%23" + f.toString() + " ").toString();
      });
      args = <String, dynamic>{
        "captionText": captionText + "\n" + tags.toString(),
        "url": modifiedUrl,
        "trailingText":
            (trailingText == null || trailingText.isEmpty) ? "" : trailingText
      };
    } else {
      args = <String, dynamic>{
        "captionText": captionText + " ",
        "url": modifiedUrl,
        "trailingText":
            (trailingText == null || trailingText.isEmpty) ? "" : trailingText
      };
    }
    final String? response = await _channel.invokeMethod('shareTwitter', args);
    return ShareResult(response: response);
  }

  static Future<ShareResult?> shareSms(String message,
      {String? url, String? trailingText}) async {
    Map<String, dynamic>? args;
    if (Platform.isIOS) {
      if (url == null) {
        args = <String, dynamic>{
          "message": message,
        };
      } else {
        args = <String, dynamic>{
          "message": message + " ",
          "urlLink": Uri.parse(url).toString(),
          "trailingText": trailingText
        };
      }
    } else if (Platform.isAndroid) {
      args = <String, dynamic>{
        "message": message + url! + trailingText!,
      };
    }
    final String? response = await _channel.invokeMethod('shareSms', args);
    return ShareResult(response: response);
  }

  static Future<ShareResult?> copyToClipboard(content) async {
    final Map<String, String> args = <String, String>{
      "content": content.toString()
    };
    final String? response =
        await _channel.invokeMethod('copyToClipboard', args);
    return ShareResult(response: response);
  }

  static Future<ShareResult?> shareOptions(String contentText,
      {String? imagePath}) async {
    Map<String, dynamic> args;
    if (Platform.isIOS) {
      args = <String, dynamic>{"image": imagePath, "content": contentText};
    } else {
      if (imagePath != null) {
        File file = File(imagePath);
        Uint8List bytes = file.readAsBytesSync();
        var imagedata = bytes.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        String imageName = 'stickerAsset.png';
        final Uint8List imageAsList = imagedata;
        final imageDataPath = '${tempDir.path}/$imageName';
        file = await File(imageDataPath).create();
        file.writeAsBytesSync(imageAsList);
        args = <String, dynamic>{"image": imageName, "content": contentText};
      } else {
        args = <String, dynamic>{"image": imagePath, "content": contentText};
      }
    }
    final String? response = await _channel.invokeMethod('shareOptions', args);
    return ShareResult(response: response);
  }

  static Future<ShareResult?> shareWhatsapp(String content) async {
    final Map<String, dynamic> args = <String, dynamic>{"content": content};
    final String? response = await _channel.invokeMethod('shareWhatsapp', args);
    return ShareResult(response: response);
  }

  static Future<Map?> checkInstalledAppsForShare() async {
    final Map? apps = await _channel.invokeMethod('checkInstalledApps');
    return apps;
  }

  static Future<ShareResult?> shareTelegram(String content) async {
    final Map<String, dynamic> args = <String, dynamic>{"content": content};
    final String? response = await _channel.invokeMethod('shareTelegram', args);
    return ShareResult(response: response);
  }

// static Future<String> shareSlack() async {
//   final String version = await _channel.invokeMethod('shareSlack');
//   return version;
// }
}
