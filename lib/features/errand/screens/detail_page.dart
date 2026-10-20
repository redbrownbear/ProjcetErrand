import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/tag.dart';
import '../data/categories.dart';
import '../models/offer.dart';
import '../models/task_item.dart';
import '../widgets/detail_parts.dart';
import '../widgets/offer_sheet.dart';
import '../widgets/report_sheet.dart';
import '../widgets/request_facts.dart';

class DetailPage extends StatefulWidget {
  final TaskItem it;
  final List<int> grabbed;
  final List<Offer> myOffers;
  final void Function(TaskItem) onGrab;
  final void Function(TaskItem, int, String) onOffer;
  final bool Function(int id) isSaved;
  final void Function(int id) toggleSave;
  final Future<bool> Function(TaskItem it, String reason, String detail)? onReport;
  final void Function(TaskItem it)? onBlock;
  const DetailPage({
    super.key,
    required this.it,
    required this.grabbed,
    required this.myOffers,
    required this.onGrab,
    required this.onOffer,
    required this.isSaved,
    required this.toggleSave,
    this.onReport,
    this.onBlock,
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
    // 자기 부탁·마감된 부탁에는 지원할 수 없다
    final blocked = it.isMine
        ? '내가 올린 부탁'
        : it.isExpired
        ? '마감된 부탁'
        : null;

    return Material(
      color: AppColors.page,
      child: Stack(
        children: [
          // 본문만 안전 영역 안에 둔다. 가격 제안 시트는 화면 전체를 덮는 딤이라
          // 여기 같이 넣으면 상태바 자리만 덮이지 않아 어색해진다 ([OfferSheet] 참고).
          SafeArea(
            child: Column(
              children: [
                _topBar(it, sea: sea, paid: paid),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _tags(it, sea: sea, paid: paid),
                        const SizedBox(height: 12),
                        Text(
                          it.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            height: 1.34,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 4),
                          child: Text(
                            paid ? won(it.price) : '무료 동행',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink),
                          ),
                        ),
                        if (sea) const Text('물건값은 영수증 확인 후 별도 정산', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 20),
                          child: _where(it, sea: sea),
                        ),
                        DetailAuthorCard(it: it),
                        const SizedBox(height: 18),
                        if (paid) ...[RequestFacts(it: it), const SizedBox(height: 18)],
                        const Text(
                          '상세 내용',
                          style: TextStyle(fontSize: 12.5, color: AppColors.sub, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 7),
                        Text(it.desc, style: const TextStyle(fontSize: 14.5, color: AppColors.ink, height: 1.7)),
                        const SizedBox(height: 18),
                        if (widget.myOffers.isNotEmpty) DetailMyOffers(offers: widget.myOffers),
                        DetailSafetyNote(sea: sea),
                        if (_canReport(it))
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => openReportSheet(context, it, onReport: widget.onReport!, onBlock: widget.onBlock!),
                              style: TextButton.styleFrom(foregroundColor: AppColors.sub, padding: EdgeInsets.zero),
                              child: const Text(
                                '이 부탁 신고 · 글쓴이 차단',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                DetailActionBar(
                  sea: sea,
                  paid: paid,
                  done: widget.grabbed.contains(it.id),
                  blocked: blocked,
                  onOffer: () => setState(() => offerOpen = true),
                  onGrab: () => widget.onGrab(it),
                ),
              ],
            ),
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
        ],
      ),
    );
  }

  /// 남이 올린 실제 부탁만 신고·차단할 수 있다(예시 글·내 글 제외)
  bool _canReport(TaskItem it) =>
      widget.onReport != null && widget.onBlock != null && !it.isMine && !it.sample && it.ownerUid != null;

  Widget _topBar(TaskItem it, {required bool sea, required bool paid}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      height: 52,
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          // 예전엔 '‹' 글자(폭 8px 남짓)만 눌려서 손가락으로 맞추기 어려웠다. 화살표와 제목을 함께 누르게 한다.
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 10, 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('‹', style: TextStyle(fontSize: 24, color: AppColors.ink)),
                  ),
                  Text(
                    sea
                        ? '해외 대행구매'
                        : paid
                        ? '부탁해요'
                        : '같이해요',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _saveBtn(it),
        ],
      ),
    );
  }

  Widget _tags(TaskItem it, {required bool sea, required bool paid}) {
    return Row(
      children: [
        if (it.hot) ...[const Tag(label: '급해요', c: AppColors.red, bg: AppColors.redSoft), const SizedBox(width: 6)],
        if (sea) ...[const Tag(label: '해외대행', c: AppColors.purple, bg: AppColors.purpleSoft), const SizedBox(width: 6)],
        if (paid) Tag(label: catOf(it.cat).label, c: AppColors.sub, bg: AppColors.page),
        // 내가 올린 글인지, 미리 만들어 둔 예시인지 상세에서도 밝힌다.
        if (it.isMine) ...[
          const SizedBox(width: 6),
          const Tag(label: '내가 올림', c: AppColors.yellowDeep, bg: AppColors.yellowSoft),
        ] else if (it.sample) ...[
          const SizedBox(width: 6),
          const Tag(label: '예시', c: AppColors.faint, bg: AppColors.page),
        ],
      ],
    );
  }

  Widget _where(TaskItem it, {required bool sea}) {
    const style = TextStyle(fontSize: 13, color: AppColors.sub);
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        if (!sea) Text('${distLabel(it)} · ${it.region ?? ''}', style: style),
        if (!sea && it.mins > 0) Text('⏱ 약 ${it.mins}분', style: style),
        if (sea) Text('${it.country ?? ''}${(it.place != null && it.place!.isNotEmpty) ? ' · ${it.place}' : ''}', style: style),
      ],
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
      icon: Icon(
        saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        color: saved ? AppColors.yellowDeep : AppColors.ink,
      ),
    );
  }
}
