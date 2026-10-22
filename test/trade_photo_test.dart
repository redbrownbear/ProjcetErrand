import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/features/errand/models/application.dart';
import 'package:gyeomsa/features/errand/repositories/photo_repository.dart';
import 'package:gyeomsa/features/profile/models/app_notice.dart';

/// A37 거래 사진: 서버 문서 → 앱 모델
void main() {
  test('사진 문서: 영수증 금액 · 역할, 모르는 종류는 버린다', () {
    final p = TradePhoto.fromDoc('p1', {
      'uid': 'h',
      'role': 'helper',
      'kind': 'receipt',
      'path': 'trades/t/h/1.jpg',
      'amount': 4500,
      'createdAt': Timestamp.fromDate(DateTime(2026, 10, 22, 18)),
    })!;
    expect(p.isReceipt, isTrue);
    expect(p.amount, 4500);
    expect(p.createdAt, DateTime(2026, 10, 22, 18));
    expect(TradePhoto.fromDoc('p2', {'kind': 'selfie', 'path': 'x'}), isNull);
    expect(TradePhoto.fromDoc('p3', {'kind': 'proof'}), isNull);
  });

  test('거래: 사진 수 · 진행 중일 때만 올리기', () {
    final t = ServerTrade.fromDoc('t1', {'status': 'working', 'requestId': '1', 'photoCount': 3})!;
    expect(t.photoCount, 3);
    expect(t.canAddPhoto, isTrue);
    expect(ServerTrade.fromDoc('t2', {'status': 'completed', 'requestId': '1'})!.canAddPhoto, isFalse);
  });

  test('알림: 거래 id를 읽는다', () {
    final n = AppNotice.fromDoc('n', {'title': '영수증이 올라왔어요', 'kind': 'trade.photo', 'tradeId': 't1'})!;
    expect(n.tradeId, 't1');
  });
}
