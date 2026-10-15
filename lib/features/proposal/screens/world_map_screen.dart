import 'package:flutter/material.dart';

import '../../../app/neighbor_store.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../../../core/widgets/surface.dart';
import '../../community/models/com_post.dart';
import '../../errand/data/countries.dart';
import '../../errand/models/task_item.dart';
import '../models/proposal.dart';
import '../widgets/live_board.dart';

/// 세계 제안 지도 (시안 v43 `openWorld`).
///
/// 나라별로 '가는 김에 사다 드려요' 제안과 해외 부탁(요청)이 몇 건인지 점 지도에 찍는다.
/// 나라를 누르면 그 나라 제안·요청·이웃 이야기가 한 시트에 모인다.
class WorldMapScreen extends StatefulWidget {
  final NeighborStore store;
  final List<TaskItem> seaItems;
  final void Function(Proposal) onOpenProposal;
  final void Function(TaskItem) onOpenTask;
  final void Function(ComPost) onOpenPost;
  final VoidCallback onPropose;
  const WorldMapScreen({
    super.key,
    required this.store,
    required this.seaItems,
    required this.onOpenProposal,
    required this.onOpenTask,
    required this.onOpenPost,
    required this.onPropose,
  });

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

/// 나라 대표 좌표 (경도, 위도)
const _pins = <String, (double, double)>{
  'jp': (138, 36),
  'us': (-110, 38),
  'gb': (-2, 53),
  'vn': (106, 15),
  'tw': (121, 24),
  'cn': (110, 35),
  'th': (101, 15),
  'fr': (2, 46),
  'sg': (104, 1),
  'au': (134, -25),
  'ca': (-100, 56),
  'de': (10, 51),
  'it': (12, 43),
  'es': (-4, 40),
  'ph': (122, 12),
  'id': (115, -3),
  'my': (102, 4),
  'hk': (114, 22),
  'ch': (8, 47),
  'ae': (54, 24),
};

class _WorldMapScreenState extends State<WorldMapScreen> {
  String? focus;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final props = widget.store.board(abroad: true);
        final stats = <String, ({int props, int asks})>{};
        for (final c in _pins.keys) {
          final p = props.where((x) => x.cc == c).length;
          final a = widget.seaItems.where((x) => x.cc == c).length;
          if (p + a > 0) stats[c] = (props: p, asks: a);
        }
        final order = stats.keys.toList()
          ..sort((a, b) => (stats[b]!.props + stats[b]!.asks) - (stats[a]!.props + stats[a]!.asks));
        final totalP = props.length;
        final totalA = widget.seaItems.length;

