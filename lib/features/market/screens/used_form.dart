import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../../../core/widgets/surface.dart';
import '../models/used_item.dart';
import '../widgets/used_art.dart';

/// 중고 판매·나눔 글쓰기 (시안 v42 — 판매와 나눔을 한 곳에서)
class UsedForm extends StatefulWidget {
  final String seller;
  final String area;
  final bool share;
  final void Function(UsedItem) onSubmit;
  const UsedForm({super.key, required this.seller, required this.area, this.share = false, required this.onSubmit});

  @override
  State<UsedForm> createState() => _UsedFormState();
}

class _UsedFormState extends State<UsedForm> {
  late bool share = widget.share;
  String art = 'etc';
  final title = TextEditingController();
  final price = TextEditingController();
  final desc = TextEditingController();

  @override
  void dispose() {
    title.dispose();
    price.dispose();
    desc.dispose();
    super.dispose();
  }

  int get _price => int.tryParse(price.text) ?? 0;
  bool get _ok => title.text.trim().length >= 2 && (share || _price > 0);

  void _submit() {
    if (!_ok) return;
    widget.onSubmit(
      UsedItem(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title.text.trim(),
        area: widget.area,
        distM: 0,
        ago: '방금',
        price: share ? 0 : _price,
        art: art,
        desc: desc.text.trim(),
        seller: widget.seller,
        mine: true,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: '중고 판매·나눔',
      sub: '물건을 팔거나 나눠요',
      bottom: BigButton(label: share ? '나눔 올리기' : '판매 올리기', onTap: _ok ? _submit : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegToggle(
            labels: const ['판매', '나눔'],
            index: share ? 1 : 0,
            margin: EdgeInsets.zero,
            onChanged: (i) => setState(() => share = i == 1),
          ),
          const FieldLabel('어떤 물건이에요?'),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: UsedArt.keys.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final on = art == UsedArt.keys[i];
                return GestureDetector(
                  onTap: () => setState(() => art = UsedArt.keys[i]),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: on ? AppColors.ink : Colors.transparent, width: 2),
                        ),
                        child: UsedArt(UsedArt.keys[i], size: 52, radius: 12),
                      ),
                      const SizedBox(height: 3),
                      Text(UsedArt.labels[i], style: TextStyle(fontSize: 11, fontWeight: on ? FontWeight.w800 : FontWeight.w500)),
                    ],
                  ),
                );
              },
            ),
          ),
          const FieldLabel('제목'),
          TextField(
            controller: title,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '예) 원목 의자 상태 좋아요'),
          ),
          if (!share) ...[
            const FieldLabel('가격'),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: '예) 45000', suffixText: '원'),
            ),
          ],
          const FieldLabel('설명', hint: '선택'),
          TextField(
            controller: desc,
            maxLines: 4,
            decoration: const InputDecoration(hintText: '상태, 사용 기간, 거래 장소를 적어 주세요'),
          ),
          const SizedBox(height: 12),
          const Text(
            '다른 동네 물건은 이웃에게 전달을 부탁할 수 있어요. 전달 부탁은 돈벌기 목록에 "중고" 카드로 올라가요.',
            style: TextStyle(fontSize: 12, color: AppColors.sub, height: 1.5),
          ),
        ],
      ),
    );
  }
}
