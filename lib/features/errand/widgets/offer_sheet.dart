import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/task_item.dart';

class OfferSheet extends StatefulWidget {
  final TaskItem it;
  final VoidCallback onClose;
  final void Function(int price, String msg) onSend;
  const OfferSheet({super.key, required this.it, required this.onClose, required this.onSend});
  @override
  State<OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<OfferSheet> {
  late int price;
  final msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    price = widget.it.price + 1000;
  }

  @override
  void dispose() {
    msgCtrl.dispose();
    super.dispose();
  }

  void step(int d) => setState(() => price = (price + d).clamp(0, 1 << 30));

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: const Color(0x73141420),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
              decoration: const BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
                  const Text('가격을 제안해볼까요?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 12.5, color: AppColors.sub),
                      children: [
                        const TextSpan(text: '요청자가 올린 금액은 '),
                        TextSpan(text: won(widget.it.price), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                        const TextSpan(text: ' 예요'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(10)),
                    child: const Text('🔒 이 제안은 요청자에게만 비공개로 전달돼요. 다른 사람에게는 안 보여요.', style: TextStyle(fontSize: 11.5, color: AppColors.blue, height: 1.5)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _round('−', () => step(-1000)),
                      SizedBox(width: 140, child: Text(won(price), textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.ink))),
                      _round('＋', () => step(1000)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final d in [-2000, 1000, 2000, 5000])
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => step(d),
                            borderRadius: BorderRadius.circular(99),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99), border: Border.all(color: AppColors.line)),
                              child: Text('${d > 0 ? '+' : ''}${d ~/ 1000}천', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: msgCtrl,
                    decoration: InputDecoration(
                      hintText: '한마디 (예: 지금 바로 갈 수 있어요)',
                      filled: true, fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => widget.onSend(price, msgCtrl.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text('${won(price)}에 제안 보내기', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _round(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 46, height: 46, alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.line, width: 1.5)),
        child: Text(label, style: const TextStyle(fontSize: 22, color: AppColors.ink)),
      ),
    );
  }
}
