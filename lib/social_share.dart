import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

const MethodChannel _channel = const MethodChannel('social_share');

class SocialShare {
  final String facebookAppId;

  SocialShare({
    required this.facebookAppId,
  });

  Future<String?> shareInstagramStory({
    required String imagePath,
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? backgroundResourcePath,
    String? attributionURL,
  }) async {
    return shareMetaStory(
      platform: 'shareInstagramStory',
      imagePath: imagePath,
      backgroundTopColor: backgroundTopColor,
      backgroundBottomColor: backgroundBottomColor,
      attributionURL: attributionURL,
      backgroundResourcePath: backgroundResourcePath,
    );
  }

  Future<String?> shareFacebookStory({
    String? imagePath,
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? backgroundResourcePath,
    String? attributionURL,
  }) async {
    return shareMetaStory(
      platform: 'shareFacebookStory',
      imagePath: imagePath,
      backgroundTopColor: backgroundTopColor,
      backgroundBottomColor: backgroundBottomColor,
      attributionURL: attributionURL,
      backgroundResourcePath: backgroundResourcePath,
    );
  }

  Future<String?> shareMetaStory({
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
      'appId': facebookAppId
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

  Future<void> shareTwitter({
    String? text,
    // List<String>? hashtags,
  }) async {
    final nativeBaseUrl = 'twitter://post';
    final webBaseUrl = 'https://twitter.com/intent/tweet';

    if (await canLaunchUrlString(nativeBaseUrl)) {
      final queryParameters = {
        if (text != null) 'message': text,
        // if (hashtags != null && hashtags.isNotEmpty)
        //   'hashtags': hashtags.join(','),
      };

      final postUrl = Uri.parse(nativeBaseUrl).replace(
        queryParameters: queryParameters,
      );

      await launchUrl(postUrl);
    } else if (await canLaunchUrlString(webBaseUrl)) {
      final queryParameters = {
        if (text != null) 'text': text,
        // if (hashtags != null && hashtags.isNotEmpty)
        //   'hashtags': hashtags.join(','),
      };

      final postUrl = Uri.parse(webBaseUrl).replace(
        queryParameters: queryParameters,
      );

      await launchUrl(postUrl);
    } else {
      throw 'Could not launch X.';
    }
  }

  Future<String?> shareSms(
    String message, {
    String? url,
    String? trailingText,
  }) async {
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

  Future<String?> copyToClipboard({String? text, String? image}) async {
    final args = <String, dynamic>{
      'content': text,
      'image': image,
    };
    final response = await _channel.invokeMethod('copyToClipboard', args);
    return response;
  }

  Future<bool?> shareOptions(String contentText, {String? imagePath}) async {
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

  Future<String?> shareWhatsapp(String content) async {
    final args = <String, dynamic>{'content': content};
    final version = await _channel.invokeMethod('shareWhatsapp', args);
    return version;
  }

  Future<Map?> checkInstalledAppsForShare() async {
    final apps = await _channel.invokeMethod('checkInstalledApps');
    return apps;
  }

  Future<String?> shareTelegram(String content) async {
    final args = <String, dynamic>{'content': content};
    final version = await _channel.invokeMethod('shareTelegram', args);
    return version;
  }

// static Future<String> shareSlack() async {
//   final String version = await _channel.invokeMethod('shareSlack');
//   return version;
// }

  //Utils
  Future<bool> reSaveImage(String? imagePath, String filename) async {
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
