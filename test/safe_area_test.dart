import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/core/widgets/screen_frame.dart';
import 'package:gyeomsa/features/benefits/data/partner_missions.dart';
import 'package:gyeomsa/features/benefits/screens/partner_mission_detail_screen.dart';

/// 노치와 제스처바가 있는 기기를 흉내 낸다.
///
/// targetSdk 36에서 안드로이드 15+는 화면을 가장자리까지 쓰게 강제한다.
/// 그러면 아무것도 안 해도 헤더가 상태바 밑으로, 하단 버튼이 제스처바 밑으로
/// 들어간다. 이 값이 실제로 화면을 밀어내는지를 좌표로 확인한다.
const _topInset = 48.0;
const _bottomInset = 24.0;

Widget _device(Widget child) => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(375, 812),
          padding: EdgeInsets.only(top: _topInset, bottom: _bottomInset),
          viewPadding: EdgeInsets.only(top: _topInset, bottom: _bottomInset),
        ),
        child: child,
      ),
    );

void main() {
  setUp(() {
    // 기기 크기를 고정해야 좌표 비교가 의미를 갖는다
  });

  group('ScreenFrame — 20개 화면이 공유하는 뼈대', () {
    testWidgets('헤더가 상태바 아래에서 시작한다', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_device(ScreenFrame(
        title: '테스트 화면',
        onBack: () {},
        child: const SizedBox.expand(),
      )));
      await tester.pump();

      final titleTop = tester.getTopLeft(find.text('테스트 화면')).dy;
      expect(titleTop, greaterThanOrEqualTo(_topInset),
          reason: '제목이 상태바($_topInset)에 가린다');
    });

    testWidgets('뒤로가기 버튼도 상태바에 가리지 않는다', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_device(ScreenFrame(
        title: '테스트 화면',
        onBack: () {},
        child: const SizedBox.expand(),
      )));
      await tester.pump();

      // 44x44 터치 영역 전체가 상태바 아래에 있어야 실제로 누를 수 있다
      final back = tester.getRect(find.byType(IconBtn));
      expect(back.top, greaterThanOrEqualTo(_topInset), reason: '뒤로가기가 상태바에 깔린다');
    });

    testWidgets('본문 맨 아래가 제스처바 위에서 끝난다', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_device(ScreenFrame(
        title: '테스트 화면',
        onBack: () {},
        child: Stack(children: [
          // 상세 화면들이 참여 버튼을 이렇게 깐다
          Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 60, color: Colors.red, key: const Key('cta'))),
        ]),
      )));
      await tester.pump();

      final cta = tester.getRect(find.byKey(const Key('cta')));
      expect(cta.bottom, lessThanOrEqualTo(812 - _bottomInset),
          reason: '하단 고정 버튼이 제스처바($_bottomInset)에 깔려 눌리지 않는다');
    });
  });

  group('실제 화면', () {
    testWidgets('제휴 미션 상세의 참여 버튼이 제스처바 위에 있다', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_device(PartnerMissionDetailScreen(
        m: partnerMissions.first,
        done: false,
        onComplete: (_) {},
      )));
      await tester.pump();

      final button = tester.getRect(find.byType(ElevatedButton));
      expect(button.bottom, lessThanOrEqualTo(812 - _bottomInset),
          reason: '참여 버튼이 제스처바에 깔린다');

      // 헤더도 같이 확인 — 같은 뼈대를 쓰므로 함께 밀려야 한다
      expect(tester.getTopLeft(find.text('제휴 미션')).dy, greaterThanOrEqualTo(_topInset));
    });
  });
}
