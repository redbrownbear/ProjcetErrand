import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/screen_frame.dart';
import '../models/partner_proposal.dart';
import '../repositories/partner_repository.dart';

/// 브랜드 협업 제안서 작성. 시안(`gyumsa-refined`)의 `GyPartner`.
///
/// 기업 미션([PartnerProposal.kindBrand])과 공동구매([PartnerProposal.kindGroup])가
/// 같은 폼을 쓰고 라벨·예시 문구만 달라진다.
class PartnerProposalScreen extends StatefulWidget {
  /// [PartnerProposal.kindBrand] | [PartnerProposal.kindGroup]
  final String kind;
  const PartnerProposalScreen({super.key, this.kind = PartnerProposal.kindBrand});

  @override
  State<PartnerProposalScreen> createState() => _PartnerProposalScreenState();
}

class _PartnerProposalScreenState extends State<PartnerProposalScreen> {
  late String type;
  final company = TextEditingController();
  final contact = TextEditingController();
  final email = TextEditingController();
  final title = TextEditingController();
  final url = TextEditingController();
  final budget = TextEditingController();
  final period = TextEditingController();
  final details = TextEditingController();
  bool consent = false;

  bool saved = false;
  String? error;
  late List<PartnerProposal> history;

  bool get group => widget.kind == PartnerProposal.kindGroup;
  List<String> get types => group ? PartnerProposal.groupTypes : PartnerProposal.brandTypes;

  @override
  void initState() {
    super.initState();
    type = types.first;
    history = PartnerRepository.load().where((p) => p.kind == widget.kind).toList();
  }

  @override
  void dispose() {
    for (final c in [company, contact, email, title, url, budget, period, details]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final missing = company.text.trim().isEmpty ||
        contact.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        title.text.trim().isEmpty ||
        details.text.trim().isEmpty ||
        !consent;
    if (missing) {
      setState(() => error = '필수 항목과 확인 체크를 입력해 주세요.');
      return;
    }
    final proposal = PartnerProposal(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      kind: widget.kind,
      type: type,
      company: company.text.trim(),
      contact: contact.text.trim(),
      email: email.text.trim(),
      title: title.text.trim(),
      url: url.text.trim(),
      budget: budget.text.trim(),
      period: period.text.trim(),
      details: details.text.trim(),
      at: DateTime.now().toIso8601String(),
    );
    final all = PartnerRepository.add(proposal);
    setState(() {
      history = all.where((p) => p.kind == widget.kind).toList();
      saved = true;
      error = null;
      for (final c in [company, contact, email, title, url, budget, period, details]) {
        c.clear();
      }
      consent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: group ? '공동구매 제안하기' : '브랜드 협업 제안',
      onBack: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
        children: [
          Text('겸사겸사 파트너', style: AppType.caption.copyWith(fontSize: 11, color: AppColors.greetingPoint)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(group ? '좋은 상품을 함께 나눠요' : '브랜드의 이야기를 들려주세요',
                style: AppType.section.copyWith(fontSize: 24, height: 1.4, color: AppColors.attendTitle)),
          ),
          Text(
            group
                ? '판매사의 입점 제안과 이용자의 공동구매 요청을 모두 받는 공간이에요.'
                : '원하는 목표와 대상을 알려 주세요. 예산·일정은 아직 정해지지 않아도 괜찮아요.',
            style: AppType.meta.copyWith(height: 1.8),
          ),
          const SizedBox(height: 10),
          if (saved) _success() else ..._form(),
          _history(),
        ],
      ),
    );
  }

  List<Widget> _form() {
    return [
      AppSelectField(
        label: '제안 유형',
        required: true,
        value: type,
        options: types,
        onChanged: (v) => setState(() => type = v),
      ),
      AppField(
        label: group && type == '이 상품 공구 요청' ? '이름·닉네임' : '회사·브랜드명',
        required: true,
        controller: company,
      ),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: AppField(label: '담당자·제안자', required: true, controller: contact)),
        const SizedBox(width: 13),
        Expanded(
          child: AppField(
            label: '회신 이메일',
            required: true,
            controller: email,
            keyboardType: TextInputType.emailAddress,
          ),
        ),
      ]),
      AppField(label: group ? '상품명·제안 제목' : '협업 주제', required: true, controller: title),
      AppField(
        label: group ? '상품 링크 (선택)' : '회사·브랜드 링크 (선택)',
        controller: url,
        placeholder: 'https://',
        keyboardType: TextInputType.url,
      ),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: AppField(label: group ? '희망 판매가·수량 (선택)' : '예산·참여자 보상 (선택)', controller: budget)),
        const SizedBox(width: 13),
        Expanded(child: AppField(label: '희망 진행 기간 (선택)', controller: period)),
      ]),
      AppField(
        label: group ? '상품·공급·배송 조건 또는 요청 내용' : '협업 목표와 희망 내용',
        required: true,
        controller: details,
        maxLines: 5,
        placeholder: group
            ? '판매사는 공급가, 최소 수량, 배송·반품 조건을 알려주세요. 공구 요청은 원하는 상품과 이유를 적어주세요.'
            : '브랜드 소개, 만나고 싶은 고객, 함께 해보고 싶은 활동을 편하게 적어 주세요.',
      ),
      AppCheckRow(
        value: consent,
        onChanged: (v) => setState(() => consent = v),
        label: '작성 내용을 이 기기에 저장하는 데 동의합니다.',
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(error!, style: AppType.meta.copyWith(fontSize: 12, color: AppColors.red)),
        ),
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text('시안에서는 제안서를 저장하며, 실제 문의 전송은 연동 전입니다.',
            style: AppType.caption.copyWith(fontSize: 11, height: 1.7)),
      ),
      ElevatedButton(onPressed: _submit, child: const Text('제안서 저장하기')),
    ];
  }

  Widget _success() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(color: AppColors.goalMintBg, borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        const AppIcon('check', size: 32, color: AppColors.green),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text('제안서를 저장했어요', style: AppType.sectionSmall.copyWith(fontSize: 16, color: AppColors.green)),
        ),
        Text('아래 내역에서 확인할 수 있어요. 시안이므로 운영팀에 실제로 전송되지는 않습니다.',
            textAlign: TextAlign.center,
            style: AppType.caption.copyWith(fontSize: 12, height: 1.8, color: AppColors.goalMintSub)),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: () => setState(() => saved = false), child: const Text('새 제안 작성')),
      ]),
    );
  }

  Widget _history() {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('내 제안 내역', style: AppType.sectionSmall.copyWith(fontSize: 16)),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Text('아직 저장한 제안이 없어요.', style: AppType.meta),
          ),
        for (final p in history)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 14),
              shape: const Border(),
              collapsedShape: const Border(),
              title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.title, style: AppType.meta.copyWith(fontSize: 12, fontWeight: AppType.w600, color: AppColors.ink)),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text('${p.status} · ${p.day}', style: AppType.caption.copyWith(fontSize: 10)),
                ),
              ]),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.details, style: AppType.meta.copyWith(fontSize: 13, height: 1.8, color: AppColors.inkSoft)),
                    const SizedBox(height: 8),
                    Text('${p.company} · ${p.email}', style: AppType.caption),
                  ]),
                ),
              ],
            ),
          ),
      ]),
    );
  }
}
