/// 오늘의 퀴즈 한 문제.
class QuizItem {
  final String q;
  final List<String> choices;

  /// 정답 인덱스
  final int answer;

  /// 맞히든 틀리든 보여 주는 한 줄. 앱 사용법을 여기서 알려 준다.
  final String tip;
  const QuizItem(this.q, this.choices, this.answer, this.tip);
}

/// 제휴가 필요 없는 자체 콘텐츠. 앱 사용법과 안전 수칙을 문제로 만들어,
/// 적립하는 사이에 사고를 줄이는 정보가 남게 한다.
const quizItems = <QuizItem>[
  QuizItem('겸사겸사에서 심부름 값을 주고받는 안전한 방법은?',
      ['계좌로 먼저 송금', '겸사페이로 결제 후 완료 시 정산', '현장에서 현금'], 1,
      '겸사페이는 완료 확인 전까지 돈을 잡아 둬요. 앱 밖 송금은 보호받지 못해요.'),
  QuizItem('부탁을 올릴 때 사진을 넣으면 좋은 이유는?',
      ['포인트를 더 받아서', '수행자가 물건을 정확히 찾을 수 있어서', '광고가 붙어서'], 1,
      '물건 사진 한 장이 오배송과 재문의를 가장 많이 줄여요.'),
  QuizItem('모르는 사람과 물건을 주고받을 때 권장되는 장소는?',
      ['상대방 집 앞', '사람이 많은 공공장소', '한적한 골목'], 1,
      '지하철역·편의점 앞처럼 CCTV가 있고 사람이 많은 곳에서 만나세요.'),
  QuizItem('포인트(P)와 겸사페이(원)의 차이는?',
      ['같은 것이다', '포인트는 리워드, 겸사페이는 실제 거래 대금', '포인트가 더 비싸다'], 1,
      '둘은 지갑이 달라요. 포인트는 상품 교환에, 겸사페이는 거래 정산에 써요.'),
  QuizItem('해외 부탁(구매대행)에서 가장 먼저 확인할 것은?',
      ['배송비와 관세 부담 주체', '판매자 얼굴', '환율 그래프'], 0,
      '관세·배송비를 누가 내는지 먼저 적어 두면 분쟁이 거의 생기지 않아요.'),
  QuizItem('단기알바 공고에서 겸사겸사의 역할은?',
      ['직접 고용한다', '구인 정보를 게시하고 연결한다', '임금을 대신 준다'], 1,
      '근로계약과 임금 지급은 구인업체와 직접 이뤄져요.'),
  QuizItem('제휴 미션에 "광고·제휴" 표시가 붙는 이유는?',
      ['디자인 때문에', '제휴사가 비용을 부담하는 광고라서', '포인트가 커서'], 1,
      '대가를 받은 콘텐츠는 반드시 표시해야 해요. 표시 없는 추천은 신고해 주세요.'),
];

/// 날짜로 문제를 고른다. 같은 날이면 기기가 달라도 같은 문제가 나온다.
QuizItem quizOfDay([DateTime? now]) {
  final kst = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 9));
  final day = DateTime.utc(kst.year, kst.month, kst.day).difference(DateTime.utc(2024, 1, 1)).inDays;
  return quizItems[day.abs() % quizItems.length];
}
