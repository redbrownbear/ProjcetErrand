import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';

class DetailPage extends StatelessWidget {
  final TaskItem item;
  final String? status;
  final VoidCallback onClose;
  final void Function(TaskItem) onApply;
  const DetailPage({super.key, required this.item, required this.status, required this.onClose, required this.onApply});
  @override
  Widget build(BuildContext context) {
    final paid = item.mode == 'ask';
    final free = item.mode == 'together';
    final share = item.mode == 'share';
    final c = catOf(item.cat);
    return Positioned.fill(
      child: Material(
        color: AppColors.page,
        child: Column(children: [
          Container(
            height: 150,
            width: double.infinity,
            alignment: Alignment.center,
            color: free ? AppColors.gray : share ? AppColors.greenSoft : AppColors.yellowSoft,
            child: Stack(children: [
              Center(child: Text(c?.icon ?? '🙌', style: const TextStyle(fontSize: 56))),
              Positioned(
                top: 16, left: 16,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    width: 36, height: 36, alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), shape: BoxShape.circle),
                    child: const Text('‹', style: TextStyle(fontSize: 17)),
                  ),
                ),
              ),
              if (item.hot)
                Positioned(
                  top: 18, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.hot, borderRadius: BorderRadius.circular(8)),
                    child: const Text('🔥 급한 일 · 최상단 노출', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: share ? AppColors.greenSoft : paid ? AppColors.yellowSoft : AppColors.blueSoft, borderRadius: BorderRadius.circular(8)),
                    child: Text(share ? '나눔' : paid ? (catOf(item.cat)?.label ?? '') : '같이해요', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: share ? AppColors.green : paid ? AppColors.ink : AppColors.blue)),
                  ),
                  Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.35)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line), bottom: BorderSide(color: AppColors.line))),
                    child: Row(children: [
                      Container(width: 42, height: 42, alignment: Alignment.center, decoration: const BoxDecoration(color: AppColors.greenSoft, shape: BoxShape.circle), child: const Text('🌱', style: TextStyle(fontSize: 20))),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.who, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                            Text('${item.gender} · ${item.age}대 인증 · 품온도 ${item.temp}℃', style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                          ],
                        ),
                      ),
                      const Text('🛡 본인인증', style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10, crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    children: [
                      _Info(label: '거리', v: km(item.dist)),
                      _Info(label: paid ? '예상 소요' : '형태', v: paid ? '약 ${item.mins}분' : (free ? '동행' : '직접 수령')),
                      _Info(label: '위치', v: item.place),
                      _Info(label: share ? '' : '사례비', v: share ? '무료 나눔' : paid ? won(item.price) : '사례 없음'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('상세 내용', style: TextStyle(fontSize: 13, color: AppColors.sub, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(item.desc, style: const TextStyle(fontSize: 14, color: AppColors.ink, height: 1.7)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🛡 안전 안내', style: TextStyle(fontSize: 11.5, color: AppColors.sub, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 7),
                        Text(
                          '· 공개된 장소에서 만나요\n· 매칭 후 실시간 위치가 공유돼요\n· 언제든 신고·차단할 수 있어요${!paid ? '\n· 본인인증한 이웃만 신청돼요' : ''}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.ink, height: 1.65),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
            child: Column(children: [
              if (status == 'pending')
                Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(14)),
                  child: const Text('매칭 중… 상대의 수락을 기다려요', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFB8860B), fontWeight: FontWeight.w800, fontSize: 15)),
                )
              else if (status == 'matched')
                Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(14)),
                  child: const Text('매칭 완료! 채팅에서 이어가요 ✓', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF1B8A5A), fontWeight: FontWeight.w800, fontSize: 15)),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onApply(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(share ? '이거 받고 싶어요' : paid ? '신청하기' : '같이 신청하기', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              const SizedBox(height: 8),
              const Text('신청하면 상대가 수락해야 매칭돼요', style: TextStyle(fontSize: 11, color: AppColors.sub)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label, v;
  const _Info({required this.label, required this.v});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.sub)),
          const SizedBox(height: 3),
          Text(v, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
        ],
      ),
    );
  }
}
