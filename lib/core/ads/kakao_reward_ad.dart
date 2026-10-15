import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/api_keys.dart';

/// 리워드 동영상 한 번의 결과.
enum RewardAdResult {
  /// 끝까지 봐서 보상 조건을 채웠다 → 적립한다
  earned,

  /// 중간에 닫았다 → 적립하지 않는다
  skipped,

  /// 지금 보여 줄 광고가 없다 (재고 없음·네트워크)
  noFill,

  /// 광고단위 ID가 없거나 네이티브 SDK가 아직 연결되지 않았다
  unavailable,
}

/// 카카오 애드핏 리워드 동영상.
///
/// 화면은 Flutter가, 광고 재생은 각 플랫폼의 애드핏 SDK가 맡는다. 둘은
/// `gyeomsa/adfit_reward` 채널 하나로 이어진다.
///
/// | 메서드 | 인자 | 돌려주는 값 |
/// | --- | --- | --- |
/// | `show` | `{unitId}` | `'earned'` · `'skipped'` · `'noFill'` |
///
/// 네이티브 쪽(Android `MainActivity`, iOS `AppDelegate`)은 애드핏에서 리워드 동영상
/// 광고단위와 SDK를 받은 뒤에 붙인다. 그 전에는 채널이 없어서 [RewardAdResult.unavailable]이
/// 나오고, 화면은 '준비 중'으로 안내한다 — 포인트가 잘못 나가는 일은 없다.
class KakaoRewardAd {
  const KakaoRewardAd();

  static const _channel = MethodChannel('gyeomsa/adfit_reward');

  /// 지금 플랫폼의 광고단위 ID. 웹·데스크톱은 애드핏 앱 SDK가 없어 빈 값이다.
  static String get unitId {
    if (kIsWeb) return '';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => ApiKeys.adfitRewardAndroid,
      TargetPlatform.iOS => ApiKeys.adfitRewardIos,
      _ => '',
    };
  }

  static bool get configured => unitId.isNotEmpty;

  /// 지금 이 기기에서 띄울 수 있는지. 테스트에서는 가짜 광고로 바꿔 끼운다.
  bool get isReady => configured;

  /// 광고를 띄우고 끝날 때까지 기다린다.
  Future<RewardAdResult> show() async {
    final id = unitId;
    if (id.isEmpty) return RewardAdResult.unavailable;
    try {
      final r = await _channel.invokeMethod<String>('show', {'unitId': id});
      return switch (r) {
        'earned' => RewardAdResult.earned,
        'skipped' => RewardAdResult.skipped,
        'noFill' => RewardAdResult.noFill,
        _ => RewardAdResult.unavailable,
      };
    } on MissingPluginException {
      return RewardAdResult.unavailable;
    } on PlatformException {
      return RewardAdResult.noFill;
    }
  }
}
