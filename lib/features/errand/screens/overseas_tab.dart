import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/mascot.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/surface.dart';
import '../../benefits/data/point_rules.dart';
import '../data/countries.dart';
import '../models/task_item.dart';
import '../navigation/errand_actions.dart';
import '../widgets/task_card.dart';
import 'overseas_screen.dart';

/// 하단 '해외' 탭 (시안 v33 `#osRoot`).
///
/// 홈과 같은 '부탁하기 | 돈벌기' 전환에 파란 겸이 카드를 쓴다.
/// - **부탁하기**: 이런 것도 부탁해도 돼요 → 이렇게 진행돼요(3단계 + 통관 안내)
/// - **돈벌기**: 나라 칩 + 지금 올라온 해외 요청 목록
///
/// 시안의 '이번 주 출국 이웃' 보드는 실제 출국 일정 데이터가 없어 옮기지 않았다.
/// 나라·품목 검색과 나라별 모아보기는 기존 [OverseasScreen]으로 이어진다.
class OverseasTab extends StatefulWidget {
  final List<TaskItem> items;
  final ErrandActions actions;
  final VoidCallback onPostSea;
  const OverseasTab({super.key, required this.items, required this.actions, required this.onPostSea});

  @override
  State<OverseasTab> createState() => _OverseasTabState();
}

class _OverseasTabState extends State<OverseasTab> {
  String mode = 'ask';
  String cc = 'all';
  final _listKey = GlobalKey();

  static const _examples = [
    (icon: 'gift', title: '일본 한정 굿즈·캐릭터 인형', color: AppColors.red),
    (icon: 'cart', title: '미국 코스트코 영양제', color: AppColors.blue),
    (icon: 'coffee', title: '다낭 콩카페 원두', color: Color(0xFFE57A16)),
    (icon: 'gift', title: '대만 펑리수 선물 세트', color: AppColors.green),
    (icon: 'bag', title: '파리 약국 화장품', color: AppColors.purple),
    (icon: 'coffee', title: '런던 홍차 틴 세트', color: Color(0xFFD99A00)),
  ];

  List<TaskItem> get _sea => widget.items.where((i) => i.mode == 'sea' && !i.isExpired).toList();

