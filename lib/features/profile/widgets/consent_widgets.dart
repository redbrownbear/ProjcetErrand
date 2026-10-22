import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../models/consents.dart';

/// 가입 화면 · 동의 화면에서 쓰는 동의 목록. 맨 위 '전체 동의'와 항목별 체크.
/// 선택 항목은 기본 꺼짐이고, 야간 혜택 알림은 혜택 알림을 켰을 때만 고를 수 있다.
class ConsentChecklist extends StatelessWidget {
  final Map<String, bool> values;
  final ValueChanged<Map<String, bool>> onChanged;
  const ConsentChecklist({super.key, required this.values, required this.onChanged});

  bool _on(String k) => values[k] ?? false;

  void _set(String key, bool on) {
    final next = Map<String, bool>.of(values)..[key] = on;
    if (key == Consents.marketing && !on) next[Consents.night] = false;
    if (key == Consents.night && on) next[Consents.marketing] = true;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final all = Consents.items.every((i) => _on(i.key));
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CheckRow(
            checked: all,
            title: '전체 동의',
            sub: '선택 항목(위치 · 혜택 알림)까지 모두 동의해요',
            bold: true,
            onTap: () => onChanged({for (final i in Consents.items) i.key: !all}),
          ),
          const Divider(height: 1, color: AppColors.line),
          for (final i in Consents.items)
            _CheckRow(
              checked: _on(i.key),
              title: i.title,
              tag: i.required ? '필수' : '선택',
              sub: i.summary,
              onTap: () => _set(i.key, !_on(i.key)),
              onView: i.required ? () => showConsentDetail(context, i) : null,
            ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final bool checked;
  final String title;
  final String? tag;
  final String sub;
  final bool bold;
  final VoidCallback onTap;
  final VoidCallback? onView;
  const _CheckRow({
    required this.checked,
    required this.title,
    this.tag,
    required this.sub,
    this.bold = false,
    required this.onTap,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      button: true,
      label: [?tag, title].join(' '),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: checked ? AppColors.green : AppColors.faint,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            if (tag != null)
                              TextSpan(
                                text: '[$tag] ',
                                style: TextStyle(color: tag == '필수' ? AppColors.red : AppColors.sub),
                              ),
                            TextSpan(text: title),
                          ],
                        ),
                        style: AppType.body.copyWith(fontSize: 14.5, fontWeight: bold ? AppType.w700 : AppType.w600),
                      ),
                      if (sub.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(sub, style: AppType.meta.copyWith(height: 1.45)),
                        ),
                    ],
                  ),
                ),
              ),
              if (onView != null)
                TextButton(
                  onPressed: onView,
                  style: TextButton.styleFrom(foregroundColor: AppColors.sub, minimumSize: const Size(44, 36)),
                  child: const Text('보기', style: TextStyle(fontSize: 13, decoration: TextDecoration.underline)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 필수 동의의 내용. 약관 전문은 출시 전에 법률 검토를 거쳐 게시한다(개발 To-do R04 · C13).
Future<void> showConsentDetail(BuildContext context, ConsentItem item) => showSheet<void>(
  context,
  (ctx) => SheetFrame(
    title: item.title,
    sub: '약관 전문은 출시 전에 이 자리와 웹 페이지에 올라가요. 지금은 요약만 보여 드려요.',
    bottom: BigButton(label: '닫기', onTap: () => Navigator.pop(ctx)),
    child: Text(item.summary, style: AppType.body.copyWith(height: 1.6)),
  ),
);

/// 위치 기능을 처음 쓸 때 묻는 시트. 동의하면 true. 기기 위치 권한은 그다음에 운영체제가 따로 묻는다.
Future<bool> showLocationConsentSheet(BuildContext context) async {
  final ok = await showSheet<bool>(
    context,
    (ctx) => SheetFrame(
      title: '위치 정보를 써도 될까요?',
      sub: '내 위치로 지도를 열고, 체크인 미션에서 가게 근처인지 확인할 때만 써요.',
      bottom: Row(
        children: [
          Expanded(
            child: BigButton(label: '안 할래요', bg: AppColors.page, onTap: () => Navigator.pop(ctx, false)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: BigButton(label: '동의하고 쓰기', onTap: () => Navigator.pop(ctx, true)),
          ),
        ],
      ),
      child: Text(
        '· 선택 동의예요. 동의하지 않아도 동네를 직접 골라 쓸 수 있어요.\n'
        '· 위치는 화면에 쓰고 말아요. 부탁 글에는 동네 이름만 올라가요.\n'
        '· 마이 › 동의 · 권한 관리에서 언제든 끌 수 있어요.',
        style: AppType.meta.copyWith(height: 1.7, color: AppColors.ink2),
      ),
    ),
  );
  return ok ?? false;
}
