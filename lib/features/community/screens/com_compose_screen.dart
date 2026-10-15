import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../../../core/widgets/surface.dart';
import '../../errand/data/countries.dart';
import '../data/com_posts.dart';
import '../models/com_post.dart';

/// 커뮤니티 글쓰기. 글을 올리면 응모권 +1.
///
/// 제안을 받은 뒤 '후기 남기기'로 열리면 [initial]에 제목·지역·종류가 채워져 온다.
class ComComposeScreen extends StatefulWidget {
  final String author;
  final ComPost? initial;
  final String scope;
  final void Function(ComPost) onSubmit;
  const ComComposeScreen({super.key, required this.author, this.initial, this.scope = 'local', required this.onSubmit});

  @override
  State<ComComposeScreen> createState() => _ComComposeScreenState();
}

class _ComComposeScreenState extends State<ComComposeScreen> {
  late String scope = widget.initial?.scope ?? widget.scope;
  late String kind = widget.initial?.kind ?? _kinds.first;
  late String place = widget.initial?.place ?? '';
  late final title = TextEditingController(text: widget.initial?.title ?? '');
  late final body = TextEditingController(text: widget.initial?.body ?? '');

  List<String> get _kinds => switch (scope) {
    'travel' => travelKinds,
    'abroad' => abroadKinds,
    _ => localKinds,
  };

  List<(String, String)> get _places => switch (scope) {
    'travel' => [for (final p in travelPlaces) (p.place, '${p.emoji} ${p.place}')],
    'abroad' => [for (final c in countries) (c.cc, c.name)],
    _ => const [],
  };

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  bool get _ok => title.text.trim().length >= 2 && body.text.trim().isNotEmpty && (scope == 'local' || place.isNotEmpty);

  void _submit() {
    if (!_ok) return;
    widget.onSubmit(
      ComPost(
        id: DateTime.now().millisecondsSinceEpoch,
        scope: scope,
        kind: kind,
        place: place,
        title: title.text.trim(),
        body: body.text.trim(),
        author: widget.author,
        mine: true,
        proposalId: widget.initial?.proposalId,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: widget.initial?.kind == '후기' ? '후기 남기기' : '커뮤니티 글쓰기',
      background: AppColors.card,
      bottom: BigButton(label: '올리기 · 응모권 +1', onTap: _ok ? _submit : null),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          SegToggle(
            labels: const ['우리 동네', '국내 여행', '해외'],
            index: const ['local', 'travel', 'abroad'].indexOf(scope),
            margin: EdgeInsets.zero,
            onChanged: (i) => setState(() {
              scope = const ['local', 'travel', 'abroad'][i];
              if (!_kinds.contains(kind)) kind = _kinds.first;
              place = '';
            }),
          ),
          const FieldLabel('어떤 글인가요?'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final k in _kinds) _chip(k, kind == k, () => setState(() => kind = k))],
          ),
          if (scope != 'local') ...[
            FieldLabel(scope == 'travel' ? '어느 지역이에요?' : '어느 나라예요?'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final p in _places) _chip(p.$2, place == p.$1, () => setState(() => place = p.$1))],
            ),
          ],
          const FieldLabel('제목'),
          TextField(
            controller: title,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '예) 서초역 근처 세탁소 추천해 주세요'),
          ),
          const FieldLabel('내용'),
          TextField(
            controller: body,
            onChanged: (_) => setState(() {}),
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(hintText: '이웃과 나누고 싶은 이야기를 적어 주세요'),
          ),
          const SizedBox(height: 12),
          const Text('개인 연락처는 적지 말아 주세요. 대화는 앱 안 채팅으로 이어져요.', style: TextStyle(fontSize: 12, color: AppColors.sub)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: on ? AppColors.ink : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: on ? AppColors.ink : AppColors.outline),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: on ? Colors.white : AppColors.ink2),
      ),
    ),
  );
}
