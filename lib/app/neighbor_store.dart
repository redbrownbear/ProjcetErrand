import 'package:flutter/foundation.dart';

import '../core/storage/local_store.dart';
import '../features/community/data/com_posts.dart';
import '../features/community/models/com_post.dart';
import '../features/errand/models/comment.dart';
import '../features/lucky/models/tickets.dart';
import '../features/market/models/used_item.dart';
import '../features/proposal/data/proposals.dart';
import '../features/proposal/models/proposal.dart';
import '../features/trip/models/trip_post.dart';

/// v77에서 새로 생긴 이웃 활동(제안 · 커뮤니티 이야기 · 가는 김에 · 중고 · 응모권)을 한곳에 둔다.
///
/// 부탁·거래·포인트·겸사페이는 원래대로 [HomeShell]이 들고 있고, 여기는 그 바깥의
/// 새 기능만 맡는다. 화면은 이 객체를 듣고([ListenableBuilder]) 다시 그린다.
/// 전부 이 기기에만 보관된다(`LocalStore`) — 서버 연동 전 체험 단계다.
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
          int.parse(e.key): [for (final c in e.value as List) if (c is Map) Comment('${c['who']}', '${c['text']}')],
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
    final list = proposals.where((p) => p.abroad == abroad).toList();
    // 열린 것 먼저, 마감은 아래로
    list.sort((a, b) {
      final af = a.expired || a.isFull(joined.contains(a.id)) ? 1 : 0;
      final bf = b.expired || b.isFull(joined.contains(b.id)) ? 1 : 0;
      if (af != bf) return af - bf;
      return 0;
    });
    return list;
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
        toast?.call(on ? '구매 요청을 취소했어요' : '구매 요청을 보냈어요 · 제안자가 확인하면 채팅이 열려요');
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
          for (final e in myComments.entries) '${e.key}': [for (final c in e.value) {'who': c.who, 'text': c.text}],
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

  List<TripPost> get trips => [...myTrips, ...seedTripPosts];

  void addTrip(TripPost t) => _run(() {
        myTrips = [t, ...myTrips];
        LocalStore.write('tripPosts', [for (final x in myTrips) x.toJson()]);
        notifyListeners();
        toast?.call('가는 김에 글을 올렸어요');
      });

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
          toast?.call('신청했어요 · 현지 이웃이 확인하면 채팅이 열려요');
        }
        LocalStore.write('appliedLocal', appliedLocal.toList());
        notifyListeners();
      });
}
