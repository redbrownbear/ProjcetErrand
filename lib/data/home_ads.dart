import 'package:flutter/material.dart';

import '../models/home_ad.dart';
import '../models/screen_route.dart';
import '../theme/colors.dart';

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
  const HomeAd(
    k: 'walk', bg: Color(0xFFF76707), tag: '걷기 리워드', t1: '걸으면서 걷고', t2: '포인트도 쌓기',
    cta: '걷기 챌린지', emoji: '🚶', nav: ScreenRoute(name: 'walk'),
  ),
];
