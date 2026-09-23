import '../models/home_news.dart';

/// 홈 '겸사겸사 소식' 세 장. 시안(`gyumsa-refined`)의 `g4News`를 그대로 옮겼다.
///
/// 세 번째 장은 광고 지면이다. 시안은 같은 자리를 서비스 소식과 브랜드 광고가
/// 나눠 쓰고, 광고에는 '광고' 표시를 붙인다.
const homeNews = <HomeNews>[
  HomeNews(
    id: 'overseas',
    tag: '업데이트',
    title: '해외 사다주기가\n더 안심되게',
    body: '예비금부터 영수증 정산까지,\n거래 흐름을 한눈에 확인해요.',
    action: '달라진 점 보기',
    icon: 'globe',
    tone: NewsTone.blue,
    lead: '상품을 부탁하는 순간부터 전달받는 순간까지, 필요한 정보를 차근차근 확인할 수 있도록 정리했어요.',
    sections: [
      (title: '등록할 때는 결제하지 않아요', body: '상품 링크·옵션·예산을 남기고 여행자의 최종 제안을 확인해요.'),
      (title: '예비금과 정산 내역이 보여요', body: '고정환율로 계산한 영수증 금액과 차액 부분취소 예정액을 확인할 수 있어요.'),
      (title: '금액 확인과 수령확정을 나눴어요', body: '영수증 확인 뒤에도 실제 상품을 받아 확인하기 전에는 지급이 진행되지 않아요.'),
    ],
  ),
  HomeNews(
    id: 'jobs',
    tag: '새로운 기능',
    title: '하루의 빈 시간을\n새로운 기회로',
    body: '업무·근무시간·급여를 확인하는\n단기알바 모집이 생겼어요.',
    action: '단기알바 알아보기',
    icon: 'clipboard',
    tone: NewsTone.peach,
    lead: '일상 부탁과 채용을 구분하고, 지원 전에 필요한 근무 조건을 한곳에 모았어요.',
    sections: [
      (title: '회사와 업무를 자세하게', body: '회사명·주소, 담당 업무, 필요한 경험과 준비물을 확인해요.'),
      (title: '근무 조건을 한눈에', body: '날짜·시간·휴게시간·모집 인원을 구분해 안내해요.'),
      (title: '급여와 지원 방법까지', body: '시급·일급·총액, 지급 예정일, 담당자와 지원 방법을 함께 확인해요.'),
    ],
  ),
  HomeNews(
    id: 'ad',
    tag: '광고 · 예시',
    title: '좋은 브랜드와\n일상이 만나는 곳',
    body: '체험과 공동구매로 만나는\n브랜드 소식을 소개할 수 있어요.',
    action: '브랜드 협업 안내',
    icon: 'gift',
    tone: NewsTone.mint,
  ),
];
