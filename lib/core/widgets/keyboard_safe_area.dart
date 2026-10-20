import 'package:flutter/widgets.dart';

/// [SafeArea] + 화면 키보드만큼 아래를 비운다.
///
/// 이 앱의 전체화면 대부분은 [Scaffold]가 아니라 `Material` 위에 그린다. `Scaffold`는 키보드가 올라오면
/// 본문을 줄여 주지만(`resizeToAvoidBottomInset`), `Material`은 그러지 않아서 입력 칸·아래 고정 버튼이
/// 키보드에 가렸다. 키보드가 올라와 있으면 그 높이만큼 아래를 비우고, 아래 안전 영역(제스처바)은 키보드가
/// 이미 덮고 있으니 겹쳐 더하지 않는다. 줄어든 화면 안에서 입력 중인 칸은 스크롤이 알아서 보이게 올린다.
class KeyboardSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  const KeyboardSafeArea({super.key, required this.child, this.top = true});

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(top: top, bottom: inset == 0, child: child),
    );
  }
}
