import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../models/offer.dart';
import '../models/task_item.dart';

/// 부탁 상세의 작성자 카드 — 이름 · 본인인증 · 후기/거래/응답률 · 도와준·부탁한 횟수.
class DetailAuthorCard extends StatelessWidget {
  final TaskItem it;
  const DetailAuthorCard({super.key, required this.it});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.yellowSoft, shape: BoxShape.circle),
                child: const AppIcon('user', size: 18, color: AppColors.ink2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.who,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    if (it.verified)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          '✓ 본인인증 완료',
                          style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 13),
            child: Container(
              padding: const EdgeInsets.only(top: 13),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  it.reviews > 0 ? _stat('★ ${it.rating.toStringAsFixed(1)}', '후기 ${it.reviews}') : _stat('-', '후기 없음'),
                  _divider(),
                  _stat('${it.deals}회', '거래 완료'),
                  _divider(),
                  _stat('${it.resp}%', '응답률'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Text(
                '도와준 ${it.helpCnt}회 · 부탁한 ${it.reqCnt}회',
                style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _stat(String v, String l) {
    return Expanded(
      child: Column(
        children: [
          Text(
            v,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 2),
          Text(l, style: const TextStyle(fontSize: 11, color: AppColors.sub)),
        ],
      ),
    );
  }

  static Widget _divider() => Container(width: 1, height: 30, color: AppColors.line);
}

/// 내가 보낸 가격 제안 목록 (나와 요청자만 본다)
class DetailMyOffers extends StatelessWidget {
  final List<Offer> offers;
  const DetailMyOffers({super.key, required this.offers});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              '내가 보낸 가격 제안 (나와 요청자만 봐요)',
              style: TextStyle(fontSize: 12, color: AppColors.blue, fontWeight: FontWeight.w800),
            ),
          ),
          for (final o in offers)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
                  children: [
                    const TextSpan(text: '· '),
                    TextSpan(
                      text: won(o.price),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (o.msg.isNotEmpty) TextSpan(text: ' — ${o.msg}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 안전 안내 상자. 해외 대행은 정산·중재, 동네 부탁은 만남 안전을 말한다.
class DetailSafetyNote extends StatelessWidget {
  final bool sea;
  const DetailSafetyNote({super.key, required this.sea});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '안전 안내',
            style: TextStyle(fontSize: 12, color: AppColors.sub, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            sea
                ? '앱 안의 결제·보관은 아직 없어요 · 물건값은 영수증으로 확인하고 직접 정산해요 · 문제가 생기면 신고해 주세요'
                : '공개된 장소에서 만나요 · 위치공유는 동의할 때만 · 아래에서 신고·차단할 수 있어요',
            style: const TextStyle(fontSize: 12.5, color: AppColors.ink, height: 1.6),
          ),
        ],
      ),
    );
  }
}

/// 상세 맨 아래 버튼 줄. 지원할 수 없으면([blocked]) 이유를, 이미 지원했으면([done]) 저장됨을 보여 준다.
class DetailActionBar extends StatelessWidget {
  final bool sea;
  final bool paid;
  final bool done;
  final String? blocked;
  final VoidCallback onOffer;
  final VoidCallback onGrab;

  const DetailActionBar({
    super.key,
    required this.sea,
    required this.paid,
    required this.done,
    required this.blocked,
    required this.onOffer,
    required this.onGrab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: (done || blocked != null) ? _status() : _buttons(),
    );
  }

  Widget _status() {
    final why = blocked;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: why != null ? AppColors.page : AppColors.greenSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        why ?? '지원 내역에 저장됨 ✓',
        textAlign: TextAlign.center,
        style: TextStyle(color: why != null ? AppColors.sub : AppColors.green, fontWeight: FontWeight.w800, fontSize: 15),
      ),
    );
  }

  Widget _buttons() {
    return Row(
      children: [
        if (paid)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: OutlinedButton(
              onPressed: onOffer,
              style: OutlinedButton.styleFrom(
                // 테마의 기본 최소 크기는 폭이 무한(Size.fromHeight)이라, Row 안에서 그대로 두면
                // 레이아웃이 깨져 상세 화면 전체가 하얗게 떴다. 글자 폭만큼만 차지하게 한다.
                minimumSize: const Size(0, 50),
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
            onPressed: onGrab,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              sea
                  ? '내가 사다줄게요'
                  : paid
                  ? '지원하기'
                  : '같이 신청하기',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
