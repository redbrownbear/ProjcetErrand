import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/features/chat/models/chat_message.dart';
import 'package:gyeomsa/features/errand/models/application.dart';
import 'package:gyeomsa/features/profile/models/app_notice.dart';
import 'package:gyeomsa/features/trip/models/trip_post.dart';

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

group('가는 김에 글', () {
  test('서버 글: 내 글 여부는 계정으로 판단한다(같은 기기의 다른 계정에겐 남의 글)', () {
    final t = TripPost.fromDoc('1760000000000', {
      'ownerUid': 'a',
      'author': '민지',
      'type': 'going',
      'title': '오사카 가요',
      'quote': '필요한 거 있으면 댓글 주세요',
      'commentCount': 2,
      'createdAt': Timestamp.fromDate(DateTime(2026, 10, 20, 10)),
    })!;
    expect(t.server, isTrue);
    expect(t.isMine('a'), isTrue);
    expect(t.isMine('b'), isFalse);
    expect(t.isMine(null), isFalse);
    expect(t.comments, 2);
    expect(t.agoAt(DateTime(2026, 10, 20, 10, 5)), '5분 전');
    expect(t.agoAt(DateTime(2026, 10, 20, 13)), '3시간 전');
  });

  test('필수 값이 없으면 버린다', () {
    expect(TripPost.fromDoc('abc', {'title': 'x', 'quote': 'y'}), isNull);
    expect(TripPost.fromDoc('1', {'quote': 'y'}), isNull);
  });

  test('제목 제안 — 장소만 쓰면 자연스럽게, 비우면 빈칸', () {
    expect(TripPost.suggestTitle('going', ' 오사카 '), '오사카 가요');
    expect(TripPost.suggestTitle('asking', '성수동'), '성수동 가시는 분 있나요?');
    expect(TripPost.suggestTitle('going', ''), '');
  });

  test('서버 문서는 규칙의 필드 목록 안에서만 쓴다', () {
    const t = TripPost(id: 1, type: 'going', author: '아주아주아주아주아주아주긴닉네임입니다', area: '반포동', title: 't', when: '', quote: 'q');
    final m = t.toDoc('a');
    expect(
      m.keys.toSet(),
      {'ownerUid', 'author', 'area', 'type', 'cc', 'where', 'title', 'when', 'quote', 'commentCount', 'createdAt'},
    );
    expect((m['author'] as String).length, lessThanOrEqualTo(20));
    expect(m['commentCount'], 0);
  });
});
}
