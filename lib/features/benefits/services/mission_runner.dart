import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/net/api_client.dart';
import '../../../core/net/coupang_partners_api.dart';
import '../../../core/net/place_api.dart';
import '../../../core/compliance/disclosures.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../errand/screens/map/map_centers.dart';
import '../data/daily_quiz.dart';
import '../models/daily_mission.dart';
import '../models/reward_ledger.dart';
import 'mission_engine.dart';

/// 미션을 실제로 실행하는 쪽.
///
/// [MissionEngine]이 '지금 받을 수 있나'를 계산한다면, 여기는 '받으려면 무엇을
/// 해야 하나'를 실행한다. 제휴 API 호출과 위치 권한처럼 실패할 수 있는 일이
/// 모두 여기 모여 있어서, 화면은 [run] 하나만 부르면 된다.
class MissionRunner {
  final EarnFn earn;
  final void Function(String) flash;

  /// 현재 보고 있는 지역. 위치 권한이 없을 때 좌표를 여기서 만든다.
  final String scope;

  /// 카운터형 미션이 아직 모자랄 때 보낼 곳
  final VoidCallback goWalk, goProfile, goPost, goList;

  const MissionRunner({
    required this.earn,
    required this.flash,
    required this.scope,
    required this.goWalk,
    required this.goProfile,
    required this.goPost,
    required this.goList,
  });

  static const _kakao = KakaoLocalApi();
  static const _coupang = CoupangPartnersApi();

  Future<void> run(BuildContext context, MissionState s) async {
    if (s.done) {
      flash(s.m.cap > 1 ? '오늘 받을 수 있는 만큼 다 받았어요' : '오늘은 이미 받았어요');
      return;
    }
    if (s.locked) {
      flash('${s.provider.name} · ${s.provider.statusLabel}');
      return;
    }

    switch (s.m.action) {
      case MissionAction.attend:
        await _claim(s, '출석 적립');

      case MissionAction.quiz:
        await _runQuiz(context, s);

      case MissionAction.checkIn:
        await _runCheckIn(context, s);

      case MissionAction.deal:
        await _runDeal(context, s);

      case MissionAction.rewardAd:
        // google_mobile_ads를 붙이면 여기서 RewardedAd.show를 부르고,
        // onUserEarnedReward 콜백에서 _claim을 호출한다.
        flash('리워드 광고는 AdMob 광고 단위 등록 후 열려요');

      case MissionAction.walk:
        goWalk();

      case MissionAction.browse:
        if (s.short) {
          flash('부탁 상세를 ${s.m.target - s.progress}개 더 열어보면 적립돼요');
          goList();
          return;
        }
        await _claim(s, s.m.title);

      case MissionAction.bookmark:
        if (s.progress < s.m.target) {
          flash('마음에 드는 부탁을 하나 저장해 보세요');
          goList();
          return;
        }
        await _claim(s, s.m.title);

      case MissionAction.post:
        if (s.progress < s.m.target) {
          goPost();
          return;
        }
        await _claim(s, s.m.title);

      case MissionAction.profile:
        goProfile();

      case MissionAction.invite:
        await _runInvite(s);

      case MissionAction.offerwall:
        // 오퍼월은 캠페인 목록·단가·노출 대상을 전부 제휴사가 정하고, 화면도
        // 제휴사 SDK가 통째로 그린다. 우리가 할 일은 SDK를 띄우는 것뿐이고,
        // 적립은 제휴사 서버 → 우리 Cloud Functions 콜백으로 들어온다.
        flash('오퍼월은 제휴사 SDK와 적립 콜백 서버가 붙어야 열려요');

      case MissionAction.external:
        await _open(s.m.url);
    }
  }

  /// 적립 한 번. 회차가 있는 미션은 아직 안 받은 회차의 키로 넣는다.
  Future<void> _claim(MissionState s, String label) =>
      earn(s.m.points, label, key: s.m.ledgerKey(s.claimed), daily: s.m.daily);

  // ── 자체 미션 ───────────────────────────────────────────────────────────

