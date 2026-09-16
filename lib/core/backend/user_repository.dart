import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/benefits/models/coupon.dart';
import '../../features/errand/models/offer.dart';
import '../../features/errand/models/trade.dart';
import '../../features/profile/models/user_profile.dart';
import 'backend.dart';

/// 로그인한 사용자 한 명의 서버 자료를 읽고 쓴다.
///
/// 구조는 전부 `users/{uid}` 아래에 둔다. 다른 사람이 볼 이유가 없는 자료라
/// 보안 규칙을 "본인만"으로 한 줄로 끝낼 수 있기 때문이다.
///
/// ```
/// users/{uid}                프로필 (닉네임·지역·포인트·본인인증)
///   bookmarks/{requestId}    관심 저장
///   trades/{requestId}       지원·거래 단계와 시각
///   offers/{requestId}       내가 보낸 가격 제안
///   coupons/{couponId}       교환한 쿠폰
///   ledger/{rewardKey}       포인트 적립 원장 (중복 지급 방지)
/// ```
///
/// 모든 호출은 [Backend.guard]를 지난다. 서버가 없거나 느리면 빈 값으로 돌아오고,
/// 화면은 이 기기의 [LocalStore] 값으로 이어서 동작한다.
class UserRepository {
  final String uid;
  const UserRepository(this.uid);

  DocumentReference<Map<String, dynamic>> get _doc => Backend.users.doc(uid);
  CollectionReference<Map<String, dynamic>> _sub(String name) => _doc.collection(name);

  // ── 프로필 ──────────────────────────────────────────────────────────────

