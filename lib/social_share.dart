import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class SocialShare {
  static const MethodChannel _channel = const MethodChannel('social_share');

  static Future<String?> shareInstagramStory({
    required String appId,
    required String imagePath,
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? backgroundResourcePath,
    String? attributionURL,
  }) async {
    return shareMetaStory(
      appId: appId,
      platform: 'shareInstagramStory',
      imagePath: imagePath,
      backgroundTopColor: backgroundTopColor,
      backgroundBottomColor: backgroundBottomColor,
      attributionURL: attributionURL,
      backgroundResourcePath: backgroundResourcePath,
    );
  }

  static Future<String?> shareFacebookStory({
    required String appId,
    String? imagePath,
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? backgroundResourcePath,
    String? attributionURL,
  }) async {
    return shareMetaStory(
      appId: appId,
      platform: 'shareFacebookStory',
      imagePath: imagePath,
      backgroundTopColor: backgroundTopColor,
      backgroundBottomColor: backgroundBottomColor,
      attributionURL: attributionURL,
      backgroundResourcePath: backgroundResourcePath,
    );
  }

  static Future<String?> shareMetaStory({
    required String appId,
    required String platform,
    String? imagePath,
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? attributionURL,
    String? backgroundResourcePath,
  }) async {
    var _imagePath = imagePath;
    var _backgroundResourcePath = backgroundResourcePath;

    if (Platform.isAndroid) {
      final stickerFilename = 'stickerAsset.png';
      await reSaveImage(imagePath, stickerFilename);
      _imagePath = stickerFilename;
      if (backgroundResourcePath != null) {
        final backgroundImageFilename = backgroundResourcePath.split('/').last;
        await reSaveImage(backgroundResourcePath, backgroundImageFilename);
        _backgroundResourcePath = backgroundImageFilename;
      }
    }

    final args = <String, dynamic>{
      'stickerImage': _imagePath,
      'backgroundTopColor': backgroundTopColor,
      'backgroundBottomColor': backgroundBottomColor,
      'attributionURL': attributionURL,
      'appId': appId
    };

    if (_backgroundResourcePath != null) {
      final extension = _backgroundResourcePath.split('.').last;
      if (['png', 'jpg', 'jpeg'].contains(extension.toLowerCase())) {
        args['backgroundImage'] = _backgroundResourcePath;
      } else {
        args['backgroundVideo'] = _backgroundResourcePath;
      }
    }

    final response = await _channel.invokeMethod(platform, args);
    return response;
  }

  static Future<String?> shareTwitter(
    String captionText, {
    List<String>? hashtags,
    String? url,
    String? trailingText,
  }) async {
    //Caption
    var _captionText = captionText;

    //Hashtags
    if (hashtags != null && hashtags.isNotEmpty) {
      final tags = hashtags.map((t) => '#$t ').join(' ');
      _captionText = _captionText + '\n' + tags.toString();
    }

    //Url
    String _url;
    if (url != null) {
      if (Platform.isAndroid) {
        _url = Uri.parse(url).toString().replaceAll('#', '%23');
      } else {
        _url = Uri.parse(url).toString();
      }
      _captionText = _captionText + '\n' + _url;
    }

    if (trailingText != null) {
      _captionText = _captionText + '\n' + trailingText;
    }

    final args = <String, dynamic>{
      'captionText': _captionText + ' ',
    };
    final version = await _channel.invokeMethod('shareTwitter', args);
    return version;
  }

  static Future<String?> shareSms(String message,
      {String? url, String? trailingText}) async {
    Map<String, dynamic>? args;
    if (Platform.isIOS) {
      if (url == null) {
        args = <String, dynamic>{
          'message': message,
        };
      } else {
        args = <String, dynamic>{
          'message': message + ' ',
          'urlLink': Uri.parse(url).toString(),
          'trailingText': trailingText
        };
      }
    } else if (Platform.isAndroid) {
      args = <String, dynamic>{
        'message': message + (url ?? '') + (trailingText ?? ''),
      };
    }
    final version = await _channel.invokeMethod('shareSms', args);
    return version;
  }

  static Future<String?> copyToClipboard({String? text, String? image}) async {
    final args = <String, dynamic>{
      'content': text,
      'image': image,
    };
    final response =
        await _channel.invokeMethod('copyToClipboard', args);
    return response;
  }

  static Future<bool?> shareOptions(String contentText,
      {String? imagePath}) async {
    Map<String, dynamic> args;

    var _imagePath = imagePath;
    if (Platform.isAndroid) {
      if (imagePath != null) {
        final stickerFilename = 'stickerAsset.png';
        await reSaveImage(imagePath, stickerFilename);
        _imagePath = stickerFilename;
      }
    }
    args = <String, dynamic>{'image': _imagePath, 'content': contentText};
    final version = await _channel.invokeMethod('shareOptions', args);
    return version;
  }

  static Future<String?> shareWhatsapp(String content) async {
    final args = <String, dynamic>{'content': content};
    final version = await _channel.invokeMethod('shareWhatsapp', args);
    return version;
  }

  static Future<Map?> checkInstalledAppsForShare() async {
    final apps = await _channel.invokeMethod('checkInstalledApps');
    return apps;
  }

  static Future<String?> shareTelegram(String content) async {
    final args = <String, dynamic>{'content': content};
    final version = await _channel.invokeMethod('shareTelegram', args);
    return version;
  }

// static Future<String> shareSlack() async {
//   final String version = await _channel.invokeMethod('shareSlack');
//   return version;
// }

  //Utils
  static Future<bool> reSaveImage(String? imagePath, String filename) async {
    if (imagePath == null) {
      return false;
    }
    final tempDir = await getTemporaryDirectory();

    var file = File(imagePath);
    final bytes = file.readAsBytesSync();
    final stickerData = bytes.buffer.asUint8List();
    final stickerAssetName = filename;
    final stickerAssetAsList = stickerData;
    final stickerAssetPath = '${tempDir.path}/$stickerAssetName';
    file = await File(stickerAssetPath).create();
    file.writeAsBytesSync(stickerAssetAsList);
    return true;
  }
}
