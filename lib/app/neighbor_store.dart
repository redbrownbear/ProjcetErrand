import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/storage/local_store.dart';
import '../features/community/data/com_posts.dart';
import '../features/community/models/com_post.dart';
import '../features/errand/models/comment.dart';
import '../features/errand/repositories/activity_repository.dart';
import '../features/lucky/models/tickets.dart';
import '../features/market/models/used_item.dart';
import '../features/proposal/data/proposals.dart';
import '../features/proposal/models/proposal.dart';
import '../features/proposal/repositories/proposal_repository.dart';
import '../core/backend/server_api.dart';
import '../core/utils/stable_sort.dart';

/// v77에서 새로 생긴 이웃 활동(제안 · 커뮤니티 이야기 · 가는 김에 · 중고 · 응모권)을 한곳에 둔다.
///
/// 부탁·거래·포인트·겸사페이는 원래대로 [HomeShell]이 들고 있고, 여기는 그 바깥의
/// 새 기능만 맡는다. 화면은 이 객체를 듣고([ListenableBuilder]) 다시 그린다.
/// 이 기기에 보관된다(`LocalStore`). 제안은 서버에 연결되면 서버에 올라간다([attachServer], A15).
/// '가는 김에'는 부탁과 같은 흐름이라 여기 없다(AppSession · requests).
class NeighborStore extends ChangeNotifier {
  NeighborStore() {
    _load();
  }

  /// 토스트를 띄우는 곳. 셸이 연결한다.
  void Function(String)? toast;

  /// 실제 참여 행동을 로그인 뒤로 미루는 문. 셸이 연결한다. 없으면 바로 실행.
  Future<void> Function(VoidCallback)? gate;

  /// 지금 시각. 테스트에서 바꿔 끼운다.
  DateTime Function() clock = DateTime.now;

  TicketWallet wallet = const TicketWallet();
  late final List<Proposal> _seedProposals = seedProposals();
  List<Proposal> myProposals = [];
  Set<int> joined = {};
  List<ComPost> myPosts = [];
  Map<int, List<Comment>> myComments = {};
  Set<int> likedPosts = {};
  List<UsedItem> myUsed = [];
  Set<int> likedUsed = {};
  Set<int> appliedLocal = {};

  void _load() {
    wallet = TicketWallet.load(clock());
    myProposals = [for (final j in LocalStore.read<List<dynamic>>('proposals', const [])) ?Proposal.fromJson(j)];
    joined = LocalStore.read<List<dynamic>>('joinedProposals', const []).whereType<int>().toSet();
    myPosts = [for (final j in LocalStore.read<List<dynamic>>('comPosts', const [])) ?ComPost.fromJson(j)];
    myComments = {
      for (final e in LocalStore.read<Map<String, dynamic>>('comComments', const {}).entries)
        if (int.tryParse(e.key) != null && e.value is List)
          int.parse(e.key): [
            for (final c in e.value as List)
              if (c is Map) Comment('${c['who']}', '${c['text']}'),
          ],
    };
    likedPosts = LocalStore.read<List<dynamic>>('likedPosts', const []).whereType<int>().toSet();
    myUsed = [for (final j in LocalStore.read<List<dynamic>>('usedItems', const [])) ?UsedItem.fromJson(j)];
    likedUsed = LocalStore.read<List<dynamic>>('likedUsed', const []).whereType<int>().toSet();
    appliedLocal = LocalStore.read<List<dynamic>>('appliedLocal', const []).whereType<int>().toSet();
  }

  void _run(VoidCallback f) {
    final g = gate;
    if (g == null) {
      f();
    } else {
      g(f);
    }
  }

  // ── 응모권 ──────────────────────────────────────────────────────────────

  /// 규칙대로 응모권을 준다. 받았으면 받은 장수, 이미 받은 것이면 0.
  int gainTicket(TicketRule rule, {int? n, bool quiet = false}) {
    final next = wallet.gain(rule, clock(), n: n);
    if (next == null) return 0;
    wallet = next;
    wallet.save();
    notifyListeners();
    final got = n ?? rule.n;
    if (!quiet) toast?.call('응모권 +$got장 · ${rule.label}');
    return got;
  }

  bool enterDraw(int n) {
    final next = wallet.enter(n, clock());
    if (next == null) {
      toast?.call('보유한 응모권보다 많이 응모할 수 없어요');
      return false;
    }
    wallet = next;
    wallet.save();
    notifyListeners();
    toast?.call('응모권 $n장으로 응모했어요 · 발표는 ${LuckyDraw(clock()).month}월 말이에요');
    return true;
  }

  // ── 제안 ────────────────────────────────────────────────────────────────

  /// 서버 제안(A15). 로그인해서 서버에 붙었을 때만 쓴다 — 그때는 이 기기에만 있는 옛 제안을 섞지 않는다
  ProposalRepository? proposalRepo;
  List<Proposal> serverProposals = [];
  StreamSubscription<List<Proposal>>? _proposalSub;
  StreamSubscription<Set<int>>? _joinSub;

