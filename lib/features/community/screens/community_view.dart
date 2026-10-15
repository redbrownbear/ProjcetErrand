import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../../errand/data/countries.dart';
import '../../overseas/data/local_helps.dart';
import '../../proposal/models/proposal.dart';
import '../data/com_posts.dart';
import '../models/com_post.dart';
import '../widgets/com_post_card.dart';

/// 커뮤니티 탭 — 이야기가 중심 (시안 v42~v44).
///
/// 국내(우리 동네 · 여행)와 해외로 나뉜다. 질문·동행·후기·정보·맛집 글이 먼저 나오고,
/// 같은 지역·나라의 제안 카드가 글처럼 섞여 바로 '저 구매할래요!'를 누를 수 있다.
/// 글을 올리거나 답글을 달 때마다 응모권 +1. 해외 부탁은 아래 한 줄로만, 제휴 광고는 맨 아래.
class CommunityView extends StatefulWidget {
  final AppNav nav;
  final VoidCallback goOverseasAsk;
  const CommunityView({super.key, required this.nav, required this.goOverseasAsk});

  @override
  State<CommunityView> createState() => CommunityViewState();
}

class CommunityViewState extends State<CommunityView> {
  bool abroad = false;
  int sub = 0; // 0 우리 동네 · 1 여행
  int kind = 0;
  String place = '';

  AppNav get nav => widget.nav;

  /// 다른 화면에서 '이야기 더 보기'로 들어올 때
  void focus(String scope, {String? place}) => setState(() {
        abroad = scope == 'abroad';
        sub = scope == 'travel' ? 1 : 0;
        kind = 0;
        this.place = place ?? '';
      });

  String get scope => abroad ? 'abroad' : (sub == 0 ? 'local' : 'travel');

