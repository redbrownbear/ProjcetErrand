import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/tag.dart';
import '../data/categories.dart';
import '../models/offer.dart';
import '../models/task_item.dart';
import '../widgets/offer_sheet.dart';
import '../widgets/request_facts.dart';

class DetailPage extends StatefulWidget {
  final TaskItem it;
  final List<int> grabbed;
  final List<Offer> myOffers;
  final void Function(TaskItem) onGrab;
  final void Function(TaskItem, int, String) onOffer;
  final bool Function(int id) isSaved;
  final void Function(int id) toggleSave;
  const DetailPage({
    super.key, required this.it, required this.grabbed, required this.myOffers,
    required this.onGrab, required this.onOffer, required this.isSaved, required this.toggleSave,
  });
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool offerOpen = false;

  @override
  Widget build(BuildContext context) {
    final it = widget.it;
    final sea = it.mode == 'sea';
    final paid = it.mode == 'ask' || sea;
    final done = widget.grabbed.contains(it.id);
    // 자기 부탁·마감된 부탁에는 지원할 수 없다
    final blocked = it.isMine ? '내가 올린 부탁' : it.isExpired ? '마감된 부탁' : null;

    return Material(
      color: AppColors.page,
      child: Stack(children: [
        // 본문만 안전 영역 안에 둔다. 가격 제안 시트는 화면 전체를 덮는 딤이라
        // 여기 같이 넣으면 상태바 자리만 덮이지 않아 어색해진다 ([OfferSheet] 참고).
        SafeArea(
          child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            height: 52,
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(color: AppColors.card, border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Row(children: [
              InkWell(onTap: () => Navigator.of(context).pop(), borderRadius: BorderRadius.circular(99), child: const Padding(padding: EdgeInsets.only(right: 2), child: Text('‹', style: TextStyle(fontSize: 24, color: AppColors.ink)))),
                Text(sea ? '해외 대행구매' : paid ? '부탁해요' : '같이해요', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const Spacer(),
                _saveBtn(it),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      if (it.hot) ...[const Tag(label: '🔥 급해요', c: AppColors.red, bg: AppColors.redSoft), const SizedBox(width: 6)],
                      if (sea) ...[const Tag(label: '해외대행', c: AppColors.purple, bg: AppColors.purpleSoft), const SizedBox(width: 6)],
                      if (paid) Tag(label: catOf(it.cat).label, c: AppColors.sub, bg: AppColors.page),
                      // 내가 올린 글인지, 미리 만들어 둔 예시인지 상세에서도 밝힌다.
                      if (it.isMine)
                        ...[const SizedBox(width: 6), const Tag(label: '내가 올림', c: AppColors.yellowDeep, bg: AppColors.yellowSoft)]
                      else if (it.sample)
                        ...[const SizedBox(width: 6), const Tag(label: '예시', c: AppColors.faint, bg: AppColors.page)],
                    ]),
                    const SizedBox(height: 12),
                    Text(it.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.34, letterSpacing: -0.3)),
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 4),
                      child: Text(paid ? won(it.price) : '무료 동행', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink)),
                    ),
                    if (sea) const Text('물건값은 영수증 확인 후 별도 정산', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 20),
                      child: Wrap(
                        spacing: 14, runSpacing: 6,
                        children: [
                          if (!sea) Text('📍 ${distLabel(it)} · ${it.region ?? ''}', style: const TextStyle(fontSize: 13, color: AppColors.sub)),
                          if (!sea && it.mins > 0) Text('⏱ 약 ${it.mins}분', style: const TextStyle(fontSize: 13, color: AppColors.sub)),
                          if (sea) Text('📍 ${it.country ?? ''}${(it.place != null && it.place!.isNotEmpty) ? ' · ${it.place}' : ''}', style: const TextStyle(fontSize: 13, color: AppColors.sub)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(width: 44, height: 44, alignment: Alignment.center, decoration: const BoxDecoration(color: AppColors.yellowSoft, shape: BoxShape.circle), child: const Text('🙂', style: TextStyle(fontSize: 21))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(it.who, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                                  if (it.verified) const Padding(padding: EdgeInsets.only(top: 2), child: Text('✓ 본인인증 완료', style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w700))),
                                ],
                              ),
                            ),
                          ]),
                          Padding(
                            padding: const EdgeInsets.only(top: 13),
                            child: Container(
                              padding: const EdgeInsets.only(top: 13),
                              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
                              child: Row(children: [
                                it.reviews > 0 ? _stat('★ ${it.rating.toStringAsFixed(1)}', '후기 ${it.reviews}') : _stat('-', '후기 없음'),
                                _statDivider(),
                                _stat('${it.deals}회', '거래 완료'),
                                _statDivider(),
                                _stat('${it.resp}%', '응답률'),
                              ]),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Center(child: Text('🤝 도와준 ${it.helpCnt}회 · 🙋 부탁한 ${it.reqCnt}회', style: const TextStyle(fontSize: 11.5, color: AppColors.faint))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (paid) ...[RequestFacts(it: it), const SizedBox(height: 18)],
                    const Text('상세 내용', style: TextStyle(fontSize: 12.5, color: AppColors.sub, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 7),
                    Text(it.desc, style: const TextStyle(fontSize: 14.5, color: AppColors.ink, height: 1.7)),
                    const SizedBox(height: 18),
                    if (widget.myOffers.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                        decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('🔒 내가 보낸 가격 제안 (나와 요청자만 봐요)', style: TextStyle(fontSize: 12, color: AppColors.blue, fontWeight: FontWeight.w800))),
                            for (final o in widget.myOffers)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text.rich(
                                  TextSpan(
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
                                    children: [
                                      const TextSpan(text: '· '),
                                      TextSpan(text: won(o.price), style: const TextStyle(fontWeight: FontWeight.w800)),
                                      if (o.msg.isNotEmpty) TextSpan(text: ' — ${o.msg}'),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🛡 안전 안내', style: TextStyle(fontSize: 12, color: AppColors.sub, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(
                            sea ? '물건값·사례비는 앱이 안전하게 보관 후 완료 시 정산돼요 · 분쟁 시 중재해요' : '공개된 장소에서 만나요 · 위치공유는 동의할 때만 · 언제든 신고·차단할 수 있어요',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.ink, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
              child: (done || blocked != null)
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: blocked != null ? AppColors.page : AppColors.greenSoft, borderRadius: BorderRadius.circular(14)),
                      child: Text(blocked ?? '지원 내역에 저장됨 ✓', textAlign: TextAlign.center, style: TextStyle(color: blocked != null ? AppColors.sub : AppColors.green, fontWeight: FontWeight.w800, fontSize: 15)),
                    )
                  : Row(children: [
                      if (paid)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: OutlinedButton(
                            onPressed: () => setState(() => offerOpen = true),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.blue,
                              side: const BorderSide(color: AppColors.line, width: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('가격 제안', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          ),
                        ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => widget.onGrab(it),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.black, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(sea ? '내가 사다줄게요' : paid ? '지원하기' : '같이 신청하기', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                    ]),
            ),
          ]),
        ),
        if (offerOpen)
          OfferSheet(
            it: it,
            onClose: () => setState(() => offerOpen = false),
            onSend: (price, msg) {
              widget.onOffer(it, price, msg);
              setState(() => offerOpen = false);
            },
          ),
      ]),
    );
  }

  Widget _saveBtn(TaskItem it) {
    final saved = widget.isSaved(it.id);
    return IconButton(
      tooltip: saved ? '관심 해제' : '관심 저장',
      onPressed: () {
        widget.toggleSave(it.id);
        setState(() {});
      },
      icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: saved ? AppColors.yellowDeep : AppColors.ink),
    );
  }

  Widget _stat(String v, String l) {
    return Expanded(
      child: Column(children: [
        Text(v, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 2),
        Text(l, style: const TextStyle(fontSize: 11, color: AppColors.sub)),
      ]),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 30, color: AppColors.line);
}
