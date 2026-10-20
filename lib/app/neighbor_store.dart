import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/backend/backend.dart';

import '../core/storage/local_store.dart';
import '../features/community/data/com_posts.dart';
import '../features/community/models/com_post.dart';
import '../features/errand/models/comment.dart';
import '../features/lucky/models/tickets.dart';
import '../features/market/models/used_item.dart';
import '../features/proposal/data/proposals.dart';
import '../features/proposal/models/proposal.dart';
import '../features/trip/models/trip_post.dart';
import '../features/trip/repositories/trip_repository.dart';
import '../core/utils/stable_sort.dart';

/// v77에서 새로 생긴 이웃 활동(제안 · 커뮤니티 이야기 · 가는 김에 · 중고 · 응모권)을 한곳에 둔다.
///
/// 부탁·거래·포인트·겸사페이는 원래대로 [HomeShell]이 들고 있고, 여기는 그 바깥의
/// 새 기능만 맡는다. 화면은 이 객체를 듣고([ListenableBuilder]) 다시 그린다.
/// '가는 김에'는 서버(`tripPosts`)에 올라가 모든 계정이 보고 댓글을 단다. 나머지는 아직 이 기기에만 보관된다(`LocalStore`).
class NeighborStore extends ChangeNotifier {
  NeighborStore() {
    _load();
  }

  /// 토스트를 띄우는 곳. 셸이 연결한다.
  void Function(String)? toast;

  /// 실제 참여 행동을 로그인 뒤로 미루는 문. 셸이 연결한다. 없으면 바로 실행.
  Future<void> Function(VoidCallback)? gate;

  /// 지금 로그인한 계정. 셸이 연결한다. '가는 김에' 내 글 판단·올리기에 쓴다.
  String? Function()? uid;

  /// 지금 시각. 테스트에서 바꿔 끼운다.
  DateTime Function() clock = DateTime.now;

  TicketWallet wallet = const TicketWallet();
  late final List<Proposal> _seedProposals = seedProposals();
  List<Proposal> myProposals = [];
  Set<int> joined = {};
  List<ComPost> myPosts = [];
  Map<int, List<Comment>> myComments = {};
  Set<int> likedPosts = {};
  List<TripPost> myTrips = [];
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
    myTrips = [for (final j in LocalStore.read<List<dynamic>>('tripPosts', const [])) ?TripPost.fromJson(j)];
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

  List<Proposal> get proposals => [...myProposals, ..._seedProposals];

  List<Proposal> board({required bool abroad}) {
    int closed(Proposal p) => p.expired || p.isFull(joined.contains(p.id)) ? 1 : 0;
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
    myProposals = [p, ...myProposals];
    LocalStore.write('proposals', [for (final x in myProposals) x.toJson()]);
    notifyListeners();
    toast?.call('제안을 올렸어요 · 원하는 이웃이 구매를 누르면 알려드려요');
  });

  /// '저 구매할래요!' 누르기 / 취소하기
  void toggleJoin(Proposal p) => _run(() {
    final on = joined.contains(p.id);
    if (!on && (p.expired || p.isFull(false))) {
      toast?.call('정원이 찼어요 · 다른 제안을 둘러보세요');
      return;
    }
    if (p.mine) {
      toast?.call('내가 올린 제안이에요');
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

  final TripRepository _trips = const TripRepository();
  List<TripPost> serverTrips = [];
  StreamSubscription<List<TripPost>>? _tripSub;

  /// 서버의 '가는 김에' 글을 구독한다. 셸이 한 번 부른다.
  void watchTrips() {
    if (!Backend.ready || _tripSub != null) return;
    _tripSub = _trips.watch().listen((list) {
      serverTrips = list;
      notifyListeners();
    });
  }

  /// 서버에 연결돼 있으면 서버 글만(이 기기 글은 다른 계정에 안 보여서 섞지 않는다), 아니면 이 기기 글. 예시 글은 뒤에.
  List<TripPost> get trips => [...(Backend.ready ? serverTrips : myTrips), ...seedTripPosts];

  TripPost? tripById(int id) {
    for (final t in trips) {
      if (t.id == id) return t;
    }
    return null;
  }

  bool isMyTrip(TripPost t) => t.isMine(uid?.call());

  void addTrip(TripPost t) => _run(() async {
    final me = uid?.call();
    if (Backend.ready && me != null) {
      try {
        await _trips.add(t, me);
        toast?.call('가는 김에 글을 올렸어요 · 이웃이 댓글로 부탁·도움을 남길 수 있어요');
      } catch (e) {
        debugPrint('가는 김에 올리기 실패: $e');
        toast?.call('글을 올리지 못했어요. 네트워크를 확인하고 다시 시도해 주세요');
      }
      return;
    }
    myTrips = [t, ...myTrips];
    LocalStore.write('tripPosts', [for (final x in myTrips) x.toJson()]);
    notifyListeners();
    toast?.call('가는 김에 글을 올렸어요 · 서버에 연결되지 않아 이 기기에만 보여요');
  });

  Future<void> deleteTrip(TripPost t) async {
    if (t.server) {
      try {
        await _trips.delete(t.id);
        toast?.call('글을 지웠어요');
      } catch (e) {
        toast?.call('지우지 못했어요. 잠시 후 다시 시도해 주세요');
      }
      return;
    }
    myTrips = [for (final x in myTrips) if (x.id != t.id) x];
    LocalStore.write('tripPosts', [for (final x in myTrips) x.toJson()]);
    notifyListeners();
  }

  @override
  void dispose() {
    _tripSub?.cancel();
    super.dispose();
  }

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
