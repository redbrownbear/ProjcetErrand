import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/features/chat/models/chat_message.dart';
import 'package:gyeomsa/features/errand/models/application.dart';
import 'package:gyeomsa/features/profile/models/app_notice.dart';
import 'package:gyeomsa/features/errand/models/new_request_data.dart';
import 'package:gyeomsa/features/errand/repositories/request_repository.dart';

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
    final photo = ChatMessage.fromDoc('m3', {'senderUid': 'h', 'text': '', 'photoPath': 'trades/t/h/chat_1.jpg'})!;
    expect(photo.photoPath, 'trades/t/h/chat_1.jpg');
    expect(photo.text, isEmpty);
    expect(m.photoPath, isNull);
  });

  test('알림: readAt이 있으면 읽음', () {
    final unread = AppNotice.fromDoc('n1', {'title': '새 지원이 왔어요', 'body': 'b', 'readAt': null})!;
    final read = AppNotice.fromDoc('n2', {'title': 't', 'readAt': Timestamp.now()})!;
    expect(unread.read, isFalse);
    expect(read.read, isTrue);
    expect(AppNotice.fromDoc('n3', {'body': '제목 없음'}), isNull);
  });

group('글쓰기 = 목록 (같은 함수로 만든다)', () {
  NewRequestData data({String mode = 'ask', String? extra, String? cc}) => NewRequestData(
    mode: mode,
    cat: 'buy',
    title: '내일 오사카 가요',
    desc: '돈키호테 들러요',
    place: mode == 'going' && cc == null ? '코스트코 양재점' : '역삼동 GS25',
    cc: cc,
    city: cc == null ? null : '오사카',
    country: cc == null ? null : '일본 오사카',
    mins: 30,
    price: 3000,
    hot: false,
    deadline: DateTime(2026, 10, 21, 18),
    deliveryPlace: '반포동',
    budget: 0,
    payment: 'none',
    completion: '만나서 전달',
    extra: extra,
  );

  test('동네 부탁: 목록엔 동네 이름, 정확한 장소는 공개 문서에 없다', () {
    final it = data().toItem(id: 1, scope: '서초구', who: '민지', ownerUid: 'a');
    expect(it.region, '서초구');
    expect(it.rating, 0, reason: '새 글에 별점을 붙이지 않는다');
    expect(it.verified, isFalse);
    final pub = RequestRepository.toMap(it);
    expect(pub.containsKey('place'), isFalse);
    expect(pub['price'], 3000);
    expect(pub['deadline'], isNotNull);
    // 서버에서 다시 읽으면 같은 값
    final back = RequestRepository.fromDoc('1', {...pub, 'deadline': pub['deadline']})!;
    expect(back.price, it.price);
    expect(back.title, it.title);
    expect(back.deadline, it.deadline);
  });

  test('가는 김에 · 제가 가요: 가는 곳이 공개 지역, 소요시간 없음, 결제 방식 없음', () {
    final it = data(mode: 'going').toItem(id: 2, scope: '서초구', who: '민지');
    expect(it.isGoing, isTrue);
    expect(it.isTrip, isTrue);
    expect(it.region, '코스트코 양재점');
    expect(it.mins, 0);
    expect(it.payment, isNull);
    final abroad = data(mode: 'going', cc: 'jp').toItem(id: 3, scope: '서초구', who: '민지');
    expect(abroad.region, isNull);
    expect(abroad.country, '일본 오사카');
  });

  test('가는 분 찾아요는 일반 부탁 + trip, 서버에도 갈래가 남는다', () {
    final it = data(extra: 'trip').toItem(id: 4, scope: '서초구', who: '준호', ownerUid: 'b');
    expect(it.isTrip, isTrue);
    expect(it.isGoing, isFalse);
    final pub = RequestRepository.toMap(it);
    expect(pub['extra'], 'trip');
    expect(RequestRepository.fromDoc('4', pub)!.extra, 'trip');
  });

  test('가는 김에 신청·거래: 모드와 부탁 내용을 읽는다', () {
    final a = Application.fromDoc('1', 'h', {'status': 'pending', 'requestMode': 'going', 'msg': '곤약젤리'})!;
    expect(a.isGoing, isTrue);
    final t = ServerTrade.fromDoc('t', {
      'status': 'matched',
      'requestId': '1',
      'mode': 'going',
      'requesterUid': 'h',
      'helperUid': 'owner',
      'applicantUid': 'h',
      'applicantName': '준호',
      'ask': '곤약젤리',
    })!;
    expect(t.isGoing, isTrue);
    expect(t.applicantName, '준호');
    expect(t.ask, '곤약젤리');
  });
});
}
