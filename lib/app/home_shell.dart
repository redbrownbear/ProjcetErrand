import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/utils/formatters.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/services/auth_service.dart';
import '../features/benefits/data/point_rules.dart';
import '../features/benefits/models/coupon.dart';
import '../features/benefits/models/partner_mission.dart';
import '../features/benefits/models/reward_ledger.dart';
import '../features/benefits/models/reward_product.dart';
import '../features/benefits/screens/benefits_view.dart';
import '../features/chat/screens/chat_view.dart';
import '../features/errand/models/offer.dart';
import '../features/errand/models/task_item.dart';
import '../features/errand/navigation/errand_actions.dart';
import '../features/errand/repositories/errand_repository.dart';
import '../features/errand/screens/home_content.dart';
import '../features/errand/screens/post_request.dart';
import '../features/errand/widgets/region_sheet.dart';
import '../features/profile/screens/me_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final ErrandRepository _errandRepository = LocalErrandRepository();
  String tab = 'home'; // home | benefits | chat | me
  List<int> grabbed = [];
  Map<int, List<Offer>> offers = {};
  String? toast;
  late List<TaskItem> items;
  String scope = '서울 서초구';
  int points = 3200;
  final int steps = 6430;
  List<Coupon> coupons = [];
  final int tradeCount = 1; // 완료한 거래 수 (신규 첫 3회 수수료 0%)
  int get freeLeft => (freeTrades - tradeCount).clamp(0, freeTrades);
  final int monthEarn = 84500; // 이번 달 겸사 수익(원)
  final int monthPoints = 4230; // 이번 달 적립 포인트
  List<String> doneMissions = [];
  final RewardLedger _rewards = RewardLedger();

  bool get isLoggedIn => AuthService().currentUser != null;
  StreamSubscription<User?>? _authSub;

  ErrandActions get actions => ErrandActions(grabbed: grabbed, onGrab: grab, onOffer: sendOffer, offers: offers);

  /// 콘텐츠 열람은 항상 허용하되, 실제 참여 행동(지원/제안/등록/적립/교환 등)만
  /// 로그인 여부로 막아 로그인 화면으로 유도함.
  ///
  /// 로그인이 필요해서 화면을 띄운 경우, 로그인에 성공하면 **원래 하려던 동작을
  /// 이어서 실행**한다. (예: 부탁 등록을 누름 -> 로그인 -> 바로 등록 화면으로)
  Future<void> requireLogin(VoidCallback action) async {
    if (isLoggedIn) {
      action();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    if (!mounted || !isLoggedIn) return; // 로그인 안 하고 뒤로 나온 경우
    action();
  }

  @override
  void initState() {
    super.initState();
    items = _errandRepository.fetchSeedItems();
    _authSub = AuthService().authStateChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void flash(String m) {
    setState(() => toast = m);
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => toast = null);
    });
  }

  /// 해당 보상을 이미 받았는지. 적립 버튼을 "완료" 상태로 그릴 때 쓴다.
  bool isClaimed(String key, {bool daily = true}) => _rewards.isClaimed(key, daily: daily);

  /// [key]가 같은 보상은 한 번만 지급된다. [daily]가 true면 한국 시간 기준
  /// 하루에 한 번, false면 계정당 한 번.
  Future<void> earn(int amt, String label, {required String key, bool daily = true}) => requireLogin(() {
        if (!_rewards.claim(key, daily: daily)) {
          flash(daily ? '오늘은 이미 받았어요' : '이미 받은 적립이에요');
          return;
        }
        setState(() => points += amt);
        flash('+${amt}P 적립됐어요 · $label');
      });

  void redeem(RewardProduct p) => requireLogin(() {
        if (points < p.points) {
          flash('보유 포인트가 부족해요');
          return;
        }
        setState(() {
          points -= p.points;
          coupons.insert(
            0,
            Coupon(id: DateTime.now().millisecondsSinceEpoch, brandK: p.brand, name: p.name, points: p.points, exp: '2026.12.31', code: genCode()),
          );
        });
      });

  void useCoupon(int id) => requireLogin(() {
        setState(() => coupons = coupons.map((c) => c.id == id ? c.copyWith(used: true) : c).toList());
      });

  void completeMission(PartnerMission m) => requireLogin(() {
        if (doneMissions.contains(m.id)) return;
        setState(() => doneMissions.add(m.id));
        earn(m.points, m.title, key: 'mission:${m.id}', daily: false);
      });

  void goPointsHub() {
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() => tab = 'benefits');
  }

  void grab(TaskItem it) => requireLogin(() {
        setState(() {
          if (!grabbed.contains(it.id)) grabbed.add(it.id);
        });
        flash(it.mode == 'together' ? '신청했어요. 채팅으로 이어드릴게요' : '지원했어요. 요청자가 확인하면 매칭돼요');
      });

  void sendOffer(TaskItem it, int price, String msg) => requireLogin(() {
        setState(() => offers.putIfAbsent(it.id, () => []).add(Offer(price, msg)));
        flash('가격 제안을 보냈어요. 요청자에게만 보여요');
      });

  void addRequest(NewRequestData data) {
    final it = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch,
      mode: data.mode,
      cat: data.cat,
      title: data.title,
      desc: data.desc,
      place: data.place.isEmpty ? null : data.place,
      cc: data.cc,
      city: data.city,
      country: data.country,
      region: data.mode == 'sea' ? null : (scope == '전국' ? '우리 동네' : scope),
      distM: data.mode == 'sea' ? 9e9 : 150,
      mins: data.mode == 'sea' ? 0 : data.mins,
      price: data.price,
      who: '나',
      // 내가 방금 올린 글에 별점 5.0 / 본인인증 완료를 자동으로 붙이면 안 된다.
      // (TaskItem의 기본값은 프로필이 이미 쌓인 SEED 데이터용이다)
      rating: 0, reviews: 0, deals: 0, resp: 0, verified: false,
      hot: data.hot,
      x: 50, y: 50,
    );
    setState(() {
      if (it.hot) {
        items.insert(0, it);
      } else {
        final i = items.indexWhere((x) => !x.hot);
        if (i == -1) {
          items.add(it);
        } else {
          items.insert(i, it);
        }
      }
    });
    flash(it.hot ? '급해요로 목록 맨 위에 올렸어요' : '부탁을 올렸어요');
  }

  void openPost() => requireLogin(() {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PostRequest(scope: scope, onSubmit: addRequest)));
      });

  Future<void> openRegion() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegionSheet(scope: scope),
    );
    if (picked != null) setState(() => scope = picked);
  }

  Widget _body() {
    switch (tab) {
      case 'benefits':
        return BenefitsView(
          points: points, steps: steps, coupons: coupons, items: items, scope: scope, actions: actions,
          monthEarn: monthEarn, monthPoints: monthPoints, freeLeft: freeLeft, doneMissions: doneMissions,
          earn: earn, isClaimed: isClaimed, redeem: redeem, useCoupon: useCoupon, completeMission: completeMission, goPointsHub: goPointsHub,
        );
      case 'chat':
        return ChatView(items: items, grabbed: grabbed);
      case 'me':
        return MeView(
          points: points, coupons: coupons, useCoupon: useCoupon, goPointsHub: goPointsHub,
          freeLeft: freeLeft, monthPoints: monthPoints, isLoggedIn: isLoggedIn, onLogin: () => requireLogin(() {}),
        );
      default:
        return HomeContent(
          items: items, scope: scope, actions: actions, points: points, steps: steps,
          coupons: coupons, doneMissions: doneMissions,
          openPost: openPost, openRegion: openRegion,
          earn: earn, isClaimed: isClaimed, redeem: redeem, useCoupon: useCoupon, completeMission: completeMission,
          flash: flash, goPointsHub: goPointsHub,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 탭은 Navigator 라우트가 아니라 상태값이라, 그대로 두면 홈이 아닌 탭에서
    // 시스템 뒤로가기(갤럭시 하단 버튼/제스처)를 눌렀을 때 앱이 그냥 종료된다.
    // 홈이 아닌 탭에서는 뒤로가기를 홈 탭 복귀로 소비하고, 홈에서만 종료되게 한다.
    // (푸시된 상세·목록 화면은 각자 라우트라 기존대로 정상 pop 된다)
    return PopScope(
      canPop: tab == 'home',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() => tab = 'home');
      },
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Stack(
            children: [
              Column(children: [Expanded(child: _body()), _bottomNav()]),
              if (toast != null)
                Positioned(
                  left: 22, right: 22, bottom: 92,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(14)),
                      child: Text(toast!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchTab(String k) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() => tab = k);
  }

  Widget _bottomNav() {
    final tabs = [
      ['home', '홈', '🏠'],
      ['benefits', '혜택', '🎁'],
    ];
    return Container(
      decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          _navBtn(tabs[0]),
          _navBtn(tabs[1]),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: InkWell(
                    onTap: openPost,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 52, height: 52, alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.add_rounded, size: 30, color: AppColors.ink),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                const Text('부탁', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ],
            ),
          ),
          _navBtn(['chat', '채팅', '💬'], badge: grabbed.length),
          _navBtn(['me', '내정보', '👤']),
        ],
      ),
    );
  }

  Widget _navBtn(List<String> t, {int badge = 0}) {
    final k = t[0], label = t[1], icon = t[2];
    final active = tab == k;
    return Expanded(
      child: InkWell(
        onTap: () => _switchTab(k),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(clipBehavior: Clip.none, children: [
                Opacity(opacity: active ? 1 : 0.55, child: Text(icon, style: const TextStyle(fontSize: 19))),
                if (badge > 0)
                  Positioned(
                    right: -10, top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(99)),
                      child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ]),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(fontSize: 11, color: active ? AppColors.ink : AppColors.faint, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