        return PageFrame(
          title: '세계 제안 지도',
          bottom: BigButton(label: '내가 가는 길에 제안하기', icon: 'plus', bg: AppColors.ink, fg: Colors.white, onTap: widget.onPropose),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                decoration: BoxDecoration(color: const Color(0xFF1C2330), borderRadius: BorderRadius.circular(20)),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 1.7,
                  child: InteractiveViewer(
                    maxScale: 4,
                    child: LayoutBuilder(
                      builder: (context, box) {
                        return Stack(
                          children: [
                            Positioned.fill(child: CustomPaint(painter: _DotWorld())),
                            for (final c in order) _pin(box.biggest, c, stats[c]!.props + stats[c]!.asks),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                child: Text(
                  '지금 제안 $totalP건 · 요청 $totalA건 · 나라를 누르거나 두 손가락으로 확대해 보세요',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.5),
                ),
              ),
              SecCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (final c in order)
                      Tap(
                        onTap: () => _openCountry(c),
                        radius: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              CodeBox(c.toUpperCase(), bg: AppColors.redSoft, fg: AppColors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(countryOf(c).name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              ),
                              Text(
                                '제안 ${stats[c]!.props} · 요청 ${stats[c]!.asks}',
                                style: const TextStyle(fontSize: 13, color: AppColors.sub),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pin(Size size, String cc, int n) {
    final (lon, lat) = _pins[cc]!;
    final x = (lon + 180) / 360 * size.width;
    final y = (80 - lat) / 140 * size.height;
    final on = focus == cc;
    return Positioned(
      left: x - 14,
      top: y - 14,
      child: GestureDetector(
        onTap: () {
          setState(() => focus = cc);
          _openCountry(cc);
        },
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Colors.white : AppColors.yellow,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Color(0x66FFCD1F), blurRadius: 10)],
          ),
          child: Text(
            '$n',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink),
          ),
        ),
      ),
    );
  }

  /// 나라 시트 — 그 나라 제안 · 요청 · 이웃 이야기
  void _openCountry(String cc) {
    final country = countryOf(cc);
    showSheet(context, (ctx) {
      return ListenableBuilder(
        listenable: widget.store,
        builder: (ctx, _) {
          final props = widget.store.board(abroad: true).where((p) => p.cc == cc).toList();
          final asks = widget.seaItems.where((t) => t.cc == cc).toList();
          final stories = widget.store.postsOf('abroad').where((p) => p.place == cc).take(3).toList();
          return SheetFrame(
            title: country.name,
            sub: '제안 ${props.length}건 · 요청 ${asks.length}건',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (props.isNotEmpty) ...[
                  const Text(
                    '가는 김에 사다 드려요',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sub),
                  ),
                  const SizedBox(height: 8),
                  for (final p in props) ...[
                    ProposalRow(
                      p: p,
                      meJoined: widget.store.joined.contains(p.id),
                      bg: AppColors.page,
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onOpenProposal(p);
                      },
                    ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: 10),
                ],
                if (asks.isNotEmpty) ...[
                  const Text(
                    '이 나라 부탁',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sub),
                  ),
                  for (final t in asks)
                    Tap(
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onOpenTask(t);
                      },
                      radius: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.line)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(won(t.price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                ],
                Text(
                  '${country.name} 이웃 이야기',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sub),
                ),
                if (stories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('아직 이야기가 없어요', style: TextStyle(color: AppColors.faint)),
                  ),
                for (final s in stories)
                  Tap(
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onOpenPost(s);
                    },
                    radius: 8,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          StatusBadge(s.kind, bg: kindTone(s.kind).bg, fg: kindTone(s.kind).fg),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    });
  }
}

/// 점으로 찍은 세계 지도. 대륙 윤곽을 위도·경도 범위로 거칠게 잡았다.
class _DotWorld extends CustomPainter {
  static bool _land(double lon, double lat) {
    bool between(double v, double a, double b) => v >= a && v <= b;
    // 북아메리카 · 그린란드
    if (lat > 50 && lat < 72 && between(lon, -165, -60)) return true;
    if (between(lat, 30, 50) && between(lon, -125, -66)) return true;
    if (between(lat, 15, 30) && between(lon, -112, -82)) return true;
    if (between(lat, 60, 82) && between(lon, -55, -20)) return true;
    // 남아메리카
    if (between(lat, 0, 12) && between(lon, -80, -50)) return true;
    if (between(lat, -20, 0) && between(lon, -80, -36)) return true;
    if (between(lat, -40, -20) && between(lon, -72, -45)) return true;
    if (between(lat, -55, -40) && between(lon, -75, -65)) return true;
    // 유럽
    if (between(lat, 36, 70) && between(lon, -10, 40)) return true;
    // 아프리카
    if (between(lat, 15, 35) && between(lon, -17, 35)) return true;
    if (between(lat, 5, 15) && between(lon, -17, 50)) return true;
    if (between(lat, 0, 5) && between(lon, 8, 45)) return true;
    if (between(lat, -35, 0) && between(lon, 12, 42)) return true;
    // 아시아
    if (between(lat, 50, 75) && between(lon, 40, 180)) return true;
    if (between(lat, 25, 50) && between(lon, 40, 122)) return true;
    if (between(lat, 31, 45) && between(lon, 129, 145)) return true;
    if (between(lat, 8, 25) && between(lon, 68, 90)) return true;
    if (between(lat, 5, 25) && between(lon, 95, 110)) return true;
    if (between(lat, 12, 30) && between(lon, 40, 58)) return true;
    // 동남아 섬 · 오세아니아
    if (between(lat, -10, 5) && between(lon, 95, 140)) return true;
    if (between(lat, -40, -12) && between(lon, 114, 153)) return true;
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 72, rows = 34;
    final dx = size.width / cols, dy = size.height / rows;
    final dot = Paint()..color = const Color(0x33FFFFFF);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final lon = -180 + (c + 0.5) * 360 / cols;
        final lat = 80 - (r + 0.5) * 140 / rows;
        if (_land(lon, lat)) canvas.drawCircle(Offset((c + 0.5) * dx, (r + 0.5) * dy), dx * 0.28, dot);
      }
    }
    // 한국
    final kx = (127 + 180) / 360 * size.width, ky = (80 - 37) / 140 * size.height;
    canvas.drawCircle(Offset(kx, ky), 4, Paint()..color = AppColors.blue);
  }

  @override
  bool shouldRepaint(_DotWorld old) => false;
}
