import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/widgets/kit.dart';
import '../features/community/models/com_post.dart';
import '../features/community/screens/com_compose_screen.dart';
import '../features/community/screens/com_post_screen.dart';
import '../features/errand/models/task_item.dart';
import '../features/errand/navigation/errand_actions.dart';
import '../features/lucky/screens/lucky_draw_screen.dart';
import '../features/market/models/used_item.dart';
import '../features/market/screens/used_detail_screen.dart';
import '../features/market/screens/used_form.dart';
import '../features/proposal/models/proposal.dart';
import '../features/proposal/screens/propose_form.dart';
import '../features/proposal/screens/proposal_list_screen.dart';
import '../features/proposal/screens/world_map_screen.dart';
import '../features/proposal/widgets/proposal_sheet.dart';
import '../features/trip/screens/trip_tab.dart';
import '../features/trip/widgets/dart_sheet.dart';
import 'app_session.dart';
import 'neighbor_store.dart';

/// 탭 어디서나 같은 화면을 여는 길목.
///
/// 제안·이야기·럭키드로우·글쓰기는 홈·마켓·커뮤니티·마이 어디서든 열린다.
/// 화면마다 콜백을 열 개씩 내려보내지 않도록 셸이 이 객체 하나를 만들어 넘긴다.
class AppNav {
  final NeighborStore store;
  final String Function() nickname;

  /// 내 동네 이름 (예: 서초구)
  final String Function() area;
  final List<TaskItem> Function() items;
  final ErrandActions Function() actions;
  final void Function(String) flash;
  final VoidCallback openAskForm;
  final VoidCallback openSeaForm;

  /// 가는 김에 글쓰기 — going이면 제가 가요(도움 주기), 아니면 가는 분 찾아요(도움 요청). 부탁과 같은 글쓰기 화면이다
  final void Function({bool going}) openTripPost;

  /// 가는 김에 일정·부탁(서버)을 들고 있는 세션. 화면 테스트처럼 없으면 예시 일정만 보여 준다
  final AppSession? session;

  /// 거래 채팅 열기 (거래 id)
  final void Function(String tradeId)? openChat;

  /// 로그인이 필요한 행동을 로그인 뒤로 미룬다
  final void Function(VoidCallback)? requireLogin;

  /// 하단 '가는 김에' 탭으로 옮긴다
  final VoidCallback? goTripTab;

  /// 커뮤니티 탭으로 옮겨 [scope](local · travel · abroad)와 [place]로 거른다
  final void Function(String scope, {String? place}) goCommunity;

  /// 중고 물건 전달을 이웃에게 부탁한다 (돈벌기 목록에 '중고'로 올라간다)
  final void Function(UsedItem) requestDelivery;

  const AppNav({
    required this.store,
    required this.nickname,
    required this.area,
    required this.items,
    required this.actions,
    required this.flash,
    required this.openAskForm,
    required this.openSeaForm,
    required this.openTripPost,
    this.session,
    this.openChat,
    this.requireLogin,
    this.goTripTab,
    required this.goCommunity,
    required this.requestDelivery,
  });

  Future<T?> _push<T>(BuildContext context, Widget page) => Navigator.push<T>(context, MaterialPageRoute(builder: (_) => page));

  // ── 글쓰기 ──────────────────────────────────────────────────────────────

