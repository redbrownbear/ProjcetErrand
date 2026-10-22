import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/backend/server_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../repositories/photo_repository.dart';
import '../widgets/photo_pick.dart';

/// 거래 한 건의 사진 · 영수증 (A37). 거래 당사자 둘만 본다.
///
/// - 영수증: 금액과 함께 올린다. 앱 안의 결제가 아직 없어서, 받는 사람은 이 금액을 보고 직접 보낸다
/// - 완료 사진: 전달 · 구매 결과
/// 끝난 거래(완료 · 취소)는 보기만 한다.
class TradePhotosScreen extends StatefulWidget {
  final String tradeId;
  final String title;
  final String myUid;

  /// 아직 진행 중인 거래(사진을 올릴 수 있다)
  final bool open;

  /// 테스트에서 저장소를 바꿔 끼운다
  final PhotoRepository? repo;
  const TradePhotosScreen({super.key, required this.tradeId, required this.title, required this.myUid, required this.open, this.repo});

  @override
  State<TradePhotosScreen> createState() => _TradePhotosScreenState();
}

class _TradePhotosScreenState extends State<TradePhotosScreen> {
  late final PhotoRepository repo = widget.repo ?? PhotoRepository(widget.tradeId);
  late final Stream<List<TradePhoto>> stream = repo.watch();
  bool sending = false;
  String? note;

  Future<int?> _askAmount() async {
    final ctrl = TextEditingController();
    final v = await showSheet<int>(context, (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          final n = int.tryParse(ctrl.text) ?? 0;
          return SheetFrame(
            title: '영수증 금액',
            sub: '영수증에 적힌 결제 금액이에요. 상대방이 이 금액을 보고 물건값을 보내요.',
            bottom: BigButton(label: n > 0 ? '${nf(n)}원으로 올리기' : '금액을 적어 주세요', onTap: n > 0 ? () => Navigator.pop(ctx, n) : null),
            child: TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
              onChanged: (_) => setSheet(() {}),
              decoration: const InputDecoration(suffixText: '원', hintText: '예: 4500'),
            ),
          );
        },
      );
    });
    ctrl.dispose();
    return v;
  }

  Future<void> _add(String kind) async {
    if (sending) return;
    int? amount;
    if (kind == 'receipt') {
      amount = await _askAmount();
      if (amount == null) return;
    }
    if (!mounted) return;
    final PickedPhoto? photo;
    try {
      photo = await pickPhoto(context);
    } catch (_) {
      setState(() => note = '사진을 가져오지 못했어요. 카메라 · 사진 권한을 확인해 주세요.');
      return;
    }
    if (photo == null) return;
    setState(() {
      sending = true;
      note = null;
    });
    try {
      await repo.upload(uid: widget.myUid, bytes: photo.bytes, kind: kind, contentType: photo.contentType, amount: amount);
      note = kind == 'receipt' ? '영수증을 올렸어요. 상대방에게 알림이 가요.' : '사진을 올렸어요. 상대방에게 알림이 가요.';
    } on ServerException catch (e) {
      note = e.message;
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: '사진 · 영수증',
      bottom: widget.open
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: BigButton(label: '영수증 올리기', onTap: sending ? null : () => _add('receipt')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: BigButton(label: '완료 사진', bg: AppColors.page, onTap: sending ? null : () => _add('proof')),
                  ),
                ],
              ),
            )
          : null,
      child: StreamBuilder<List<TradePhoto>>(
        stream: stream,
        builder: (context, snap) {
          final list = snap.data ?? const <TradePhoto>[];
          final paid = list.where((p) => p.isReceipt).fold<int>(0, (s, p) => s + (p.amount ?? 0));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text(widget.title, style: AppType.section, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(
                '이 거래의 두 사람만 볼 수 있어요. 앱 안의 결제는 아직 없어서, 영수증 금액을 보고 물건값을 직접 보내 주세요.',
                style: AppType.meta.copyWith(fontSize: 12.5, height: 1.5),
              ),
              if (paid > 0)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(14)),
                  child: Text('영수증 합계 ${nf(paid)}원', style: AppType.price.copyWith(color: AppColors.yellowInk)),
                ),
              if (sending)
                const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator(minHeight: 3)),
              if (note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(note!, style: AppType.meta.copyWith(color: AppColors.ink2)),
                ),
              const SizedBox(height: 14),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    widget.open ? '아직 올린 사진이 없어요.\n구매했으면 영수증을, 전달했으면 완료 사진을 올려 주세요.' : '올린 사진이 없어요.',
                    textAlign: TextAlign.center,
                    style: AppType.meta.copyWith(fontSize: 13, height: 1.6),
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
                  children: [for (final p in list.reversed) _PhotoTile(photo: p, mine: p.uid == widget.myUid)],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PhotoTile extends StatefulWidget {
  final TradePhoto photo;
  final bool mine;
  const _PhotoTile({required this.photo, required this.mine});

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  late final Future<Uint8List?> bytes = PhotoRepository.load(widget.photo.path);

  @override
  Widget build(BuildContext context) {
    final p = widget.photo;
    final at = p.createdAt;
    final who = widget.mine ? '내가 올림' : (p.role == 'helper' ? '수행자' : '요청자');
    final label = p.isReceipt ? '영수증 ${nf(p.amount ?? 0)}원' : '완료 사진';
    return Semantics(
      button: true,
      label: '$label · $who',
      child: Container(
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FutureBuilder<Uint8List?>(
                future: bytes,
                builder: (context, snap) {
                  final data = snap.data;
                  if (snap.connectionState != ConnectionState.done) {
                    return const ColoredBox(color: AppColors.page, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                  }
                  if (data == null) {
                    return ColoredBox(
                      color: AppColors.page,
                      child: Center(child: Text('사진을 못 불러왔어요', style: AppType.meta)),
                    );
                  }
                  return InkWell(onTap: () => showPhotoViewer(context, data), child: Image.memory(data, fit: BoxFit.cover));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppType.body.copyWith(fontWeight: AppType.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    '$who · ${at.month}.${at.day} ${at.hour}:${at.minute.toString().padLeft(2, '0')}',
                    style: AppType.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