  List<String> get kinds => ['전체', ...switch (scope) {
        'travel' => travelKinds,
        'abroad' => abroadKinds,
        _ => localKinds,
      }];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: nav.store,
      builder: (context, _) {
        final all = nav.store.postsOf(scope);
        final posts = all.where((p) {
          if (kind > 0 && p.kind != kinds[kind]) return false;
          if (place.isNotEmpty && p.place != place) return false;
          return true;
        }).toList();

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Seg(
              labels: const ['국내', '해외'],
              index: abroad ? 1 : 0,
              iconOf: (i, on) => i == 1 ? Icon(Icons.public_rounded, size: 17, color: on ? AppColors.ink : AppColors.sub) : const SizedBox.shrink(),
              onChanged: (i) => setState(() {
                abroad = i == 1;
                kind = 0;
                place = '';
              }),
            ),
            if (!abroad)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: UnderTabs(
                  labels: const ['우리 동네', '여행'],
                  index: sub,
                  onChanged: (i) => setState(() {
                    sub = i;
                    kind = 0;
                    place = '';
                  }),
                ),
              ),
            _status(all),
            if (scope == 'travel') _travelPlaces(all),
            if (scope == 'abroad') _countryChips(all),
            if (scope != 'travel') _todayQuestion(),
            const SizedBox(height: 12),
            ChipRow(labels: kinds, index: kind, onChanged: (i) => setState(() => kind = i)),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
              child: Column(children: _feed(posts)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
              child: BigButton(
                label: '커뮤니티 글쓰기',
                icon: 'pencil',
                bg: AppColors.card,
                fg: AppColors.ink,
                onTap: () => nav.compose(context, scope: scope),
              ),
            ),
            if (scope != 'local') _askBridge(),
            if (scope == 'travel') _travelAd(),
            if (scope == 'abroad') _abroadAd(),
          ],
        );
      },
    );
  }

  Widget _status(List<ComPost> all) {
    final (label, n) = switch (scope) {
      'travel' => ('지금 여행 중인 이웃', 64),
      'abroad' => ('지금 해외 이웃', 128),
      _ => ('${nav.area()} 이웃', 312),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.greenSoft, width: 3),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$label '),
              TextSpan(text: '$n명', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
              const TextSpan(text: '  · 오늘 새 글 '),
              TextSpan(
                text: '${all.where((p) => p.mine || p.ago.contains('분') || p.ago.contains('시간') || p.ago == '방금').length}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.sub),
          ),
        ),
      ]),
    );
  }

  Widget _todayQuestion() {
    final id = todayQuestionIds[abroad ? 'abroad' : 'local']!;
    final q = nav.store.postById(id);
    if (q == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 14, 10, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4C9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.liveLine),
      ),
      child: Tap(
        onTap: () => nav.openPost(context, id),
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('오늘의 질문 · 답글 달면 응모권 +1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.yellowInk)),
            const SizedBox(height: 6),
            Text(q.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('답글 ${q.comments.length} · 좋아요 ${q.likes + (nav.store.likedPosts.contains(id) ? 1 : 0)}', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
          ]),
        ),
      ),
    );
  }

  Widget _placeCard({required String top, required String name, required int n, required bool on, required VoidCallback onTap, bool code = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: on ? AppColors.ink : AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          code
              ? Text(top, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: on ? AppColors.yellow : AppColors.red))
              : Text(top, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: on ? Colors.white : AppColors.ink)),
          Text('글 $n', style: TextStyle(fontSize: 11, color: on ? const Color(0xB3FFFFFF) : AppColors.sub)),
        ]),
      ),
    );
  }

  Widget _travelPlaces(List<ComPost> all) => SizedBox(
        height: 104,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
          children: [
            _placeCard(top: '🗺️', name: '전체', n: all.length, on: place.isEmpty, onTap: () => setState(() => place = '')),
            for (final p in travelPlaces) ...[
              const SizedBox(width: 6),
              _placeCard(
                top: p.emoji,
                name: p.place,
                n: all.where((x) => x.place == p.place).length,
                on: place == p.place,
                onTap: () => setState(() => place = p.place),
              ),
            ],
          ],
        ),
      );

  Widget _countryChips(List<ComPost> all) => SizedBox(
        height: 104,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
          children: [
            _placeCard(top: 'ALL', name: '전체', n: all.length, on: place.isEmpty, code: true, onTap: () => setState(() => place = '')),
            for (final c in abroadPlaces) ...[
              const SizedBox(width: 6),
              _placeCard(
                top: c.cc.toUpperCase(),
                name: c.name,
                n: all.where((x) => x.place == c.cc).length,
                on: place == c.cc,
                code: true,
                onTap: () => setState(() => place = c.cc),
              ),
            ],
          ],
        ),
      );

  /// 글 사이에 같은 지역·나라의 제안을 섞는다. 두 글마다 한 장.
  List<Widget> _feed(List<ComPost> posts) {
    final showOffers = scope != 'local' && (kind == 0);
    final offers = !showOffers
        ? <Proposal>[]
        : nav.store.board(abroad: abroad).where((p) {
            if (place.isEmpty) return true;
            return abroad ? p.cc == place : (p.from == place || p.to == place);
          }).toList();
    final helps = !(showOffers && abroad) ? <LocalHelp>[] : localHelps.where((h) => place.isEmpty || h.cc == place).take(2).toList();

    final out = <Widget>[];
    var oi = 0, hi = 0;
    for (var i = 0; i < posts.length; i++) {
      final p = posts[i];
      out.add(ComPostTile(p: p, liked: nav.store.likedPosts.contains(p.id), showPlace: scope != 'local', onTap: () => nav.openPost(context, p.id)));
      if (i % 2 == 1) {
        if (oi < offers.length) {
          final o = offers[oi++];
          out.add(ProposalFeedTile(
            p: o,
            meJoined: nav.store.joined.contains(o.id),
            onOpen: () => nav.openProposal(context, o),
            onJoin: () => nav.store.toggleJoin(o),
          ));
        } else if (hi < helps.length) {
          out.add(_helpTile(helps[hi++]));
        }
      }
    }
    // 글이 적어 못 섞인 제안도 하나는 보여 준다
    if (oi == 0 && offers.isNotEmpty) {
      final o = offers.first;
      out.add(ProposalFeedTile(p: o, meJoined: nav.store.joined.contains(o.id), onOpen: () => nav.openProposal(context, o), onJoin: () => nav.store.toggleJoin(o)));
    }
    if (out.isEmpty) {
      out.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('아직 글이 없어요 · 첫 글을 남겨 주세요', style: TextStyle(color: AppColors.sub))),
      ));
    }
    return out;
  }

  Widget _helpTile(LocalHelp h) {
    final applied = nav.store.appliedLocal.contains(h.id);
    final n = h.applied + (applied ? 1 : 0);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(color: Color(0xFFF5F8FF), border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Pill('제안', bg: AppColors.yellowSoft, fg: AppColors.yellowInk, fontSize: 12),
          const SizedBox(width: 6),
          Pill('${h.city} · ${countryOf(h.cc).name}', bg: AppColors.page, fg: AppColors.inkSoft, fontSize: 12),
          const Spacer(),
          const Pill('현지 거주 확인', bg: AppColors.greenSoft, fg: AppColors.greenDeep),
        ]),
        const SizedBox(height: 10),
        Text(h.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        const SizedBox(height: 4),
        Text('${h.kind} · ${won(h.price)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
        Text('$n/${h.max}명 · ${h.max - n}자리 남음', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: BigButton(
            label: applied ? '신청함 ✓' : '저 신청할래요!',
            height: 42,
            bg: applied ? AppColors.page : AppColors.yellow,
            onTap: () => nav.store.applyLocal(h.id),
          ),
        ),
      ]),
    );
  }

  Widget _askBridge() {
    final n = abroad ? nav.items().where((i) => i.mode == 'sea').length : nav.store.board(abroad: false).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Tap(
        onTap: abroad ? widget.goOverseasAsk : () => nav.openProposalList(context, abroad: false),
        radius: 16,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(abroad ? '여행 가는 김에 하는 해외 부탁도 있어요' : '여행 가는 김에 하는 부탁도 있어요', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                const SizedBox(height: 2),
                Text(abroad ? '해외 부탁 $n건 보러 가기' : '국내 여행 부탁 $n건 보러 가기', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
          ]),
        ),
      ),
    );
  }

  Widget _adFrame({required String tag, required String title, required String sub, List<(String, String, IconData)> extras = const []}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(4)),
            child: const Text('광고', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.sub)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
        if (extras.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final (t, s, i) in extras)
            Tap(
              onTap: () => nav.flash('제휴 확정 후 열려요'),
              radius: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(10)),
                    child: Icon(i, size: 18, color: AppColors.blue),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                  Text(s, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.faint),
                ]),
              ),
            ),
        ],
      ]),
    );
  }

  Widget _travelAd() => _adFrame(tag: '국내 여행 제휴', title: '떠나기 전, 숙소·렌터카 제휴 혜택', sub: '제휴 혜택을 먼저 알려드려요');

  Widget _abroadAd() => _adFrame(
        tag: '출국 준비 제휴',
        title: '출국 전, 여행자보험 챙기셨나요?',
        sub: '3분이면 보장 항목을 비교해요 · 제휴 가입하면 응모권 +2',
        extras: const [
          ('eSIM·로밍', '도착하자마자 바로 연결', Icons.sim_card_outlined),
          ('환전·트래블카드', '수수료 줄이는 환전', Icons.credit_card_rounded),
          ('짐 보관·공항 서비스', '공항에서 가볍게', Icons.luggage_outlined),
        ],
      );
}
