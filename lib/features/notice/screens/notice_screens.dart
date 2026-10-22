import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../models/notice.dart';
import '../repositories/notice_repository.dart';

String _date(DateTime d) => '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

/// 마이 › 공지 · 업데이트 (A33). 고정 글 먼저, 그다음 최신 순. 연 뒤에 올라온 글엔 '새 글'.
class NoticeListScreen extends StatefulWidget {
  final NoticeRepository repo;

  /// 테스트에서 지금 시각을 고정한다
  final DateTime? now;
  const NoticeListScreen({super.key, this.repo = const NoticeRepository(), this.now});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  late final Stream<List<Notice>> stream = widget.repo.watch();

  /// 이번에 열기 전의 '본 시각' — 화면을 여는 동안 '새 글' 표시를 유지한다
  final DateTime? seenBefore = NoticeRepository.seenAt;

  @override
  void initState() {
    super.initState();
    NoticeRepository.markSeen(widget.now ?? DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: '공지 · 업데이트',
      child: StreamBuilder<List<Notice>>(
        stream: stream,
        builder: (context, snap) {
          final list = Notice.visible(snap.data ?? const [], widget.now ?? DateTime.now());
          if (list.isEmpty) {
            return Center(
              child: snap.connectionState == ConnectionState.waiting
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : Text('아직 올라온 공지가 없어요', style: AppType.meta.copyWith(fontSize: 13.5)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final n = list[i];
              final fresh = seenBefore == null || n.publishedAt.isAfter(seenBefore!);
              return Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => NoticeDetailScreen(notice: n))),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _Badge(n.pinned ? '고정 · ${n.kindLabel}' : n.kindLabel, strong: n.pinned),
                                  if (fresh) ...[
                                    const SizedBox(width: 6),
                                    Text('새 글', style: AppType.meta.copyWith(color: AppColors.red, fontWeight: AppType.w700)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                n.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.body.copyWith(fontSize: 15, fontWeight: AppType.w700),
                              ),
                              const SizedBox(height: 3),
                              Text(_date(n.publishedAt), style: AppType.meta),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool strong;
  const _Badge(this.label, {this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: strong ? AppColors.yellowSoft : AppColors.page, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: AppType.meta.copyWith(fontSize: 11.5, fontWeight: AppType.w700, color: strong ? AppColors.yellowInk : AppColors.ink2)),
    );
  }
}

/// 공지 한 건. 본문은 올린 그대로(줄바꿈 유지), 길게 눌러 복사할 수 있다
class NoticeDetailScreen extends StatelessWidget {
  final Notice notice;
  const NoticeDetailScreen({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    final n = notice;
    return PageFrame(
      title: n.kindLabel,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(n.title, style: AppType.section.copyWith(height: 1.35)),
          const SizedBox(height: 6),
          Text(_date(n.publishedAt), style: AppType.meta),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.line)),
          SelectableText(n.body.isEmpty ? '내용이 없어요' : n.body, style: AppType.body.copyWith(fontSize: 15, height: 1.65)),
        ],
      ),
    );
  }
}
