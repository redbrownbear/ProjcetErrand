import '../../errand/models/task_item.dart';

/// '가는 김에' 체험용 예시 글. 실제 글이 없을 때 화면을 채운다 — 목록·상세에 '예시'로 표시되고 신청할 수 없다.
///
/// 실제 글과 같은 [TaskItem]·같은 줄 모양(TaskCard)으로 보여 준다.
/// - going : 제가 가요(도움 주기) — 보는 사람은 '부탁할게요'
/// - extra trip : 가는 분 찾아요(도움 요청) — 보는 사람은 '도와줄게요'
final tripSeeds = <TaskItem>[
  TaskItem(
    id: 8001,
    mode: 'going',
    cat: 'buy',
    title: '내일 오사카 가요',
    desc: '돈키호테 들를 예정인데 필요한 거 있으면 부탁 주세요. 3박 하고 돌아와요.',
    cc: 'jp',
    city: '오사카',
    country: '일본 오사카',
    place: '돈키호테',
    distM: 9e9,
    price: 3000,
    who: '민지',
    deadline: DateTime.now().add(const Duration(hours: 20)),
    deliveryPlace: '반포동 · 돌아와서 만나서',
    completion: '돌아와서 만나 전달, 영수증 사진 공유',
  ),
  TaskItem(
    id: 8002,
    mode: 'ask',
    extra: 'trip',
    cat: 'buy',
    title: '오늘 성수 가시는 분, 팝업 굿즈 부탁해요',
    desc: '성수동 팝업스토어 굿즈 하나만 부탁드리고 싶어요.',
    region: '서초구',
    distM: null,
    mins: 60,
    price: 8000,
    who: '준호',
    deadline: DateTime.now().add(const Duration(hours: 6)),
    deliveryPlace: '서초역 근처',
    completion: '전달 후 수령 확인',
  ),
  TaskItem(
    id: 8003,
    mode: 'going',
    cat: 'buy',
    title: '토요일에 코스트코 양재점 가요',
    desc: '대용량 나눠 사실 분이나 필요한 거 있으면 말씀 주세요.',
    region: '코스트코 양재점',
    place: '코스트코 양재점',
    distM: null,
    price: 2000,
    who: '수아',
    deadline: DateTime.now().add(const Duration(days: 3)),
    deliveryPlace: '잠원동',
    completion: '돌아오는 길에 만나서 전달',
  ),
];