  /// 프로필 문서를 읽고, 없으면 계정 정보로 만들어 준다.
  ///
  /// 가입 때 [AuthService]가 한 번 만들지만, 그때 Firestore가 느려서 실패했거나
  /// 콘솔에서 지워졌을 수도 있다. 로그인할 때마다 한 번 확인해 두면
  /// "가입은 됐는데 내 정보 화면이 비어 있는" 상태가 생기지 않는다.
  Future<UserProfile?> ensureProfile({required String email, String? nickname}) async {
    return Backend.guard<UserProfile?>(() async {
      final snap = await _doc.get();
      final data = snap.data();
      if (snap.exists && data != null) {
        final profile = UserProfile.fromMap(uid, data);
        // 계정 쪽 닉네임이 더 최신이면 맞춰 둔다
        if (nickname != null && nickname.isNotEmpty && nickname != profile.nickname) {
          await _doc.set({'nickname': nickname, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
          return profile.copyWith(nickname: nickname);
        }
        return profile;
      }
      final fresh = UserProfile.blank(uid: uid, email: email, nickname: nickname);
      await _doc.set({
        ...fresh.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return fresh;
    }, null);
  }

  Future<void> savePoints(int points) => Backend.push(
        () => _doc.set({'points': points, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true)),
      );

  Future<void> saveProfileFields({String? nickname, String? region, bool? verified}) => Backend.push(
        () => _doc.set({
          if (nickname != null) 'nickname': nickname,
          if (region != null) 'region': region,
          if (verified != null) 'verified': verified,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );

  // ── 관심 저장 ───────────────────────────────────────────────────────────

  Future<List<int>> loadBookmarks() => Backend.guard<List<int>>(() async {
        final snap = await _sub('bookmarks').get();
        return [
          for (final d in snap.docs)
            if (int.tryParse(d.id) != null) int.parse(d.id),
        ];
      }, const []);

  Future<void> setBookmark(int requestId, bool on) => Backend.push(() async {
        final doc = _sub('bookmarks').doc('$requestId');
        if (on) {
          await doc.set({'createdAt': FieldValue.serverTimestamp()});
        } else {
          await doc.delete();
        }
      });

  // ── 지원·거래 단계 ──────────────────────────────────────────────────────

  Future<Map<int, Trade>> loadTrades() => Backend.guard<Map<int, Trade>>(() async {
        final snap = await _sub('trades').get();
        final out = <int, Trade>{};
        for (final d in snap.docs) {
          final id = int.tryParse(d.id);
          final t = _tradeFrom(d.data());
          if (id != null && t != null) out[id] = t;
        }
        return out;
      }, const {});

  /// 거래 단계를 저장한다. [title]·[price]는 나중에 정산 내역을 서버만 보고
  /// 그릴 수 있도록 같이 남기는 사본이다.
  Future<void> saveTrade(int requestId, Trade trade, {String? title, int? price, String? mode}) => Backend.push(
        () => _sub('trades').doc('$requestId').set({
          'status': trade.status,
          'updatedAt': Timestamp.fromDate(trade.updatedAt),
          if (title != null) 'title': title,
          if (price != null) 'price': price,
          if (mode != null) 'mode': mode,
        }, SetOptions(merge: true)),
      );

  static Trade? _tradeFrom(Map<String, dynamic> m) {
    final status = m['status'];
    final at = m['updatedAt'];
    if (status is! String || !Trade.labels.containsKey(status)) return null;
    final when = at is Timestamp ? at.toDate() : DateTime.tryParse('$at');
    return Trade(status, when ?? DateTime.now());
  }

  // ── 가격 제안 ───────────────────────────────────────────────────────────

  Future<Map<int, List<Offer>>> loadOffers() => Backend.guard<Map<int, List<Offer>>>(() async {
        final snap = await _sub('offers').get();
        final out = <int, List<Offer>>{};
        for (final d in snap.docs) {
          final id = int.tryParse(d.id);
          final raw = d.data()['items'];
          if (id == null || raw is! List) continue;
          out[id] = [
            for (final o in raw)
              if (o is Map && o['price'] is int) Offer(o['price'] as int, o['msg'] is String ? o['msg'] as String : ''),
          ];
        }
        return out;
      }, const {});

  Future<void> saveOffers(int requestId, List<Offer> offers) => Backend.push(
        () => _sub('offers').doc('$requestId').set({
          'items': [for (final o in offers) {'price': o.price, 'msg': o.msg}],
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );

  // ── 쿠폰 ────────────────────────────────────────────────────────────────

  Future<List<Coupon>> loadCoupons() => Backend.guard<List<Coupon>>(() async {
        final snap = await _sub('coupons').orderBy('createdAt', descending: true).get();
        return [
          for (final d in snap.docs)
            if (int.tryParse(d.id) != null)
              Coupon(
                id: int.parse(d.id),
                brandK: '${d.data()['brandK'] ?? ''}',
                name: '${d.data()['name'] ?? ''}',
                points: d.data()['points'] is int ? d.data()['points'] as int : 0,
                exp: '${d.data()['exp'] ?? ''}',
                code: '${d.data()['code'] ?? ''}',
                used: d.data()['used'] == true,
              ),
        ];
      }, const []);

  Future<void> saveCoupon(Coupon c) => Backend.push(
        () => _sub('coupons').doc('${c.id}').set({
          'brandK': c.brandK,
          'name': c.name,
          'points': c.points,
          'exp': c.exp,
          'code': c.code,
          'used': c.used,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );

  // ── 포인트 적립 원장 ────────────────────────────────────────────────────

  /// key -> 받은 날짜('YYYY-MM-DD') 또는 '*'(1회성)
  Future<Map<String, String>> loadLedger() => Backend.guard<Map<String, String>>(() async {
        final snap = await _sub('ledger').get();
        return {
          for (final d in snap.docs) d.id: '${d.data()['on'] ?? '*'}',
        };
      }, const {});

  Future<void> saveLedgerEntry(String key, String value, int amount, String label) => Backend.push(
        () => _sub('ledger').doc(key).set({
          'on': value,
          'amount': amount,
          'label': label,
          'claimedAt': FieldValue.serverTimestamp(),
        }),
      );

  // ── 첫 로그인 이관 ──────────────────────────────────────────────────────

  /// 이 기기에 있던 자료를 이미 이 계정으로 올렸는지.
  /// 여러 번 올려서 관심 목록이 두 배가 되는 걸 막는다.
  Future<bool> isMigrated() => Backend.guard<bool>(() async {
        final snap = await _doc.get();
        return snap.data()?['migratedFromDevice'] == true;
      }, true); // 서버를 못 읽으면 "이미 했다"로 봐서 중복 업로드를 피한다

  Future<void> markMigrated() => Backend.push(
        () => _doc.set({'migratedFromDevice': true, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true)),
      );
}
