import '../../errand/models/task_item.dart';

/// '가는 김에' 체험용 예시 일정 (시안 v78 '어! 나도!'). 실제 일정이 적을 때 화면을 채운다.
/// 목록·지도·상세에 '예시'로 표시되고 부탁을 보낼 수 없다.
///
/// 실제 일정과 같은 [TaskItem](mode `going`)으로 만든다. 시각은 지금을 기준으로 잡는다.
List<TaskItem> tripSeeds([DateTime? now]) {
  final t = now ?? DateTime.now();
  // 30분 단위로 올린 기준 시각
  final base = DateTime(t.year, t.month, t.day, t.hour, t.minute < 30 ? 30 : 0).add(Duration(hours: t.minute < 30 ? 0 : 1));
  final tomorrow10 = DateTime(t.year, t.month, t.day + 1, 10);
  TaskItem seed(
    int id, {
    required String who,
    required String area,
    required String place,
    required DateTime goAt,
    required String note,
    required List<String> kinds,
    required int capacity,
    required int accepted,
    required double lat,
    required double lng,
  }) => TaskItem(
    id: id,
    mode: 'going',
    cat: 'buy',
    title: place,
    desc: note,
    region: place,
    place: place,
    lat: lat,
    lng: lng,
    distM: null,
    price: 0,
    who: who,
    ago: area,
    goAt: goAt,
    deadline: goAt.add(const Duration(hours: 1)),
    kinds: kinds,
    capacity: capacity,
    acceptedCount: accepted,
  );

  return [
    seed(
      8005,
      who: '민지',
      area: '반포동',
      place: '동네 치킨집',
      goAt: base,
      note: '치킨 포장해서 가요. 한 마리 더 어때요?',
      kinds: ['사다주기'],
      capacity: 2,
      accepted: 0,
      lat: 37.5045,
      lng: 127.0060,
    ),
    seed(
      8002,
      who: '도윤',
      area: '서초동',
      place: '서초역 올리브영',
      goAt: base.add(const Duration(minutes: 30)),
      note: '퇴근길에 들러요. 가벼운 것만요!',
      kinds: ['사다주기', '물건 전달'],
      capacity: 2,
      accepted: 0,
      lat: 37.4918,
      lng: 127.0076,
    ),
    seed(
      8001,
      who: '수아',
      area: '반포동',
      place: '죽전역 이마트',
      goAt: base.add(const Duration(hours: 2)),
      note: '간 김에 뭐 사다드릴까요?',
      kinds: ['사다주기'],
      capacity: 3,
      accepted: 1,
      lat: 37.3247,
      lng: 127.1076,
    ),
    seed(
      8003,
      who: '하늘',
      area: '방배동',
      place: '강남역 다이소',
      goAt: base.add(const Duration(hours: 4)),
      note: '',
      kinds: ['사다주기', '사진·재고 확인'],
      capacity: 4,
      accepted: 2,
      lat: 37.4979,
      lng: 127.0276,
    ),
    seed(
      8004,
      who: '준호',
      area: '반포동',
      place: '판교 현대백화점 식품관',
      goAt: tomorrow10,
      note: '점심 전에 도착해요.',
      kinds: ['사다주기', '줄서기·예약'],
      capacity: 3,
      accepted: 3,
      lat: 37.3925,
      lng: 127.1120,
    ),
  ];
}