  /// 최근 완료된 거래(A23, LIVE 보드 티커). 서버에 붙었을 때만
  List<DoneActivity> recentDone = [];
  StreamSubscription<List<DoneActivity>>? _doneSub;

  /// 로그인한 uid가 바뀔 때 셸이 부른다. null이면 서버 구독을 끊고 이 기기 제안으로 돌아간다
  void attachServer(String? uid, {ProposalRepository Function(String uid)? repo, ActivityRepository? activity}) {
    if (proposalRepo?.uid == uid) return;
    _proposalSub?.cancel();
    _joinSub?.cancel();
    _doneSub?.cancel();
    _proposalSub = null;
    _joinSub = null;
    _doneSub = null;
    serverProposals = [];
    recentDone = [];
    if (uid == null) {
      proposalRepo = null;
      joined = LocalStore.read<List<dynamic>>('joinedProposals', const []).whereType<int>().toSet();
    } else {
      final r = proposalRepo = (repo ?? ProposalRepository.new)(uid);
      joined = {};
      _proposalSub = r.watch().listen((list) {
        serverProposals = list;
        notifyListeners();
      });
      _joinSub = r.watchMyJoins().listen((ids) {
        joined = ids;
        notifyListeners();
      });
      _doneSub = (activity ?? const ActivityRepository()).watchRecent().listen((list) {
        recentDone = list;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _proposalSub?.cancel();
    _joinSub?.cancel();
    _doneSub?.cancel();
    super.dispose();
  }

  /// 서버에 붙으면 실제 제안만(A23). 로그인 전 · 서버 연결 전에는 이 기기 제안 + 체험용 예시
  bool get live => proposalRepo != null;

  List<Proposal> get proposals => live ? serverProposals : [...myProposals, ..._seedProposals];

  /// 보드 티커에 띄울 최근 완료(일주일 안)
  List<DoneActivity> recentDoneFor({required bool abroad}) {
    final since = clock().subtract(const Duration(days: 7));
    return [for (final a in recentDone) if (a.abroad == abroad && a.at.isAfter(since)) a];
  }

  /// 내가 올린 제안 (마이 · 제안 목록)
  List<Proposal> get mine => proposals.where((p) => p.mine).toList();

  List<Proposal> board({required bool abroad}) {
    int closed(Proposal p) => p.openFor(joined.contains(p.id)) ? 0 : 1;
    // 열린 것 먼저, 마감은 아래로. 같은 칸 안에서는 올린 순서를 지킨다.
    return proposals.where((p) => p.abroad == abroad).toList()..sortStable((a, b) => closed(a) - closed(b));
  }

  Proposal? proposalById(int id) {
    for (final p in proposals) {
      if (p.id == id) return p;
    }
    return null;
  }

  void addProposal(Proposal p) => _run(() {
    final r = proposalRepo;
    if (r != null) {
      _server(() => r.create(p), '제안을 올렸어요 · 원하는 이웃이 구매를 누르면 알려드려요');
      return;
    }
    myProposals = [p, ...myProposals];
    LocalStore.write('proposals', [for (final x in myProposals) x.toJson()]);
    notifyListeners();
    toast?.call('제안을 올렸어요 · 이 기기에만 저장돼요(서버 연결 전)');
  });

  /// 서버 함수를 부르고 결과를 토스트로. 실패 문구는 서버가 보낸 한국어 그대로
  Future<void> _server(Future<void> Function() job, String done) async {
    try {
      await job();
      toast?.call(done);
    } on ServerException catch (e) {
      toast?.call(e.message);
    }
  }

  /// 제안자의 결정 — proceed(지금 인원으로 진행) · cancel(제안 취소)
  Future<void> decideProposal(Proposal p, String action) async {
    final r = proposalRepo;
    if (r == null || !p.onServer) return;
    await _server(() => r.decide(p.id, action), action == 'cancel' ? '제안을 취소했어요 · 신청한 이웃에게 알렸어요' : '진행하기로 했어요 · 신청한 이웃에게 알렸어요');
  }

  /// 제안자에게 따로 부탁(A29) — 제안에 없는 물건도 사다 줄 수 있는지 묻는다. 보냈으면 true
  Future<bool> askProposer(Proposal p, {required String item, int? est, String note = ''}) async {
    final r = proposalRepo;
    if (r == null || !p.onServer || p.mine) return false;
    try {
      await r.ask(p.id, item: item, est: est, note: note);
      toast?.call('제안자에게 부탁을 보냈어요 · 수락하면 채팅이 열려요');
      return true;
    } on ServerException catch (e) {
      toast?.call(e.message);
      return false;
    }
  }

  /// 따로 온 부탁에 답하기 — 수락하면 거래가 생기고 채팅이 열린다
  Future<void> answerAsk(Proposal p, String askerUid, bool accept) async {
    final r = proposalRepo;
    if (r == null || !p.onServer) return;
    await _server(() => r.answerAsk(p.id, askerUid, accept), accept ? '부탁을 맡았어요 · 채팅 탭에서 이야기해 보세요' : '어렵다고 알렸어요');
  }

  /// '저 구매할래요!' 누르기 / 취소하기
  void toggleJoin(Proposal p) => _run(() {
    final on = joined.contains(p.id);
    if (!on && !p.openFor(false)) {
      toast?.call(p.proceeding ? '모집이 끝난 제안이에요' : '정원이 찼어요 · 다른 제안을 둘러보세요');
      return;
    }
    if (p.mine) {
      toast?.call('내가 올린 제안이에요');
      return;
    }
    final r = proposalRepo;
    if (r != null) {
      if (!p.onServer) {
        toast?.call('예시 제안이라 구매 요청을 보낼 수 없어요');
        return;
      }
      _server(() => on ? r.leave(p.id) : r.join(p.id), on ? '구매 요청을 취소했어요' : '구매 요청을 보냈어요 · 제안자에게 알렸어요');
      return;
    }
    joined = on ? ({...joined}..remove(p.id)) : {...joined, p.id};
    LocalStore.write('joinedProposals', joined.toList());
    notifyListeners();
    toast?.call(on ? '구매 요청을 취소했어요' : '구매 요청을 표시했어요 · 제안은 아직 서버 연결 전이라 제안자에게 전달되지 않아요');
  });

  // ── 커뮤니티 ────────────────────────────────────────────────────────────

  List<ComPost> get posts => [
    for (final p in [...myPosts, ...seedComPosts])
      myComments[p.id] == null ? p : p.copyWith(comments: [...p.comments, ...myComments[p.id]!]),
  ];

  List<ComPost> postsOf(String scope) => posts.where((p) => p.scope == scope).toList();

  /// 제안과 같은 지역·나라의 이야기 (제안 상세 · 나라 시트에 붙는다)
  List<ComPost> related(Proposal p) => posts.where((c) {
    if (p.abroad) return c.scope == 'abroad' && c.place == p.cc;
    return c.scope == 'travel' && (c.place == p.from || c.place == p.to);
  }).toList();

  ComPost? postById(int id) {
    for (final p in posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  void addPost(ComPost p) => _run(() {
    myPosts = [p, ...myPosts];
    LocalStore.write('comPosts', [for (final x in myPosts) x.toJson()]);
    notifyListeners();
    gainTicket(TicketRules.community, quiet: true);
    toast?.call(p.kind == '후기' ? '후기를 올렸어요 · 응모권 +1장' : '글을 올렸어요 · 응모권 +1장');
  });

  void addComment(int postId, String text, {String who = '나'}) => _run(() {
    final list = [...?myComments[postId], Comment(who, text)];
    myComments = {...myComments, postId: list};
    LocalStore.write('comComments', {
      for (final e in myComments.entries)
        '${e.key}': [
          for (final c in e.value) {'who': c.who, 'text': c.text},
        ],
    });
    notifyListeners();
    gainTicket(TicketRules.community, quiet: true);
    toast?.call('답글을 달았어요 · 응모권 +1장');
  });

  void toggleLike(int postId) {
    likedPosts = likedPosts.contains(postId) ? ({...likedPosts}..remove(postId)) : {...likedPosts, postId};
    LocalStore.write('likedPosts', likedPosts.toList());
    notifyListeners();
  }

  // ── 가는 김에 ───────────────────────────────────────────────────────────

  // ── 중고 · 나눔 ─────────────────────────────────────────────────────────

  List<UsedItem> get used => [...myUsed, ...seedUsedItems];

  void addUsed(UsedItem u) => _run(() {
    myUsed = [u, ...myUsed];
    LocalStore.write('usedItems', [for (final x in myUsed) x.toJson()]);
    notifyListeners();
    toast?.call(u.share ? '나눔을 올렸어요' : '판매글을 올렸어요');
  });

  void toggleUsedLike(int id) {
    likedUsed = likedUsed.contains(id) ? ({...likedUsed}..remove(id)) : {...likedUsed, id};
    LocalStore.write('likedUsed', likedUsed.toList());
    notifyListeners();
  }

  // ── 현지 이웃 ───────────────────────────────────────────────────────────

  void applyLocal(int id) => _run(() {
    if (appliedLocal.contains(id)) {
      appliedLocal = {...appliedLocal}..remove(id);
      toast?.call('신청을 취소했어요');
    } else {
      appliedLocal = {...appliedLocal, id};
      toast?.call('신청을 표시했어요 · 아직 서버 연결 전이라 현지 이웃에게 전달되지 않아요');
    }
    LocalStore.write('appliedLocal', appliedLocal.toList());
    notifyListeners();
  });
}
