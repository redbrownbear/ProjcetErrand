import 'package:flutter/material.dart';

import '../../../core/navigation/screen_route.dart';
import '../../../core/theme/colors.dart';
import '../models/home_ad.dart';

final homeAds = [
  const HomeAd(
    k: 'shop', bg: AppColors.purple, tag: '포인트샵', t1: '모은 포인트로', t2: '커피·치킨 바꿔요',
    cta: '교환하러 가기', emoji: '🎁', nav: ScreenRoute(name: 'shop'),
  ),
  const HomeAd(
    k: 'earn', bg: AppColors.ink, tag: '돈벌기', t1: '가는 길에 5분,', t2: '5천원 벌기',
    cta: '근처 부탁 보기', emoji: '🤝',
    nav: ScreenRoute(name: 'list', title: '돈벌기', subtitle: '가는 길에 부탁 해결하고 사례비 받기', base: 'earn', sortable: true, catChips: true, mapBtn: true),
  ),
  const HomeAd(
    k: 'sea', bg: AppColors.green, tag: '해외 대행', t1: '여행 가는 김에', t2: '용돈 벌기',
    cta: '해외 부탁 보기', emoji: '✈️', nav: ScreenRoute(name: 'overseas'),
  ),
];

/// 재원이 정해질 때까지 내려 둔 배너.
///
/// 걷기 적립은 제휴사가 비용을 대지 않는 자체 지급이라 화면에서 뺐다.
/// [WalkScreen]과 적립 계산은 그대로 남아 있어서, 재원이 생기면 이 항목을
/// [homeAds]로 옮기기만 하면 된다. (`home_content.dart`의 걷기 진입점도 함께)
final parkedAds = [
  const HomeAd(
    k: 'walk', bg: Color(0xFFF76707), tag: '걷기 리워드', t1: '걸으면서 걷고', t2: '포인트도 쌓기',
    cta: '걷기 챌린지', emoji: '🚶', nav: ScreenRoute(name: 'walk'),
  ),
];
