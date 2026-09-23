/// 브랜드·판매사가 보내는 협업 제안서. 시안(`gyumsa-refined`)의 `GyPartner`.
///
/// 두 종류가 한 폼을 나눠 쓴다.
/// - [kindBrand] 설문·체험단·광고 같은 기업 미션 제안
/// - [kindGroup] 공동구매 상품 입점 제안과 이용자의 공구 요청
class PartnerProposal {
  static const kindBrand = '기업 미션';
  static const kindGroup = '공동구매';

  static const brandTypes = ['설문조사', '블로그·SNS', '제품·서비스 체험단', '매장 방문', '광고·리워드', '기타 제휴'];
  static const groupTypes = ['상품 입점 제안', '이 상품 공구 요청', '기타 문의'];

  final String id;
  final String kind;
  final String type;
  final String company;
  final String contact;
  final String email;
  final String title;
  final String url;
  final String budget;
  final String period;
  final String details;

  /// 저장한 시각 (yyyy-MM-dd까지만 화면에 쓴다)
  final String at;

  /// 진행 상태. 시안은 저장만 하므로 항상 '제안서 저장'이다.
  final String status;

  const PartnerProposal({
    required this.id,
    required this.kind,
    required this.type,
    required this.company,
    required this.contact,
    required this.email,
    required this.title,
    required this.url,
    required this.budget,
    required this.period,
    required this.details,
    required this.at,
    this.status = '제안서 저장',
  });

  String get day => at.length >= 10 ? at.substring(0, 10) : at;

  Map<String, dynamic> toJson() => {
        'id': id, 'kind': kind, 'type': type, 'company': company, 'contact': contact,
        'email': email, 'title': title, 'url': url, 'budget': budget, 'period': period,
        'details': details, 'at': at, 'status': status,
      };

  factory PartnerProposal.fromJson(Map<String, dynamic> j) => PartnerProposal(
        id: '${j['id'] ?? ''}',
        kind: '${j['kind'] ?? kindBrand}',
        type: '${j['type'] ?? ''}',
        company: '${j['company'] ?? ''}',
        contact: '${j['contact'] ?? ''}',
        email: '${j['email'] ?? ''}',
        title: '${j['title'] ?? ''}',
        url: '${j['url'] ?? ''}',
        budget: '${j['budget'] ?? ''}',
        period: '${j['period'] ?? ''}',
        details: '${j['details'] ?? ''}',
        at: '${j['at'] ?? ''}',
        status: '${j['status'] ?? '제안서 저장'}',
      );
}
