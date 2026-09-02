import 'package:flutter/material.dart';

import '../../../core/navigation/screen_route.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../errand/models/task_item.dart';
import '../../errand/widgets/task_card.dart';
import '../data/partner_missions.dart';
import '../data/point_rules.dart';
import '../data/reward_products.dart';
import '../models/coupon.dart';
import '../widgets/attend_streak.dart';
import '../widgets/mission_row.dart';
import '../widgets/partner_card.dart';
import '../widgets/walk_ring.dart';

class BenefitsView extends StatefulWidget {
  final int points;
  final int steps;
  final List<Coupon> coupons;
  final List<TaskItem> items;
  final List<int> grabbed;
  final int monthEarn;
  final int monthPoints;
  final int freeLeft;
  final List<String> doneMissions;
  final void Function(int amt, String label) earn;
  final void Function(ScreenRoute) push;
  final void Function(TaskItem) openDetail;
  final VoidCallback goPointsHub;
  const BenefitsView({
    super.key,
    required this.points,
    required this.steps,
    required this.coupons,
    required this.items,
    required this.grabbed,
    required this.monthEarn,
    required this.monthPoints,
    required this.freeLeft,
    required this.doneMissions,
    required this.earn,
    required this.push,
    required this.openDetail,
    required this.goPointsHub,
  });
  @override
  State<BenefitsView> createState() => _BenefitsViewState();
}

class _BenefitsViewState extends State<BenefitsView> {
  final Map<String, bool> claimed = {};
  int ad = 0;
  bool walkGot = false;
  static const todayMax = 8430; // 오늘 받을 수 있는 예상 포인트(예상치)

  void _claim(String k, int amt, String label) {
    if (claimed[k] == true) return;
    setState(() => claimed[k] = true);
    widget.earn(amt, label);
  }

  void _watchAd() {
    if (ad >= 5) return;
    setState(() => ad += 1);
    widget.earn(PointRules.adView, '광고 시청');
  }

