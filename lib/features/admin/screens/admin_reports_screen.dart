import 'package:flutter/material.dart';

import '../../../core/backend/server_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/stable_sort.dart';
import '../../../core/widgets/kit.dart';
import '../models/admin_report.dart';
import '../repositories/admin_repository.dart';

/// 마이 › 운영 › 신고 처리 (개발 To-do A36). 운영자 계정(role=admin)에만 메뉴가 보인다.
/// 신고 목록(처리 전 · 처리됨) → 신고 한 건: 신고된 사람 · 신고한 사람 · 부탁 글 → 문제 없음 · 경고 · 이용 정지,
/// 정지 해제, 글 내리기 · 되돌리기. 모든 처리는 서버 함수가 하고 adminLog에 남는다.
class AdminReportsScreen extends StatefulWidget {
  final AdminRepository repo;

  /// 부탁 글 보기
  final void Function(int requestId)? onOpenRequest;
  const AdminReportsScreen({super.key, this.repo = const AdminRepository(), this.onOpenRequest});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool showResolved = false;
  late final Stream<List<AdminReport>> reports = widget.repo.watchReports();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminReport>>(
      stream: reports,
      builder: (context, snap) {
        final all = snap.data ?? const <AdminReport>[];
        final open = all.where((r) => !r.resolved).toList()..sortStable(AdminReport.byUrgency);
        final done = all.where((r) => r.resolved).toList();
        final list = showResolved ? done : open;
        // 같은 사람이 받은 신고 수(불러온 범위 안에서)
        final perTarget = <String, int>{};
        for (final r in all) {
          perTarget[r.targetUid] = (perTarget[r.targetUid] ?? 0) + 1;
        }
        return PageFrame(
          title: '신고 처리',
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text('운영자 전용 화면이에요. 처리 결과는 기록(adminLog)에 남아요.', style: AppType.meta.copyWith(fontSize: 13, height: 1.5)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('admin-tab-open'),
                    label: Text('처리 전 ${open.length}'),
                    selected: !showResolved,
                    onSelected: (_) => setState(() => showResolved = false),
                  ),
                  ChoiceChip(
                    key: const Key('admin-tab-done'),
                    label: Text('처리됨 ${done.length}'),
                    selected: showResolved,
                    onSelected: (_) => setState(() => showResolved = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snap.hasError)
                _Empty('신고를 읽지 못했어요. 운영자 권한이 적용됐는지(다시 로그인) 확인해 주세요.')
              else if (snap.connectionState == ConnectionState.waiting && all.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              else if (list.isEmpty)
                _Empty(showResolved ? '처리한 신고가 없어요.' : '처리할 신고가 없어요.')
              else
                for (final r in list)
                  _ReportCard(
                    report: r,
                    targetCount: perTarget[r.targetUid] ?? 1,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AdminReportDetailScreen(
                          report: r,
                          repo: widget.repo,
                          targetCount: perTarget[r.targetUid] ?? 1,
                          onOpenRequest: widget.onOpenRequest,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Text(text, textAlign: TextAlign.center, style: AppType.meta.copyWith(fontSize: 13.5, height: 1.6)),
  );
}

class _ReportCard extends StatelessWidget {
  final AdminReport report;
  final int targetCount;
  final VoidCallback onTap;
  const _ReportCard({required this.report, required this.targetCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = report;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Tap(
        onTap: onTap,
        radius: AppRadius.card,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!r.resolved && r.priority != ReportPriority.normal) ...[
                    _Pill(r.priority.label, r.priority == ReportPriority.urgent ? AppColors.red : AppColors.orange),
                    const SizedBox(width: 6),
                  ],
                  Expanded(child: Text(r.category?.label ?? r.reason, style: AppType.sectionSmall)),
                  if (r.resolution case final res?) _Pill(res.label, res == ReportResolution.dismissed ? AppColors.sub : AppColors.red),
                ],
              ),
              if (r.detail != null) ...[
                const SizedBox(height: 4),
                Text(r.detail!, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppType.body.copyWith(height: 1.5)),
              ],
              const SizedBox(height: 6),
              Text(
                [dateTimeLabel(r.createdAt), if (r.requestId != null) '부탁 글', if (targetCount > 1) '이 사람 신고 $targetCount건'].join(' · '),
                style: AppType.meta.copyWith(color: targetCount > 1 ? AppColors.red : AppColors.sub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.pill)),
    child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
  );
}

/// 신고 한 건 처리
class AdminReportDetailScreen extends StatefulWidget {
  final AdminReport report;
  final AdminRepository repo;
  final int targetCount;
  final void Function(int requestId)? onOpenRequest;
  const AdminReportDetailScreen({
    super.key,
    required this.report,
    required this.repo,
    this.targetCount = 1,
    this.onOpenRequest,
  });

  @override
  State<AdminReportDetailScreen> createState() => _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  late final AdminReport r = widget.report;
  late final Stream<AdminUser> target = widget.repo.watchUser(r.targetUid);
  late final Stream<AdminUser>? reporter = r.reporterUid.isEmpty ? null : widget.repo.watchUser(r.reporterUid);
  late final Stream<AdminRequest?>? request = r.requestId == null ? null : widget.repo.watchRequest(r.requestId!);
  late final memo = TextEditingController(text: r.memo ?? '');

  /// 서버 함수를 부르는 중
  bool busy = false;

  /// 방금 한 처리 결과 · 실패 문구
  String? message;
  bool failed = false;

  @override
  void dispose() {
    memo.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() job, String done) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await job();
      if (!mounted) return;
      setState(() {
        message = done;
        failed = false;
      });
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        message = e.message;
        failed = true;
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
              child: const Text('확인'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _resolve(ReportResolution res) async {
    if (res == ReportResolution.suspended &&
        !await _confirm('이용 정지', '신고된 사람의 계정을 정지해요. 정지하면 지원 · 수락 · 채팅 등 모든 거래가 막혀요.')) {
      return;
    }
    await _run(() => widget.repo.resolve(r.id, res, memo.text), '처리했어요: ${res.label}');
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: '신고 처리',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Box(
            title: '신고 내용',
            children: [
              Text(r.reason, style: AppType.sectionSmall),
              if (r.detail != null) ...[const SizedBox(height: 6), Text(r.detail!, style: AppType.body.copyWith(height: 1.55))],
              if (r.category case final c?) ...[
                const SizedBox(height: 8),
                Text(
                  '자동 분류: ${c.label} · 긴급도 ${r.priority.label}',
                  style: AppType.meta.copyWith(color: r.priority == ReportPriority.urgent ? AppColors.red : AppColors.ink2),
                ),
                for (final s in r.signals) Text('· $s', style: AppType.meta),
                Text('신고한 사람에게는 유형에 맞는 1차 안내가 자동으로 갔어요', style: AppType.meta),
              ],
              const SizedBox(height: 8),
              Text('접수 ${dateTimeLabel(r.createdAt)} · 신고 번호 ${r.id}', style: AppType.meta),
              if (r.resolution case final res?)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    [
                      '처리됨: ${res.label}',
                      if (r.resolvedAt != null) dateTimeLabel(r.resolvedAt!),
                      if (r.memo != null && r.memo!.isNotEmpty) '메모 "${r.memo}"',
                    ].join(' · '),
                    style: AppType.meta.copyWith(color: AppColors.ink2),
                  ),
                ),
            ],
          ),
          _Box(
            title: '신고된 사람',
            children: [
              StreamBuilder<AdminUser>(
                stream: target,
                builder: (context, snap) {
                  final u = snap.data;
                  if (u == null) return Text(r.targetUid, style: AppType.meta);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.nickname, style: AppType.body.copyWith(fontWeight: AppType.w600)),
                      const SizedBox(height: 2),
                      Text(
                        [
                          u.suspended ? '이용 정지 중${u.suspendReason != null ? ' (${u.suspendReason})' : ''}' : '정상 이용 중',
                          if (widget.targetCount > 1) '받은 신고 ${widget.targetCount}건(최근)',
                        ].join(' · '),
                        style: AppType.meta.copyWith(color: u.suspended ? AppColors.red : AppColors.sub),
                      ),
                      Text(u.uid, style: AppType.caption),
                      if (u.suspended)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            key: const Key('admin-unsuspend'),
                            onPressed: busy ? null : () => _run(() => widget.repo.setSuspended(u.uid, false), '정지를 풀었어요'),
                            child: const Text('정지 풀기'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          if (reporter != null)
            _Box(
              title: '신고한 사람',
              children: [
                StreamBuilder<AdminUser>(
                  stream: reporter,
                  builder: (context, snap) => Text(
                    snap.data == null ? r.reporterUid : '${snap.data!.nickname} · ${r.reporterUid}',
                    style: AppType.meta.copyWith(color: AppColors.ink2),
                  ),
                ),
              ],
            ),
          if (request != null)
            _Box(
              title: '신고된 부탁 글',
              children: [
                StreamBuilder<AdminRequest?>(
                  stream: request,
                  builder: (context, snap) {
                    final q = snap.data;
                    if (q == null) {
                      return Text(
                        snap.connectionState == ConnectionState.waiting ? '불러오는 중…' : '글을 찾을 수 없어요 (#${r.requestId})',
                        style: AppType.meta,
                      );
                    }
                    final rid = int.tryParse(q.id);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.title, style: AppType.body.copyWith(fontWeight: AppType.w600)),
                        const SizedBox(height: 2),
                        Text(
                          [q.statusLabel, if (q.who.isNotEmpty) q.who, if (q.hidden && q.hiddenReason != null) q.hiddenReason!].join(' · '),
                          style: AppType.meta.copyWith(color: q.hidden ? AppColors.red : AppColors.sub),
                        ),
                        Wrap(
                          spacing: 4,
                          children: [
                            if (rid != null && widget.onOpenRequest != null && !q.hidden)
                              TextButton(onPressed: () => widget.onOpenRequest!(rid), child: const Text('글 보기')),
                            if (!q.hidden)
                              TextButton(
                                key: const Key('admin-hide'),
                                onPressed: busy
                                    ? null
                                    : () async {
                                        if (!await _confirm('글 내리기', '이 글을 목록에서 내리고 글쓴이에게 알려요. 나중에 되돌릴 수 있어요.')) return;
                                        await _run(
                                          () => widget.repo.setRequestHidden(q.id, true, reason: '신고(${r.reason})가 확인돼'),
                                          '글을 내렸어요',
                                        );
                                      },
                                style: TextButton.styleFrom(foregroundColor: AppColors.red),
                                child: const Text('글 내리기'),
                              )
                            else if (q.canUnhide)
                              TextButton(
                                key: const Key('admin-unhide'),
                                onPressed: busy ? null : () => _run(() => widget.repo.setRequestHidden(q.id, false), '글을 되돌렸어요'),
                                child: const Text('글 되돌리기'),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          _Box(
            title: r.resolved ? '처리 고치기' : '처리하기',
            children: [
              TextField(
                key: const Key('admin-memo'),
                controller: memo,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(hintText: '운영 메모 (선택 · 사용자에게 보이지 않아요)', border: OutlineInputBorder()),
              ),
              Text(
                '경고는 신고된 사람에게 경고 알림을, 이용 정지는 계정을 정지해요. 신고한 사람에게는 처리했다는 알림만 가요.',
                style: AppType.meta.copyWith(height: 1.5),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final res in ReportResolution.values) ...[
                    if (res != ReportResolution.values.first) const SizedBox(width: 8),
                    Expanded(
                      child: BigButton(
                        key: Key('admin-resolve-${res.name}'),
                        label: res.label,
                        height: 44,
                        bg: switch (res) {
                          ReportResolution.dismissed => AppColors.page,
                          ReportResolution.warned => AppColors.yellow,
                          ReportResolution.suspended => AppColors.red,
                        },
                        fg: res == ReportResolution.suspended ? Colors.white : AppColors.ink,
                        onTap: busy ? null : () => _resolve(res),
                      ),
                    ),
                  ],
                ],
              ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    message!,
                    key: const Key('admin-message'),
                    style: AppType.body.copyWith(color: failed ? AppColors.red : AppColors.greenDeep, fontWeight: AppType.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Box({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppType.meta.copyWith(fontWeight: AppType.w700)),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}
