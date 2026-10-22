import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/app_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../../auth/services/auth_service.dart';
import '../models/consents.dart';
import '../widgets/consent_widgets.dart';

String _day(DateTime? d) => d == null ? '' : '${d.year}.${d.month}.${d.day}';

/// 로그인했는데 지금 버전의 필수 동의가 없는 계정(가입 때 저장 실패 · 약관 개정)에게 한 번 띄운다.
/// 동의하거나 로그아웃해야 닫힌다.
class ConsentGateScreen extends StatefulWidget {
  final AppSession session;
  const ConsentGateScreen({super.key, required this.session});

  @override
  State<ConsentGateScreen> createState() => _ConsentGateScreenState();
}

class _ConsentGateScreenState extends State<ConsentGateScreen> {
  late Map<String, bool> values = {
    for (final i in Consents.items)
      if (!i.required) i.key: widget.session.consents.isOn(i.key),
  };

  bool get _ready => Consents.items.where((i) => i.required).every((i) => values[i.key] ?? false);

  @override
  Widget build(BuildContext context) {
    final again = widget.session.consents.hadOldRequired;
    return PopScope(
      canPop: false,
      child: Material(
        color: AppColors.page,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  children: [
                    Text(again ? '약관이 바뀌었어요' : '시작하기 전에 동의가 필요해요', style: AppType.bigTab),
                    const SizedBox(height: 6),
                    Text(
                      again ? '바뀐 내용을 확인하고 다시 동의해 주세요.' : '필수 항목에 동의해야 부탁을 올리고 지원할 수 있어요. 선택 항목은 나중에 마이에서 바꿀 수 있어요.',
                      style: AppType.meta.copyWith(fontSize: 13.5, height: 1.55),
                    ),
                    const SizedBox(height: 18),
                    ConsentChecklist(values: values, onChanged: (v) => setState(() => values = v)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: BigButton(
                  label: '동의하고 시작하기',
                  onTap: _ready
                      ? () {
                          widget.session.setConsents(values);
                          Navigator.of(context).pop();
                        }
                      : null,
                ),
              ),
              TextButton(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await AuthService().signOut();
                  nav.pop();
                },
                child: Text('로그아웃', style: AppType.meta.copyWith(fontSize: 13)),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// 마이 › 동의 · 권한 관리. 필수 동의는 날짜만 보여 주고(철회는 탈퇴), 선택 동의는 바로 끄고 켠다.
class ConsentManageScreen extends StatefulWidget {
  final AppSession session;
  const ConsentManageScreen({super.key, required this.session});

  @override
  State<ConsentManageScreen> createState() => _ConsentManageScreenState();
}

class _ConsentManageScreenState extends State<ConsentManageScreen> {
  LocationPermission? _perm;

  @override
  void initState() {
    super.initState();
    _readPermission();
  }

  Future<void> _readPermission() async {
    try {
      final p = await Geolocator.checkPermission();
      if (mounted) setState(() => _perm = p);
    } catch (_) {
      // 웹 · 데스크톱 등 확인할 수 없는 환경
    }
  }

  String get _permLabel => switch (_perm) {
    LocationPermission.always || LocationPermission.whileInUse => '허용됨',
    LocationPermission.denied => '아직 안 물어봤거나 거부됨',
    LocationPermission.deniedForever => '거부됨 · 설정에서 바꿔야 해요',
    _ => '확인할 수 없어요',
  };

  Future<void> _openSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {
      widget.session.flash('이 기기에서는 설정 화면을 열 수 없어요');
    }
    await _readPermission();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final c = widget.session.consents;
        return PageFrame(
          title: '동의 · 권한 관리',
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            children: [
              _Group(
                title: '필수 동의',
                note: '필수 동의를 철회하려면 탈퇴해야 해요.',
                children: [
                  for (final i in Consents.items.where((i) => i.required))
                    _Line(
                      title: i.title,
                      sub: c.isOn(i.key) ? '동의함 · ${_day(c[i.key]?.at)}' : '동의 기록이 없어요',
                      trailing: TextButton(onPressed: () => showConsentDetail(context, i), child: const Text('보기')),
                    ),
                ],
              ),
              _Group(
                title: '선택 동의',
                note: '끄면 바로 반영돼요. 거래 알림(지원 · 수락 · 채팅)은 이 설정과 상관없이 와요.',
                children: [
                  for (final i in Consents.items.where((i) => !i.required))
                    _Line(
                      title: i.title,
                      sub: [i.summary, if (c[i.key] != null) '${c.isOn(i.key) ? '동의' : '철회'} ${_day(c[i.key]!.at)}'].join('\n'),
                      trailing: Switch(
                        value: c.isOn(i.key),
                        activeTrackColor: AppColors.green,
                        onChanged: i.key == Consents.night && !c.isOn(Consents.marketing)
                            ? null
                            : (on) => widget.session.setConsents({i.key: on}),
                      ),
                    ),
                ],
              ),
              _Group(
                title: '기기 권한',
                note: '위치 정보 이용에 동의한 뒤, 기기에서도 위치 권한을 허용해야 내 위치가 보여요.',
                children: [
                  _Line(
                    title: '위치 권한',
                    sub: _permLabel,
                    trailing: TextButton(onPressed: _openSettings, child: const Text('설정 열기')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final String note;
  final List<Widget> children;
  const _Group({required this.title, required this.note, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
            child: Text(title, style: AppType.sectionSmall),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Text(note, style: AppType.meta.copyWith(height: 1.5)),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String title;
  final String sub;
  final Widget trailing;
  const _Line({required this.title, required this.sub, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.body.copyWith(fontSize: 15, fontWeight: AppType.w500)),
                const SizedBox(height: 2),
                Text(sub, style: AppType.meta.copyWith(height: 1.45)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
