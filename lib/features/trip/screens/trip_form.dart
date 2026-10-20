import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../../../core/widgets/surface.dart';
import '../../errand/data/countries.dart';
import '../models/trip_post.dart';

/// 가는 김에 글쓰기 — 어디 가는 길인지, 같이 할 일을 올린다.
class TripForm extends StatefulWidget {
  final String author;
  final String area;
  final void Function(TripPost) onSubmit;
  const TripForm({super.key, required this.author, required this.area, required this.onSubmit});

  @override
  State<TripForm> createState() => _TripFormState();
}

class _TripFormState extends State<TripForm> {
  String type = 'going';
  bool abroad = false;
  String cc = 'jp';
  final where = TextEditingController();
  final when = TextEditingController();
  final quote = TextEditingController();
  final title = TextEditingController();

  /// 제목을 직접 고쳤으면 더 이상 '어디로'를 따라 바꾸지 않는다
  bool titleEdited = false;

  @override
  void dispose() {
    title.dispose();
    where.dispose();
    when.dispose();
    quote.dispose();
    super.dispose();
  }

  bool get _ok => where.text.trim().isNotEmpty && title.text.trim().isNotEmpty && quote.text.trim().isNotEmpty;

  /// '어디로'·종류가 바뀌면 제목 제안을 다시 채운다(직접 고친 뒤엔 그대로 둔다)
  void _suggest() {
    if (titleEdited) return;
    title.text = TripPost.suggestTitle(type, where.text);
  }

  void _submit() {
    if (!_ok) return;
    widget.onSubmit(
      TripPost(
        id: DateTime.now().millisecondsSinceEpoch,
        type: type,
        author: widget.author,
        area: widget.area,
        cc: abroad ? cc : null,
        where: where.text.trim(),
        title: title.text.trim(),
        when: when.text.trim().isEmpty ? (type == 'going' ? '곧 출발' : '언제든') : when.text.trim(),
        quote: quote.text.trim(),
        mine: true,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: '가는 김에 글쓰기',
      sub: '어디 가는 길인지, 같이 할 일을 올려요',
      bottom: BigButton(label: '올리기', onTap: _ok ? _submit : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegToggle(
            labels: const ['제가 가요', '가는 분 찾아요'],
            index: type == 'going' ? 0 : 1,
            margin: EdgeInsets.zero,
            onChanged: (i) => setState(() {
              type = i == 0 ? 'going' : 'asking';
              _suggest();
            }),
          ),
          const FieldLabel('어디로?'),
          Row(
            children: [
              _toggle('국내', !abroad, () => setState(() => abroad = false)),
              const SizedBox(width: 6),
              _toggle('해외', abroad, () => setState(() => abroad = true)),
            ],
          ),
          const SizedBox(height: 8),
          if (abroad)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DropdownButtonFormField<String>(
                initialValue: cc,
                isExpanded: true,
                items: [for (final c in countries) DropdownMenuItem(value: c.cc, child: Text(c.name))],
                onChanged: (v) => setState(() => cc = v ?? cc),
              ),
            ),
          TextField(
            controller: where,
            maxLength: 40,
            onChanged: (_) => setState(_suggest),
            decoration: InputDecoration(
              hintText: abroad ? '예) 오사카' : '예) 성수동 · 코스트코 양재점',
              helperText: '장소 이름만 적어 주세요. 제목은 아래에서 고칠 수 있어요',
              counterText: '',
            ),
          ),
          const FieldLabel('제목'),
          TextField(
            controller: title,
            maxLength: 60,
            onChanged: (v) => setState(() => titleEdited = v.trim().isNotEmpty),
            decoration: InputDecoration(
              hintText: type == 'going' ? '예) 내일 오사카 가요' : '예) 오늘 성수 가시는 분 있나요?',
              counterText: '',
            ),
          ),
          const FieldLabel('언제?', hint: '선택'),
          TextField(
            controller: when,
            maxLength: 40,
            decoration: const InputDecoration(hintText: '예) 내일 오후 · 10.02 출국 3박', counterText: ''),
          ),
          const FieldLabel('한마디'),
          TextField(
            controller: quote,
            onChanged: (_) => setState(() {}),
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: type == 'going' ? '예) 돈키호테 들를 예정인데 필요한 거 있으면 부탁 주세요.' : '예) 팝업 굿즈 하나만 부탁드리고 싶어요.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String label, bool on, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? AppColors.ink : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: on ? AppColors.ink : AppColors.outline),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: on ? Colors.white : AppColors.ink2),
      ),
    ),
  );
}
