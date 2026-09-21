import 'package:flutter/material.dart';

import '../../../core/compliance/disclosures.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/fact_rows.dart';
import '../../../core/widgets/screen_frame.dart';
import '../models/mission_meta.dart';
import '../models/partner_mission.dart';
import '../repositories/mission_progress.dart';

/// 미션 상세. 시안(`gyumsa-refined`)의 `미션 상세` 화면.
///
/// 참여 전 확인사항을 먼저 읽고, 참여 시작 → 인증 제출 → 검수 → 적립을
/// 한 화면 안에서 단계로 따라간다. 규제 영역별 고지(§19)는 시안에 없지만
/// 법적으로 필요한 내용이라 그대로 둔다.
class PartnerMissionDetailScreen extends StatefulWidget {
  final PartnerMission m;
  final bool done;
  final void Function(PartnerMission) onComplete;
  const PartnerMissionDetailScreen({super.key, required this.m, required this.done, required this.onComplete});

  @override
  State<PartnerMissionDetailScreen> createState() => _PartnerMissionDetailScreenState();
}

class _PartnerMissionDetailScreenState extends State<PartnerMissionDetailScreen> {
  late MissionProgress progress = MissionProgress.load();
  late final proof = TextEditingController(text: progress.proofOf(widget.m.id));
  String? error;

  static const _labels = ['참여 시작', '인증 제출', '적립 완료'];

  MissionStage get stage => progress.stageOf(widget.m.id);
  bool get done => widget.done;

  int get stepIndex {
    if (done) return 2;
    return switch (stage) {
      MissionStage.ready => 0,
      MissionStage.active => 1,
      MissionStage.review => 2,
    };
  }

  @override
  void dispose() {
    proof.dispose();
    super.dispose();
  }

  void _next() {
    if (done) return;
    switch (stage) {
      case MissionStage.ready:
        setState(() => progress = progress.update(widget.m.id, MissionStage.active));
      case MissionStage.active:
        final text = proof.text.trim();
        if (text.length < 5) {
          setState(() => error = '인증 내용을 5자 이상 입력해 주세요.');
          return;
        }
        setState(() {
          progress = progress.update(widget.m.id, MissionStage.review, proof: text);
          error = null;
        });
      case MissionStage.review:
        widget.onComplete(widget.m);
        Navigator.pop(context);
    }
  }

  String get _buttonLabel {
    if (done) return '적립 완료';
    return switch (stage) {
      MissionStage.ready => '참여 시작 체험',
      MissionStage.active => '인증 제출 체험',
      MissionStage.review => '검수 승인 체험',
    };
  }

  (String, String) get _stageCopy {
    if (done) return ('포인트 적립이 완료됐어요', '내 포인트와 적립 내역에서 확인할 수 있어요.');
    return switch (stage) {
      MissionStage.ready => ('조건을 확인하고 시작해 보세요', '${widget.m.costTag} · ${widget.m.cond}'),
      MissionStage.active => ('참여 중이에요', '미션을 마치면 인증 내용을 작성해 주세요.'),
      MissionStage.review => ('인증을 제출했어요 · 검수 대기', '승인 후 보상이 적립됩니다. 아래에서 승인 흐름을 체험해 보세요.'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final dis = Disclosures.of(m.disclosureKey);
    final (stageTitle, stageBody) = _stageCopy;

    return ScreenFrame(
      title: '미션 상세',
      onBack: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          Text('${m.brand} · 체험용 미션', style: AppType.caption.copyWith(fontSize: 11, color: AppColors.greetingPoint)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(m.title, style: AppType.section.copyWith(fontSize: 22, height: 1.4, color: AppColors.attendTitle)),
          ),
          Text(m.desc, style: AppType.meta.copyWith(fontSize: 12.5, height: 1.8)),

          // 보상·시간·방식 세 칸 (.reward-v9 + .gy-summary)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(children: [
              Expanded(child: _tile('승인 후 적립', '+${nf(m.points)}P', point: true)),
              const SizedBox(width: 10),
              Expanded(child: _tile('예상 시간', m.time)),
              const SizedBox(width: 10),
              Expanded(child: _tile('참여 방식', m.mode)),
            ]),
          ),

          _heading('참여 전에 확인하세요'),
          FactRows([
            ('참여 대상', m.cond),
            ('구매·비용', m.costDetail),
            ('완료 조건', m.completionRule),
            ('완료 인정', m.verify),
            ('지급 시점', '인증 검수 승인 후 · 실제 지급 일정은 모집 시 안내'),
          ]),

          if (m.isBlog)
            Container(
              margin: const EdgeInsets.only(top: 13),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: AppColors.attendSoft, borderRadius: BorderRadius.circular(10)),
              child: Text('제품·메뉴 제공과 포인트 보상을 구분해 확인하세요. 게시물에는 제공받은 혜택을 표시해야 해요.',
                  style: AppType.caption.copyWith(fontSize: 12, height: 1.75, color: AppColors.yellowDeep)),
            ),