  void _openSearch() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OverseasScreen(items: widget.items, actions: widget.actions)),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SegToggle(
          labels: const ['부탁하기', '돈벌기'],
          index: mode == 'ask' ? 0 : 1,
          onChanged: (i) => setState(() => mode = i == 0 ? 'ask' : 'earn'),
        ),
        ...(mode == 'ask' ? _ask() : _earn()),
        const FootNote('해외 사다주기는 안전결제로만 진행돼요'),
      ],
    );
  }

  List<Widget> _ask() {
    final latest = _sea.firstOrNull;
    return [
      HeroCard(
        blue: true,
        sub: '해외 사다주기',
        title: '한국에 없는 물건\n**여행 가는 이웃**에게 부탁해요',
        liveBold: latest?.title,
        liveRest: latest == null ? null : [latest.country ?? '해외', latest.sample ? '예시' : '모집 중'].join(' · '),
        floats: const ['globe', 'gift', 'bag', 'heart'],
        cta: '해외 부탁하기',
        ctaIcon: 'plus',
        onCta: widget.onPostSea,
        note: '물건값은 영수증으로 정산, 부탁 비용은 ${nf(seaMin)}원부터예요',
      ),
      ExampleRotator(
        question: '이런 것도 부탁해도 돼요',
        items: _examples,
        onTap: (_) => widget.onPostSea(),
        footLabel: '나라도 물건도 상관없어요. 어떤 해외 부탁이든 올려보세요',
        onFoot: widget.onPostSea,
      ),
      _howItWorks(),
    ];
  }

  /// 이렇게 진행돼요 (.ost2-how)
  Widget _howItWorks() {
    const steps = [
      ('부탁 올리기', '상품과 예상가, 부탁 비용을 적어 올려요'),
      ('여행자가 수락·구매', '현지에서 사고 영수증을 올려요'),
      ('받고 정산', '물건을 받으면 물건값과 부탁 비용이 정산돼요'),
    ];
    return SecCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SecHead(title: '이렇게 진행돼요'),
        for (int i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.page, shape: BoxShape.circle),
                child: Text('${i + 1}', style: AppType.caption.copyWith(fontSize: 12, fontWeight: AppType.w700, color: AppColors.ink)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(steps[i].$1, style: AppType.body.copyWith(fontWeight: AppType.w700)),
                  const SizedBox(height: 2),
                  Text(steps[i].$2, style: AppType.meta.copyWith(fontSize: 12.5)),
                ]),
              ),
            ]),
          ),
        _customsNote(),
      ]),
    );
  }

  /// 통관 안내 (.os-note)
  Widget _customsNote() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(AppRadius.tile)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppIcon('shield', size: 17, color: AppColors.sub),
        const SizedBox(width: 9),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '통관비용은 따로 상의해 주세요\n', style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w700, color: AppColors.ink2)),
              const TextSpan(text: '구매 금액과 상품 종류에 따라 관세·부가세가 달라져요. 부탁하기 전에 여행자와 꼭 이야기해 주세요.'),
            ]),
            style: AppType.meta.copyWith(height: 1.55),
          ),
        ),
      ]),
    );
  }

  List<Widget> _earn() {
    final sea = _sea;
    final codes = <String>[];
    for (final i in sea) {
      if (i.cc != null && !codes.contains(i.cc)) codes.add(i.cc!);
    }
    final list = cc == 'all' ? sea : sea.where((i) => i.cc == cc).toList();

    return [
      HeroCard(
        blue: true,
        sub: '여행이 부업이 되는 시간',
        title: '여행 가는 김에 사다주고\n**부탁 비용**을 받아요',
        liveBold: '지금 올라온 해외 요청 ${sea.length}건',
        liveRest: codes.isEmpty ? null : '· ${codes.take(3).map((c) => countryOf(c).name).join(' · ')}',
        floats: const ['globe', 'wallet', 'sparkles', 'gift'],
        cta: '나라별 요청 찾기',
        ctaIcon: 'globe',
        onCta: _openSearch,
        note: '가는 나라를 고르면 그 나라 요청만 모아 볼 수 있어요',
      ),
      SecCard(
        key: _listKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SecHead(title: '해외 요청 사다주기', action: '전체보기', onAction: _openSearch),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                ChipWidget(label: '전체', active: cc == 'all', onTap: () => setState(() => cc = 'all')),
                for (final c in codes) ...[
                  const SizedBox(width: 7),
                  ChipWidget(label: countryOf(c).name, active: cc == c, onTap: () => setState(() => cc = c)),
                ],
              ],
            ),
          ),
          if (list.isEmpty)
            const EmptyState(compact: true, msg: '이 나라에 올라온 요청이 아직 없어요.')
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(children: [
                for (int i = 0; i < list.length; i++)
                  _OsRow(it: list[i], last: i == list.length - 1, onOpen: () => widget.actions.open(context, list[i])),
              ]),
            ),
          _customsNote(),
        ]),
      ),
    ];
  }
}

/// 해외 요청 한 줄 (.osrow)
class _OsRow extends StatelessWidget {
  final TaskItem it;
  final bool last;
  final VoidCallback onOpen;
  const _OsRow({required this.it, required this.last, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final place = seaPlace(it);
    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(children: [
          CountryFlag(cc: it.cc),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(it.sample ? '$place · 예시' : place,
                  style: AppType.meta.copyWith(fontWeight: AppType.w700, color: AppColors.blue)),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(it.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.body.copyWith(fontSize: 15, fontWeight: AppType.w700)),
              ),
              if (it.budget > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: '물건 예산 '),
                      TextSpan(text: won(it.budget), style: const TextStyle(fontWeight: AppType.w700, color: AppColors.ink2)),
                    ]),
                    style: AppType.meta.copyWith(fontWeight: AppType.w600),
                  ),
                ),
            ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('부탁 비용', style: AppType.caption.copyWith(fontWeight: AppType.w700)),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: nf(it.price)),
                const TextSpan(text: '원', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
              ]),
              style: const TextStyle(fontSize: 17, fontWeight: AppType.w700, color: AppColors.ink, letterSpacing: -0.5),
            ),
          ]),
        ]),
      ),
    );
  }
}