  Future<void> _runQuiz(BuildContext context, MissionState s) async {
    final quiz = quizOfDay();
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheet) => _Sheet(
        title: '오늘의 퀴즈',
        subtitle: '맞히면 +${nf(s.m.points)}P',
        children: [
          Text(quiz.q,
              style: AppType.meta.copyWith(fontSize: 15, fontWeight: AppType.w600, color: AppColors.ink, height: 1.5)),
          const SizedBox(height: 14),
          for (var i = 0; i < quiz.choices.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ChoiceButton(label: quiz.choices[i], onTap: () => Navigator.of(sheet).pop(i)),
            ),
        ],
      ),
    );
    if (picked == null) return;

    if (picked != quiz.answer) {
      flash('아쉬워요, 정답이 아니에요 · ${quiz.tip}');
      return;
    }
    await _claim(s, '오늘의 퀴즈');
    flash(quiz.tip);
  }

  Future<void> _runInvite(MissionState s) async {
    // share_plus 없이도 되게 클립보드로 복사한다. 초대 코드는 서버가 발급해야
    // 하므로 지금은 링크만 만들고, 적립은 친구 가입이 확인될 때 서버가 준다.
    await Clipboard.setData(const ClipboardData(text: 'https://gyeomsa.app/invite'));
    flash('초대 링크를 복사했어요 · 친구가 가입하면 +${nf(s.m.points)}P');
  }

  Future<void> _runCheckIn(BuildContext context, MissionState s) async {
    final at = await _coords(requirePrecise: true);
    if (at.$3) {
      flash('체크인은 위치 권한이 필요해요');
      return;
    }
    if (!context.mounted) return;
    await _guard(() async {
      final places = await _kakao.nearby(lat: at.$1, lon: at.$2, radius: 500);
      if (!context.mounted) return;
      if (places.isEmpty) {
        flash('500m 안에 체크인할 매장이 없어요');
        return;
      }
      final picked = await showModalBottomSheet<NearbyPlace>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheet) => _Sheet(
          title: '근처 매장 체크인',
          subtitle: '지금 자리에서 500m 안 · 카카오 로컬 확인',
          children: [
            for (final p in places.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ChoiceButton(
                  label: p.name,
                  hint: [p.distanceLabel, p.address].where((v) => v.isNotEmpty).join(' · '),
                  onTap: () => Navigator.of(sheet).pop(p),
                ),
              ),
          ],
        ),
      );
      if (picked == null) return;
      await _claim(s, '${picked.name} 체크인');
    });
  }

  // ── 제휴 ────────────────────────────────────────────────────────────────

  /// 목록을 열어 주기만 한다. **적립은 여기서 하지 않는다.**
  ///
  /// 포인트가 주문액에 비례하는데 주문 금액도, 주문이 취소될지도 앱은 모른다.
  /// 쿠팡이 구매를 확정해 정산 리포트에 올린 뒤에야 우리 서버가 적립할 수 있다.
  /// 그래서 화면에서도 '보면 준다'가 아니라 '사면 나중에 준다'로 말한다.
  Future<void> _runDeal(BuildContext context, MissionState s) async {
    await _guard(() async {
      final deals = await _coupang.goldbox(limit: 5);
      if (!context.mounted) return;
      await _show(
        context,
        _Sheet(
          title: '오늘의 특가',
          subtitle: '쿠팡 파트너스 골드박스 · ${s.m.payoutLabel} 적립',
          children: [
            for (final d in deals)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ChoiceButton(
                  label: d.name,
                  hint: [
                    won(d.price),
                    if (d.discountRate > 0) '${d.discountRate}% 할인',
                    if (d.rocket) '로켓배송',
                    '→ ${nf(s.m.pointsFor(d.price))}P',
                  ].join(' · '),
                  onTap: () => _open(d.url),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '포인트는 쿠팡이 구매를 확정한 뒤에 들어와요. 취소·반품하면 적립되지 않아요.\n'
                '${Disclosures.partner.body}',
                style: AppType.caption.copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── 공통 ────────────────────────────────────────────────────────────────

  /// API 실패를 사용자 말로 바꿔서 알린다. 미션 하나가 실패해도 화면은 살아 있어야 한다.
  Future<void> _guard(Future<void> Function() body) async {
    try {
      await body();
    } on ApiFailure catch (e) {
      flash(e.userMessage);
    } catch (_) {
      flash('불러오지 못했어요. 잠시 후 다시 시도해 주세요');
    }
  }

  Future<void> _show(BuildContext context, Widget sheet) => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => sheet,
      );

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) flash('링크를 열지 못했어요');
  }

  /// 현재 좌표. 세 번째 값은 '위치를 못 얻어 지역 중심으로 대체했는지'.
  /// 날씨는 동네 중심 좌표로도 충분하지만 체크인은 그러면 안 되므로 구분한다.
  Future<(double, double, bool)> _coords({bool requirePrecise = false}) async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm != LocationPermission.denied && perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
        );
        return (pos.latitude, pos.longitude, false);
      }
    } catch (_) {
      // 웹·데스크톱이거나 권한 거부. 아래 지역 중심으로 넘어간다.
    }
    final center = centerOf(scope);
    return (center.$1, center.$2, requirePrecise);
  }
}

/// 미션 결과를 보여 주는 바텀시트. 미션마다 내용만 갈아 끼운다.
class _Sheet extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> children;
  const _Sheet({required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.surface)),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppType.section),
            Padding(
              padding: const EdgeInsets.only(top: 3, bottom: 14),
              child: Text(subtitle, style: AppType.caption),
            ),
            ...children,
          ]),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final String hint;
  final VoidCallback onTap;
  const _ChoiceButton({required this.label, this.hint = '', required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.page,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.meta.copyWith(fontSize: 14, fontWeight: AppType.w600, color: AppColors.ink, height: 1.4)),
          if (hint.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption),
            ),
        ]),
      ),
    );
  }
}
