import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/features/chat/models/chat_message.dart';
import 'package:gyeomsa/features/errand/models/application.dart';
import 'package:gyeomsa/features/profile/models/app_notice.dart';

/// 서버 문서 → 앱 모델 변환 (W3·W4). 서버가 쓰는 필드 이름이 바뀌면 여기서 먼저 깨진다.
void main() {
  test('지원서: 서버 사본 필드를 읽고, 없으면 지어내지 않고 기본값', () {
    final a = Application.fromDoc('1760000000000', 'h1', {
      'status': 'pending',
      'requesterUid': 'r1',
      'helperName': '지수',
      'requestTitle': '택배 찾기',
      'offerPrice': 4000,
      'msg': '퇴근길에 갈게요',
      'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 20, 9)),
    })!;
    expect(a.isPending, isTrue);
    expect(a.requestIdInt, 1760000000000);
    expect(a.helperName, '지수');
    expect(a.offerPrice, 4000);
    expect(a.updatedAt, DateTime(2026, 10, 20, 9));

    final bare = Application.fromDoc('x', 'h2', {'status': 'rejected'})!;
    expect(bare.helperName, '이웃');
    expect(bare.requestIdInt, isNull);
    expect(bare.offerPrice, isNull);
    expect(Application.fromDoc('1', 'h', {'status': 3}), isNull);
  });

  test('거래 문서: 상태·부탁 id가 없으면 버린다', () {
    final t = ServerTrade.fromDoc('t1', {'status': 'working', 'requestId': '1', 'price': 3000, 'helperUid': 'h'})!;
    expect(t.status, 'working');
    expect(t.price, 3000);
    expect(ServerTrade.fromDoc('t2', {'status': 'working'}), isNull);
  });

  test('거래 문서의 채팅 요약: 마지막 메시지·사람별 안 읽은 수', () {
    final t = ServerTrade.fromDoc('t1', {
      'status': 'matched',
      'requestId': '1',
      'lastMessage': {'text': '도착했어요', 'at': Timestamp.fromDate(DateTime(2026, 10, 20, 10)), 'by': 'h'},
      'unread': {'r': 2, 'h': 0, 'x': 'bad'},
    })!;
    expect(t.lastMessage, '도착했어요');
    expect(t.lastMessageAt, DateTime(2026, 10, 20, 10));
    expect(t.unreadFor('r'), 2);
    expect(t.unreadFor('nobody'), 0);
    expect(t.isOpenForChat, isTrue);
    expect(ServerTrade.fromDoc('t2', {'status': 'cancelled', 'requestId': '1'})!.isOpenForChat, isFalse);
  });

  test('채팅 메시지: 보낸 사람·내용이 없으면 버린다', () {
    final m = ChatMessage.fromDoc('m1', {'senderUid': 'h', 'text': '[전화번호 가림]로 연락', 'masked': true})!;
    expect(m.masked, isTrue);
    expect(ChatMessage.fromDoc('m2', {'text': 'x'}), isNull);
  });

  test('알림: readAt이 있으면 읽음', () {
    final unread = AppNotice.fromDoc('n1', {'title': '새 지원이 왔어요', 'body': 'b', 'readAt': null})!;
    final read = AppNotice.fromDoc('n2', {'title': 't', 'readAt': Timestamp.now()})!;
    expect(unread.read, isFalse);
    expect(read.read, isTrue);
    expect(AppNotice.fromDoc('n3', {'body': '제목 없음'}), isNull);
  });
}
