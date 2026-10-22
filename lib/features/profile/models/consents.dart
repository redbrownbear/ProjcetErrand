/// 약관 · 개인정보 · 위치 · 혜택 알림 동의 (개발 To-do A21).
///
/// 필수 세 가지(이용약관 · 개인정보 수집·이용 · 만 14세 이상)는 가입할 때 받고, 철회는 탈퇴로만 한다.
/// 선택 항목은 **기본 꺼짐**이고 마이 › 동의 · 권한 관리에서 언제든 끄고 켠다.
///
/// 계정에 저장할 때는 `users/{uid}.consents`에 현재 값을, `users/{uid}/consentLog`에 바꾼 기록을 남긴다
/// ([UserRepository.saveConsents]). 시각은 서버 시각이다.
class ConsentItem {
  final String key;
  final String title;
  final String summary;
  final bool required;
  const ConsentItem(this.key, this.title, this.summary, {this.required = false});
}

class Consent {
  final bool on;
  final DateTime? at;

  /// 동의할 때 보여 준 문구 버전([Consents.version])
  final String? version;
  const Consent(this.on, {this.at, this.version});

  Map<String, Object?> toJson() => {'on': on, 'at': at?.toIso8601String(), 'v': version};

  static Consent? fromJson(Object? raw) {
    if (raw is! Map || raw['on'] is! bool) return null;
    final at = raw['at'];
    return Consent(
      raw['on'] as bool,
      at: at is DateTime ? at : (at is String ? DateTime.tryParse(at) : null),
      version: raw['v'] is String ? raw['v'] as String : null,
    );
  }
}

class Consents {
  /// 약관 · 동의 문구 버전. 문구가 바뀌면 올리고, 필수 항목은 다시 받는다([requiredDone]).
  static const version = '2026-10-22';

  static const terms = 'terms';
  static const privacy = 'privacy';
  static const age14 = 'age14';
  static const location = 'location';
  static const marketing = 'marketing';
  static const night = 'night';

  static const items = [
    ConsentItem(terms, '서비스 이용약관', '부탁 올리기 · 지원 · 거래와 신고 · 이용 제한 규칙', required: true),
    ConsentItem(privacy, '개인정보 수집 · 이용', '이메일 · 닉네임 · 활동 기록. 탈퇴하면 지워요', required: true),
    ConsentItem(age14, '만 14세 이상이에요', '만 14세 미만은 가입할 수 없어요', required: true),
    ConsentItem(location, '위치 정보 이용', '내 위치로 지도 열기 · 체크인 미션. 끄면 동네를 직접 골라 써요'),
    ConsentItem(marketing, '혜택 · 이벤트 알림 받기', '거래 알림(지원 · 수락 · 채팅)과는 별개예요'),
    ConsentItem(night, '밤 9시 ~ 아침 8시에도 혜택 알림 받기', '혜택 · 이벤트 알림을 켰을 때만 고를 수 있어요'),
  ];

  static ConsentItem item(String key) => items.firstWhere((i) => i.key == key);

  final Map<String, Consent> map;
  const Consents([this.map = const {}]);

  bool isOn(String key) => map[key]?.on ?? false;
  Consent? operator [](String key) => map[key];
  bool get isEmpty => map.isEmpty;

  /// 필수 항목을 지금 버전으로 모두 받았는가
  bool get requiredDone => items.where((i) => i.required).every((i) => isOn(i.key) && map[i.key]?.version == version);

  /// 예전 버전의 필수 동의는 있다(약관이 바뀌어 다시 받아야 하는 경우)
  bool get hadOldRequired => !requiredDone && items.where((i) => i.required).any((i) => isOn(i.key));

  /// [changes]를 적용한 새 값. 값이 그대로인 항목은 시각도 그대로 둔다.
  /// 혜택 알림을 끄면 야간 수신도 같이 꺼지고, 혜택 알림이 꺼져 있으면 야간 수신은 켤 수 없다.
  Consents apply(Map<String, bool> changes, DateTime now) {
    final want = {for (final i in items) i.key: changes[i.key] ?? isOn(i.key)};
    if (!want[marketing]!) want[night] = false;
    final next = Map<String, Consent>.of(map);
    for (final e in want.entries) {
      final cur = map[e.key];
      final asked = changes.containsKey(e.key);
      final record = cur == null
          ? asked // 한 번도 고르지 않은 항목은 기록하지 않는다(기본 꺼짐)
          : cur.on != e.value || (asked && item(e.key).required && cur.version != version); // 새 버전 필수 동의는 다시 기록
      if (record) next[e.key] = Consent(e.value, at: now, version: version);
    }
    return Consents(next);
  }

  /// [before]와 비교해 새로 기록된 항목
  List<String> changedFrom(Consents before) => [
    for (final i in items)
      if (map[i.key] != null && !identical(map[i.key], before.map[i.key])) i.key,
  ];

  /// 필수 항목만 지운 값. 다른 계정으로 바뀔 때 앞사람의 동의가 넘어가지 않게 한다.
  /// 위치 동의는 이 기기의 설정이라 남긴다.
  Consents forDevice() => Consents({if (map[location] != null) location: map[location]!});

  Map<String, Object?> toJson() => {for (final e in map.entries) e.key: e.value.toJson()};

  factory Consents.fromJson(Object? raw) {
    if (raw is! Map) return const Consents();
    final out = <String, Consent>{};
    for (final i in items) {
      final c = Consent.fromJson(raw[i.key]);
      if (c != null) out[i.key] = c;
    }
    return Consents(out);
  }
}