  /// 오른쪽 위 '글쓰기' — 어떤 글을 쓸지부터 고른다 (시안 v42)
  void openWrite(BuildContext context) {
    showSheet(context, (ctx) {
      Widget item(String icon, Color bg, Color fg, String title, String sub, VoidCallback go) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
          ),
          child: Tap(
            radius: 16,
            onTap: () {
              Navigator.pop(ctx);
              go();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                    child: Icon(_icons[icon], size: 21, color: fg),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(sub, style: const TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.4)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                ],
              ),
            ),
          ),
        ),
      );
      return SheetFrame(
        title: '어떤 글을 쓸까요?',
        sub: '쓰고 싶은 글을 골라요',
        child: Column(
          children: [
            item(
              'pencil',
              AppColors.blueSoft,
              AppColors.blue,
              '나 여기 가요',
              '가는 김에 — 갈 곳과 시간을 올리면 이웃이 "어! 나도!" 해요',
              () => openTripPost(going: true),
            ),
            item(
              'gift',
              const Color(0xFFFFF1E6),
              const Color(0xFFE5772E),
              '제안하기',
              '다녀오는 길에 사 올 수 있는 걸 올려요 · 인원 제한 없이도 OK',
              () => openPropose(context),
            ),
            item('hand', const Color(0xFFF7F1E0), AppColors.yellowInk, '부탁하기', '동네 이웃에게 일을 부탁해요', openAskForm),
            item('globe', AppColors.blueSoft, AppColors.blue, '해외 부탁하기', '여행 가는 이웃에게 사다주기를 부탁해요', openSeaForm),
            item('store', AppColors.greenSoft, AppColors.greenDeep, '중고 판매·나눔', '물건을 팔거나 나눠요', () => openUsedForm(context)),
            item('users', AppColors.purpleSoft, AppColors.purple, '커뮤니티 글쓰기', '질문, 후기, 동행, 동네 소식을 나눠요', () => compose(context)),
          ],
        ),
      );
    });
  }

  static const _icons = <String, IconData>{
    'pencil': Icons.edit_outlined,
    'gift': Icons.card_giftcard_rounded,
    'hand': Icons.back_hand_outlined,
    'globe': Icons.public_rounded,
    'store': Icons.storefront_outlined,
    'users': Icons.groups_outlined,
  };

  /// 가는 김에 — 전체보기 = 하단 '가는 김에' 탭으로
  void openTripFeed(BuildContext context) {
    final go = goTripTab;
    if (go != null) {
      go();
    } else {
      _push(context, PageFrame(title: '가는 김에', child: TripTab(nav: this)));
    }
  }


  void openUsedForm(BuildContext context, {bool share = false}) =>
      showSheet(context, (_) => UsedForm(seller: nickname(), area: area(), share: share, onSubmit: store.addUsed));

  void compose(BuildContext context, {String scope = 'local', ComPost? initial}) =>
      _push(context, ComComposeScreen(author: nickname(), scope: scope, initial: initial, onSubmit: store.addPost));

  // ── 제안 ────────────────────────────────────────────────────────────────

  void openPropose(BuildContext context, {bool abroad = false}) =>
      showSheet(context, (_) => ProposeForm(abroad: abroad, who: nickname(), area: area(), onSubmit: store.addProposal));

  void openProposal(BuildContext context, Proposal p) => ProposalSheet.show(
    context,
    store: store,
    p: p,
    onOpenPost: (c) => openPost(context, c.id),
    onMoreStories: () => goCommunity(p.abroad ? 'abroad' : 'travel', place: p.abroad ? p.cc : p.from),
    onReview: (x) => review(context, x),
    onOtherAsk: openAskForm,
    onOpenChat: openChat,
  );

  void openProposalList(BuildContext context, {required bool abroad}) => _push(
    context,
    ProposalListScreen(
      store: store,
      abroad: abroad,
      onOpen: (p) => openProposal(context, p),
      onPropose: () => openPropose(context, abroad: abroad),
    ),
  );

  /// 제안을 받았거나 전달한 뒤의 '후기 남기기'. 제목·지역이 채워져 열린다. (응모권 +1)
  void review(BuildContext context, Proposal p) => compose(
    context,
    initial: ComPost(
      id: 0,
      scope: p.abroad ? 'abroad' : 'travel',
      kind: '후기',
      place: p.abroad ? (p.cc ?? '') : p.from,
      title: '${p.from} ${p.item} 받았어요',
      body: '',
      author: nickname(),
      proposalId: p.id,
    ),
  );

  void openWorld(BuildContext context) => _push(
    context,
    WorldMapScreen(
      store: store,
      seaItems: items().where((i) => i.mode == 'sea').toList(),
      onOpenProposal: (p) => openProposal(context, p),
      onOpenTask: (t) => openTask(context, t),
      onOpenPost: (c) => openPost(context, c.id),
      onPropose: () => openPropose(context, abroad: true),
    ),
  );

  // ── 이야기 · 기타 ───────────────────────────────────────────────────────

  void openPost(BuildContext context, int id) => _push(
    context,
    ComPostScreen(
      store: store,
      postId: id,
      onOpenProposal: (pid) {
        final p = store.proposalById(pid);
        if (p != null) openProposal(context, p);
      },
    ),
  );

  void openLucky(BuildContext context) => _push(
    context,
    ListenableBuilder(
      listenable: store,
      builder: (_, _) => LuckyDrawScreen(wallet: () => store.wallet, onEnter: store.enterDraw),
    ),
  );

  void openDart(BuildContext context, {bool abroad = false}) => showSheet(
    context,
    (_) => DartSheet(
      abroad: abroad,
      onStories: (place, ab) {
        if (ab) {
          goCommunity('abroad');
        } else {
          goCommunity('travel', place: place);
        }
      },
    ),
  );

  void openUsed(BuildContext context, UsedItem item) =>
      _push(context, UsedDetailScreen(store: store, item: item, onDeliver: requestDelivery, flash: flash));

  void openTask(BuildContext context, TaskItem it) => actions().open(context, it);
}
