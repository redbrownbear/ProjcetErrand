/// 위치 정보 이용 동의(선택, 기본 꺼짐)를 지도 · 미션 같은 하위 화면에서 확인하는 창구.
///
/// 동의 값은 [AppSession.consents]가 들고 있고, 셸이 [allowed]를 맞추고 [ask]를 붙인다.
/// 동의하지 않았으면 기기 위치 권한을 묻지도, 위치를 읽지도 않는다.
class LocationConsent {
  LocationConsent._();

  static bool allowed = false;

  /// 동의를 묻는 시트를 띄우고, 동의하면 저장한 뒤 true. 셸이 붙인다
  static Future<bool> Function()? ask;

  /// 이미 동의했으면 바로 true, 아니면 물어본다
  static Future<bool> ensure() async {
    if (allowed) return true;
    final a = ask;
    if (a == null) return false;
    return a();
  }
}