  Widget _secTitle(String t, {String? sub, Widget? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
              if (sub != null) TextSpan(text: '  $sub', style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
            ])),
          ),
          ?action,
        ],
      ),
    );
  }

  Widget _missionRowScroll(String cat) {
    final list = missionsByCat(cat);
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final m = list[i];
          return PartnerCard(
            m: m, done: widget.doneMissions.contains(m.id),
            onOpen: () => widget.push(ScreenRoute(name: 'mission', mission: m)),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goal = nextRewardGoal(widget.points);
    final liveCoupons = widget.coupons.where((c) => !c.used).length;
    final claimable = walkClaimable(widget.steps);
    final nearby = widget.items.where((it) => it.mode != 'together').take(2).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 26),
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 18, 16, 2), child: Text('혜택', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink))),
        const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 4), child: Text('오늘 내가 더 벌 수 있는 방법', style: TextStyle(fontSize: 12.5, color: AppColors.sub))),

        // 내 포인트 + 오늘 예상
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('내 포인트', style: TextStyle(fontSize: 12.5, color: Colors.white70)),
                    Padding(padding: const EdgeInsets.only(top: 4), child: Text('${nf(widget.points)}P', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.yellow))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('오늘 받을 수 있는 포인트', style: TextStyle(fontSize: 11, color: Colors.white54)),
                    Padding(padding: const EdgeInsets.only(top: 3), child: Text('최대 +${nf(todayMax)}P', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
                  ],
                ),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: goal != null
                    ? Text.rich(TextSpan(style: const TextStyle(fontSize: 11.5, color: Colors.white60), children: [
                        TextSpan(text: '${goal.name}까지 '),
                        TextSpan(text: '${nf(goal.remain)}P', style: const TextStyle(color: AppColors.yellow)),
                        const TextSpan(text: ' 남았어요'),
                      ]))
                    : Text('1P ≈ $pointValue원처럼 쓸 수 있어요', style: const TextStyle(fontSize: 11.5, color: Colors.white54)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(children: [
                  Expanded(
                    flex: 14,
                    child: ElevatedButton(
                      onPressed: () => widget.push(const ScreenRoute(name: 'shop')),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: AppColors.ink, padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)), elevation: 0),
                      child: const Text('포인트 사용하기', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 10,
                    child: OutlinedButton(
                      onPressed: () => widget.push(const ScreenRoute(name: 'coupons')),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                      child: Text('🎟 내 쿠폰${liveCoupons > 0 ? ' $liveCoupons' : ''}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),

        // 이번 달 수익 / 포인트 + 수수료 혜택
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(13)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('이번 달 겸사 수익', style: TextStyle(fontSize: 11, color: AppColors.sub)),
                    Padding(padding: const EdgeInsets.only(top: 3), child: Text('+${nf(widget.monthEarn)}원', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(13)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('이번 달 적립', style: TextStyle(fontSize: 11, color: AppColors.sub)),
                    Padding(padding: const EdgeInsets.only(top: 3), child: Text('+${nf(widget.monthPoints)}P', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.blue))),
                  ],
                ),
              ),
            ),
          ]),
        ),
        if (widget.freeLeft > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Text('🎉', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Expanded(child: Text('신규 첫 3거래 수수료 0% · 남은 무료 거래 ${widget.freeLeft}회', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.yellowDeep))),
            ]),
          ),

        // 오늘의 수익 기회
        _secTitle('오늘의 수익 기회'),
        SizedBox(
          height: 104,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            children: [
              for (final c in const [
                ['🚶', '걷기', '+30P', AppColors.blue],
                ['🤝', '근처 부탁', '+7,000원', AppColors.ink],
                ['🎁', '제휴 미션', '+2,000P', AppColors.blue],
                ['✈️', '해외', '+20,000원', AppColors.ink],
                ['👥', '친구추천', '+400P', AppColors.blue],
              ])
                Container(
                  width: 96,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                  decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(13)),
                  child: Column(children: [
                    Text(c[0] as String, style: const TextStyle(fontSize: 19)),
                    Padding(padding: const EdgeInsets.only(top: 5), child: Text(c[1] as String, style: const TextStyle(fontSize: 11, color: AppColors.sub))),
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text(c[2] as String, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: c[3] as Color))),
                  ]),
                ),
            ],
          ),
        ),

        // A. 근처에서 벌기
        _secTitle('📍 근처에서 벌기',
            action: InkWell(
              onTap: () => widget.push(const ScreenRoute(name: 'list', title: '근처에서 벌기', subtitle: '가까운 순', base: 'earn', sortable: true, defaultSort: 'dist', catChips: true, mapBtn: true)),
              child: const Text('더 보기 ›', style: TextStyle(color: AppColors.sub, fontSize: 12, fontWeight: FontWeight.w700)),
            )),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [for (final it in nearby) TaskCard(it: it, onOpen: () => widget.openDetail(it), done: widget.grabbed.contains(it.id))])),

        // B. 걸어서 벌기
        _secTitle('🚶 걸어서 벌기', sub: '걷다가 근처 부탁까지'),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 2),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Row(children: [
              WalkRing(steps: widget.steps, size: 72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(TextSpan(style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink), children: [
                      TextSpan(text: nf(widget.steps)),
                      TextSpan(text: ' / ${nf(walkGoal)}걸음', style: const TextStyle(fontSize: 13, color: AppColors.sub, fontWeight: FontWeight.w600)),
                    ])),
                    Padding(padding: const EdgeInsets.only(top: 4), child: Text('오늘 +$claimable P 적립 가능', style: const TextStyle(fontSize: 12.5, color: AppColors.green, fontWeight: FontWeight.w700))),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: InkWell(
                        onTap: () {
                          if (!walkGot) {
                            widget.earn(claimable, '걸음 적립');
                            setState(() => walkGot = true);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(color: walkGot ? AppColors.page : AppColors.yellow, borderRadius: BorderRadius.circular(10)),
                          child: Text(walkGot ? '오늘 적립 완료' : '포인트 받기', style: TextStyle(color: walkGot ? AppColors.sub : AppColors.ink, fontSize: 13, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(children: [
                for (final w in walkRules)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: widget.steps >= w.steps ? AppColors.greenSoft : AppColors.page, borderRadius: BorderRadius.circular(9)),
                      child: Column(children: [
                        Text(nf(w.steps), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: widget.steps >= w.steps ? AppColors.green : AppColors.faint)),
                        Padding(padding: const EdgeInsets.only(top: 2), child: Text('+${w.p}P', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: widget.steps >= w.steps ? AppColors.green : AppColors.sub))),
                      ]),
                    ),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => widget.push(const ScreenRoute(name: 'walk')),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                  child: const Text('걸으면서 할 수 있는 근처 부탁 보기 ›', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        ),

        // 연속 출석 현금 보상
        _secTitle('📅 연속 출석하고 벌기', sub: '빠짐없이 오면 현금이 커져요'),
        AttendStreak(earn: widget.earn),

        // 같이 사고 벌기 (공동구매)
        InkWell(
          onTap: () => widget.push(const ScreenRoute(name: 'gongu')),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Text('🛍️', style: TextStyle(fontSize: 22))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('같이 사고 벌기 · 공동구매', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text('공구를 안 만들어도 — 추천으로 같이 사면 보상', style: const TextStyle(fontSize: 11.5, color: AppColors.yellowDeep))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(9)),
                child: const Text('공구 보기', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ]),
          ),
        ),

        // B2B2C 부업 허브 진입
        InkWell(
          onTap: () => widget.push(const ScreenRoute(name: 'earn')),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF2A2C30), borderRadius: BorderRadius.circular(12)), child: const Text('💼', style: TextStyle(fontSize: 22))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('부업 · 제휴 성과보상', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text('가입·콘텐츠·의견·방문을 한곳에서', style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: .6)))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(9)),
                child: const Text('전체보기', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
            ]),
          ),
        ),

        // 가입하고 벌기
        _secTitle('🎁 가입하고 벌기', sub: '카드·통신·서비스 가입 등'),
        _missionRowScroll('signup'),

        // 콘텐츠로 벌기
        _secTitle('✍️ 콘텐츠로 벌기', sub: '블로그·SNS·리뷰 콘텐츠로 사례비'),
        _missionRowScroll('blog'),

        // 의견 주고 벌기
        _secTitle('🗣️ 의견 주고 벌기', sub: '설문·인터뷰·좌담회·UX 테스트'),
        _missionRowScroll('survey'),

        // 방문하고 벌기
        _secTitle('🏬 방문하고 벌기', sub: '가는 길에 들러서'),
        _missionRowScroll('visit'),

        // G. 여행하며 벌기
        _secTitle('✈️ 여행하며 벌기'),
        InkWell(
          onTap: () => widget.push(const ScreenRoute(name: 'overseas')),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('여행 가는 김에, +20,000원부터', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                Padding(padding: const EdgeInsets.only(top: 4), child: Text('지금 도쿄에서 할 수 있는 부탁 14개 · 해외 부탁 보기 ›', style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: .9)))),
              ],
            ),
          ),
        ),

        // F. 친구랑 벌기
        _secTitle('👥 친구랑 벌기', sub: '실제 거래까지 이어지면 더'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(children: [
            MissionRow(icon: '💬', label: '카카오톡 채널 친구 추가', points: PointRules.kakaoFriend, cta: '추가', done: claimed['kakao'] == true, onClaim: () => _claim('kakao', PointRules.kakaoFriend, '카카오톡 채널 친구 추가')),
            MissionRow(icon: '👥', label: '친구 추천', sub: '친구가 가입하면 +100P · 첫 거래 완료 시 +300P', points: PointRules.referral, cta: '초대', prog: const [2, 5], done: claimed['referral'] == true, onClaim: () => _claim('referral', PointRules.referral, '친구 추천')),
            MissionRow(icon: '📲', label: '초대 링크 공유', points: PointRules.invite, cta: '공유', done: claimed['invite'] == true, onClaim: () => _claim('invite', PointRules.invite, '초대 링크 공유')),
          ]),
        ),

        // 오늘 받을 수 있는 포인트 (광고 + 기본 미션)
        _secTitle('오늘 받을 수 있는 포인트'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(13)),
              child: Row(children: [
                Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(11)), child: const Text('▶️', style: TextStyle(fontSize: 18))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(TextSpan(style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink), children: [
                        const TextSpan(text: '광고 보기 '),
                        TextSpan(text: '+${PointRules.adView}P', style: const TextStyle(color: AppColors.blue)),
                      ])),
                      Padding(padding: const EdgeInsets.only(top: 2), child: Text('오늘 $ad/5회', style: const TextStyle(fontSize: 11.5, color: AppColors.sub))),
                    ],
                  ),
                ),
                InkWell(
                  onTap: ad >= 5 ? null : _watchAd,
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(color: ad >= 5 ? AppColors.page : AppColors.ink, borderRadius: BorderRadius.circular(9)),
                    child: Text(ad >= 5 ? '완료' : '보기', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: ad >= 5 ? AppColors.faint : Colors.white)),
                  ),
                ),
              ]),
            ),
            MissionRow(icon: '✅', label: '출석 체크', points: PointRules.attendance, cta: '출석', done: claimed['attend'] == true, onClaim: () => _claim('attend', PointRules.attendance, '출석 체크')),
            MissionRow(icon: '📅', label: '7일 연속 출석', points: PointRules.attendance7, prog: const [4, 7], done: false),
            MissionRow(icon: '🙂', label: '프로필 완성', points: PointRules.profile, cta: '완성', done: claimed['profile'] == true, onClaim: () => _claim('profile', PointRules.profile, '프로필 완성')),
            MissionRow(icon: '🙋', label: '첫 부탁 등록', points: PointRules.firstRequest, cta: '등록', done: claimed['firstReq'] == true, onClaim: () => _claim('firstReq', PointRules.firstRequest, '첫 부탁 등록')),
            MissionRow(icon: '🤝', label: '첫 도와주기 완료', points: PointRules.firstHelp, done: false),
            MissionRow(icon: '⭐', label: '후기 작성', points: PointRules.review, cta: '작성', done: claimed['review'] == true, onClaim: () => _claim('review', PointRules.review, '후기 작성')),
          ]),
        ),
      ],
    );
  }
}
