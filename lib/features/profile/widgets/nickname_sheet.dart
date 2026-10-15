import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';

/// 닉네임을 바꾸는 시트를 띄운다. 저장하면 새 닉네임을, 닫으면 null을 돌려준다.
Future<String?> showNicknameSheet(BuildContext context, String current) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.surface))),
    builder: (_) => _NicknameSheet(current: current),
  );
}

/// 닉네임 입력 시트. 2~12자만 받는다.
class _NicknameSheet extends StatefulWidget {
  final String current;
  const _NicknameSheet({required this.current});
  @override
  State<_NicknameSheet> createState() => _NicknameSheetState();
}

class _NicknameSheetState extends State<_NicknameSheet> {
  late final TextEditingController ctrl = TextEditingController(text: widget.current);
  String? error;

  static const _min = 2;
  static const _max = 12;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final value = ctrl.text.trim();
    if (value.length < _min || value.length > _max) {
      setState(() => error = '$_min~$_max자로 입력해 주세요');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 키보드가 올라와도 입력창이 가리지 않게 한다
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('닉네임', style: AppType.pageTitle.copyWith(fontSize: 16)),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('부탁 목록과 상세에 이 이름으로 보여요', style: AppType.meta),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  maxLength: _max,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (error != null) setState(() => error = null);
                  },
                  onSubmitted: (_) => _save(),
                  decoration: InputDecoration(hintText: '예: 서초동 이웃', errorText: error, counterText: ''),
                  style: AppType.body.copyWith(fontSize: 16, fontWeight: AppType.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(onPressed: _save, child: const Text('저장')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