          _more(),

          // 규제 영역별 필수 고지 (§19)
          Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text('참여 전 확인 · ${dis.label}',
                    style: AppType.caption.copyWith(fontSize: 11.5, fontWeight: AppType.w700, color: AppColors.purple)),
              ),
              Text(dis.body, style: AppType.caption.copyWith(fontSize: 12, height: 1.6, color: AppColors.purple)),
              if (m.disclosureKey != 'partner')
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(Disclosures.partner.body,
                      style: AppType.caption.copyWith(fontSize: 12, height: 1.6, color: AppColors.purple)),
                ),
            ]),
          ),

          _heading('나의 참여 상태'),
          _steps(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.goalMintBg, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(stageTitle, style: AppType.sectionSmall.copyWith(fontSize: 14, color: AppColors.attendPoint)),
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(stageBody, style: AppType.caption.copyWith(fontSize: 12, height: 1.7, color: AppColors.goalMintSub)),
              ),
            ]),
          ),

          if (!done && stage == MissionStage.active) _proofField(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(error!, style: AppType.meta.copyWith(fontSize: 12, color: AppColors.red)),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
            child: Text('참여·검수·적립 흐름을 체험하는 화면입니다. 실제 신청이나 자료 전송은 이루어지지 않아요.',
                style: AppType.caption.copyWith(fontSize: 11, height: 1.7)),
          ),
          ElevatedButton(
            onPressed: done ? null : _next,
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: AppColors.goalMintBg,
              disabledForegroundColor: AppColors.attendPoint,
            ),
            child: Text(_buttonLabel),
          ),
          if (done)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('${nf(widget.m.points)}P를 받았어요 · 체험 적립',
                  textAlign: TextAlign.center, style: AppType.caption.copyWith(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Text(text, style: AppType.sectionSmall.copyWith(fontSize: 16)),
      );

  Widget _tile(String label, String value, {bool point = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppType.caption.copyWith(fontSize: 11, color: AppColors.goalMintSub)),
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(value,
              style: AppType.body.copyWith(
                fontSize: 14,
                fontWeight: AppType.w700,
                color: point ? AppColors.green : AppColors.ink,
              )),
        ),
      ]),
    );
  }

  /// 모집·개인정보 안내 (.gy-more)
  Widget _more() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text('모집·개인정보 안내', style: AppType.meta.copyWith(fontSize: 12, color: AppColors.inkSoft)),
        children: [
          Text(
            '현재는 예시 미션입니다. 실제 모집 시 제공 혜택, 모집 기간·정원, 방문 주소, 검수 기준, '
            '재참여 제한, 개인정보 수집 항목 및 문의처가 안내됩니다.',
            style: AppType.caption.copyWith(fontSize: 12, height: 1.8),
          ),
        ],
      ),
    );
  }

  /// 참여 단계 표시 (.gy-progress)
  Widget _steps() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(children: [
        for (int i = 0; i < _labels.length; i++)
          Expanded(
            child: Row(children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i <= stepIndex ? AppColors.goalMintBar : AppColors.page,
                  shape: BoxShape.circle,
                ),
                child: Text('${i + 1}',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0,
                        color: i <= stepIndex ? Colors.white : AppColors.faint)),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(_labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.caption.copyWith(
                      fontSize: 11,
                      fontWeight: i == stepIndex ? AppType.w700 : AppType.w400,
                      color: i == stepIndex ? AppColors.attendPoint : AppColors.faint,
                    )),
              ),
            ]),
          ),
      ]),
    );
  }

  /// 참여 인증 입력 (.gy-proof)
  Widget _proofField() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('참여 인증 (체험)', style: AppType.body.copyWith(fontSize: 13, fontWeight: AppType.w600)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: TextField(
            controller: proof,
            maxLines: 4,
            maxLength: 500,
            onChanged: (_) {
              if (error != null) setState(() => error = null);
            },
            style: AppType.body.copyWith(fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText: widget.m.isBlog ? '후기 링크 또는 체험 내용을 입력해 주세요' : '완료한 내용을 5자 이상 입력해 주세요',
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green)),
            ),
          ),
        ),
        Text('실제 개인정보 대신 예시 내용을 입력해 주세요.', style: AppType.caption.copyWith(fontSize: 11)),
      ]),
    );
  }
}
