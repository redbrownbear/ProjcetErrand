import 'package:flutter/material.dart';

void main() => runApp(const PumApp());

class PumApp extends StatelessWidget {
  const PumApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '품',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: AppColors.page),
      home: const HomeShell(),
    );
  }
}

class AppColors {
  static const page = Color(0xFFF3F3F5);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF191A1C);
  static const sub = Color(0xFF9296A0);
  static const line = Color(0xFFECECEF);
  static const yellow = Color(0xFFFFD429);
  static const yellowSoft = Color(0xFFFFF3C7);
  static const blue = Color(0xFF3D6DE8);
  static const blueSoft = Color(0xFFDEE8FF);
  static const gray = Color(0xFFE9E9EE);
  static const green = Color(0xFF22B573);
  static const greenSoft = Color(0xFFDCF3E8);
  static const hot = Color(0xFFFF4D4F);
  static const black = Color(0xFF191A1C);
}

class Cat {
  final String k, label, icon, tone;
  const Cat(this.k, this.label, this.icon, this.tone);
}

const cats = [
  Cat('line', '줄서기', '🧍', 'ask'),
  Cat('buy', '사오기', '🛍️', 'ask'),
  Cat('pickup', '받아오기', '📦', 'ask'),
  Cat('photo', '사진', '📸', 'ask'),
  Cat('ticket', '티켓·굿즈', '🎫', 'ask'),
  Cat('move', '운반', '🚚', 'ask'),
  Cat('clean', '청소', '🧹', 'ask'),
  Cat('pet', '반려동물', '🐕', 'ask'),
  Cat('carpool', '카풀', '🚗', 'ask'),
  Cat('rent', '빌려주기', '🔑', 'ask'),
  Cat('assemble', '조립·설치', '🔧', 'ask'),
  Cat('study', '과외·레슨', '📚', 'ask'),
  Cat('share', '나눔', '🎁', 'share'),
  Cat('movie', '영화', '🎬', 'together'),
  Cat('meal', '밥친구', '🍜', 'together'),
  Cat('run', '러닝메이트', '🏃', 'together'),
];

Cat? catOf(String k) {
  for (final c in cats) {
    if (c.k == k) return c;
  }
  return null;
}

class TaskItem {
  final int id;
  final String mode, cat, title, place, who, gender;
  final double dist, temp, x, y;
  final int mins, price, age;
  final bool hot;
  final String desc;
  final String? extra;
  const TaskItem({
    required this.id, required this.mode, required this.cat, required this.title,
    required this.place, required this.dist, required this.mins, required this.price,
    required this.who, required this.gender, required this.age, required this.temp,
    required this.hot, required this.x, required this.y, required this.desc, this.extra,
  });
}

const items = [
  TaskItem(id: 1, mode: 'ask', cat: 'buy', title: '성심당 빵 대신 사다주기', place: '역삼동', dist: 0.42, mins: 25, price: 12000, who: '복숭아언니', gender: '여', age: 30, temp: 41.2, hot: false, x: 34, y: 30, desc: '성심당 튀김소보로 6개, 판당고 2개 사서 역삼동 카페 앞으로 전달 부탁드려요. 빵값은 앱에서 같이 결제돼요.'),
  TaskItem(id: 2, mode: 'ask', cat: 'line', title: '성수 팝업 줄 40분만 대신 서주기', place: '성수동', dist: 1.1, mins: 40, price: 18000, who: '지금바로', gender: '남', age: 27, temp: 38.5, hot: true, x: 66, y: 22, desc: '디올 팝업 오픈런 줄서기예요. 제가 도착하면 교대해요. 지금 바로 가능한 분! 급해서 HOT 걸었어요.'),
  TaskItem(id: 3, mode: 'ask', cat: 'photo', title: '매장 재고 사진 찍어 보내주기', place: '서초동', dist: 0.3, mins: 10, price: 5000, who: '재고확인', gender: '여', age: 34, temp: 40.0, hot: false, x: 48, y: 46, desc: '나이키 서초점에 특정 신발 재고 있는지 사진으로 확인 부탁해요. 사이즈 270.'),
  TaskItem(id: 4, mode: 'ask', cat: 'pickup', title: '카페 픽업해서 사무실 전달', place: '강남역', dist: 0.55, mins: 15, price: 7000, who: '3층직장인', gender: '남', age: 41, temp: 39.1, hot: false, x: 40, y: 62, desc: '블루보틀 커피 4잔 픽업 후 강남역 오피스 3층으로 전달해주세요.'),
  TaskItem(id: 5, mode: 'ask', cat: 'carpool', title: '내일 아침 판교까지 카풀 (1인)', place: '양재 → 판교', dist: 0.8, mins: 30, price: 6000, who: '출근메이트', gender: '여', age: 33, temp: 42.0, hot: false, x: 72, y: 58, desc: '평일 매일 아침 8시 양재역 출발, 판교 도착. 정기로도 가능해요. 커피값 정도만 받아요.'),
  TaskItem(id: 6, mode: 'ask', cat: 'rent', title: '캠핑 테이블 하루 빌려드려요', place: '반포동', dist: 0.5, mins: 0, price: 8000, who: '장비수집가', gender: '남', age: 38, temp: 43.5, hot: false, x: 30, y: 40, desc: '코베아 롤테이블, 상태 좋아요. 보증금 별도, 앱에서 안전하게 처리돼요.'),
  TaskItem(id: 7, mode: 'share', cat: 'share', title: '이사 정리 중 · 책장 무료 나눔', place: '서초동', dist: 0.35, mins: 0, price: 0, who: '이사2일차', gender: '여', age: 29, temp: 40.8, hot: false, x: 54, y: 36, desc: '3단 책장 상태 양호. 직접 가지러 오실 분! 먼저 오케이한 분께 드려요.'),
  TaskItem(id: 8, mode: 'together', cat: 'movie', title: '오늘 9시 영화 같이 볼 사람?', place: '메가박스 강남', dist: 0, mins: 0, price: 0, who: '혼영탈출', gender: '여', age: 26, temp: 44.1, hot: false, x: 26, y: 74, desc: 'F1 영화 예매했는데 같이 볼 분 구해요. 20대 인증 우대, 끝나고 가볍게 커피도 좋아요.', extra: '관심 8명 · 2자리 남음'),
  TaskItem(id: 9, mode: 'together', cat: 'meal', title: '혼밥 말고 같이 저녁 (부담 X)', place: '서초 골목', dist: 0, mins: 0, price: 0, who: '저녁친구', gender: '남', age: 31, temp: 39.4, hot: false, x: 58, y: 78, desc: '서초동 국밥집 같이 가실 분. 그냥 밥만 먹고 헤어져도 됩니다.', extra: '관심 3명'),
];

String _comma(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return (n < 0 ? '-' : '') + buf.toString();
}

String won(int n) => '${_comma(n)}원';

String _fmtDist(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toString();

String km(double d) {
  if (d == 0) return '무료';
  if (d < 1) return '${(d * 1000).round()}m';
  return '${_fmtDist(d)}km';
}

class Filters {
  int maxPrice;
  double maxDist;
  String gender;
  int ageMin, ageMax;
  Filters({this.maxPrice = 30000, this.maxDist = 2, this.gender = 'all', this.ageMin = 20, this.ageMax = 60});
  Filters copy() => Filters(maxPrice: maxPrice, maxDist: maxDist, gender: gender, ageMin: ageMin, ageMax: ageMax);
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  String nav = 'home';
  String mode = 'home';
  TaskItem? detail;
  Map<int, String> status = {};
  String? toast;
  bool filterOpen = false;
  bool sortPrice = false;
  Filters flt = Filters();

  void apply(TaskItem it) {
    setState(() {
      status[it.id] = 'pending';
      detail = null;
      toast = '신청했어요! 상대가 수락하면 매칭돼요';
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        status[it.id] = 'matched';
        toast = '${it.who} 님이 수락했어요! 채팅으로 이어져요';
      });
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => toast = null);
      });
    });
  }

  Widget _navBody() {
    switch (nav) {
      case 'map':
        return MapView(status: status, onOpenDetail: (it) => setState(() => detail = it));
      case 'chat':
        return ChatView(status: status);
      case 'me':
        return const MeView();
      default:
        return HomeContent(
          mode: mode,
          setMode: (m) => setState(() => mode = mode == m ? 'home' : m),
          status: status,
          onApply: apply,
          onOpenDetail: (it) => setState(() => detail = it),
          sortPrice: sortPrice,
          setSortPrice: (v) => setState(() => sortPrice = v),
          openFilter: () => setState(() => filterOpen = true),
          flt: flt,
          goMap: () => setState(() => nav = 'map'),
        );
    }
  }

  Widget _bottomNav() {
    final tabs = [
      ['home', '홈', '🏠'],
      ['map', '지도', '🗺️'],
      ['chat', '채팅', '💬'],
      ['me', '내정보', '👤'],
    ];
    return Container(
      decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: tabs.map((t) {
          final k = t[0], label = t[1], icon = t[2];
          final active = nav == k;
          final badge = k == 'chat' ? status.values.where((v) => v == 'pending' || v == 'matched').length : 0;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() {
                nav = k;
                if (k == 'home') mode = 'home';
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(clipBehavior: Clip.none, children: [
                      Opacity(opacity: active ? 1 : 0.55, child: Text(icon, style: const TextStyle(fontSize: 20))),
                      if (badge > 0)
                        Positioned(
                          right: -10,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.hot, borderRadius: BorderRadius.circular(99)),
                            child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 2),
                    Text(label, style: TextStyle(fontSize: 11, color: active ? AppColors.ink : AppColors.sub, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Stack(
          children: [
            Column(children: [Expanded(child: _navBody()), _bottomNav()]),
            if (toast != null)
              Positioned(
                left: 20,
                right: 20,
                bottom: 78,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                    decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(14)),
                    child: Text(toast!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            if (detail != null)
              DetailPage(item: detail!, status: status[detail!.id], onClose: () => setState(() => detail = null), onApply: apply),
            if (filterOpen)
              FilterSheet(
                flt: flt,
                onClose: () => setState(() => filterOpen = false),
                onApplyFilters: (f) => setState(() {
                  flt = f;
                  filterOpen = false;
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final String mode;
  final void Function(String) setMode;
  final Map<int, String> status;
  final void Function(TaskItem) onApply;
  final void Function(TaskItem) onOpenDetail;
  final bool sortPrice;
  final void Function(bool) setSortPrice;
  final VoidCallback openFilter;
  final Filters flt;
  final VoidCallback goMap;

  const HomeContent({
    super.key, required this.mode, required this.setMode, required this.status, required this.onApply,
    required this.onOpenDetail, required this.sortPrice, required this.setSortPrice, required this.openFilter,
    required this.flt, required this.goMap,
  });

  @override
  Widget build(BuildContext context) {
    var feed = items.where((i) {
      if (mode == 'ask' || mode == 'earn') return i.mode == 'ask';
      if (mode == 'together') return i.mode == 'together';
      if (mode == 'share') return i.mode == 'share';
      return i.mode == 'ask';
    }).toList();

    if (mode != 'together' && mode != 'share') {
      feed = feed.where((i) => i.price <= flt.maxPrice && i.dist <= flt.maxDist && (flt.gender == 'all' || i.gender == flt.gender) && i.age >= flt.ageMin && i.age <= flt.ageMax).toList();
    }
    feed.sort((a, b) {
      final h = (b.hot ? 1 : 0) - (a.hot ? 1 : 0);
      if (h != 0) return h;
      return sortPrice ? b.price - a.price : 0;
    });

    final free = items.where((i) => i.mode == 'together').toList();
    final shares = items.where((i) => i.mode == 'share').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: const [
                  Text('서초구 서초동', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  SizedBox(width: 4),
                  Text('▾', style: TextStyle(color: AppColors.sub, fontSize: 12)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(99)),
                  child: const Text('3,200P', style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w800, fontSize: 12.5)),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 2, 20, 12),
            child: Text('오늘 뭐 할까?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink)),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
            child: const Text('🔍 줄서기, 카풀, 나눔, 영화 같이…', style: TextStyle(color: AppColors.sub, fontSize: 13.5)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(children: [
              ModeCard(active: mode == 'ask', onTap: () => setMode('ask'), bg: AppColors.yellow, title: '부탁해요', tcol: AppColors.ink),
              const SizedBox(width: 8),
              ModeCard(active: mode == 'together', onTap: () => setMode('together'), bg: AppColors.gray, title: '같이해요', tcol: AppColors.ink),
              const SizedBox(width: 8),
              ModeCard(active: mode == 'share', onTap: () => setMode('share'), bg: AppColors.greenSoft, title: '나눔', tcol: AppColors.green),
              const SizedBox(width: 8),
              ModeCard(active: mode == 'earn', onTap: () => setMode('earn'), bg: AppColors.blueSoft, title: '돈벌기', tcol: AppColors.blue),
            ]),
          ),
          if (mode == 'earn') EarnView(onOpenDetail: onOpenDetail, status: status, onApply: onApply),
          if (mode != 'earn') ...[
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              padding: const EdgeInsets.fromLTRB(6, 14, 6, 10),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                children: cats.map((c) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42, height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.tone == 'together' ? AppColors.gray : c.tone == 'share' ? AppColors.greenSoft : AppColors.yellowSoft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(c.icon, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(height: 5),
                    Text(c.label, style: const TextStyle(fontSize: 10.5, color: AppColors.ink, fontWeight: FontWeight.w500)),
                  ],
                )).toList(),
              ),
            ),
            if (mode == 'home' || mode == 'ask') ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('내 주변 지금 뜬 일', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
                    TextButton(onPressed: goMap, child: const Text('지도 보기 ›', style: TextStyle(color: AppColors.sub, fontSize: 12.5))),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  children: [
                    ChipWidget(label: '💰 높은 금액순', active: sortPrice, onTap: () => setSortPrice(!sortPrice)),
                    const SizedBox(width: 7),
                    ChipWidget(label: '⚙️ 필터', onTap: openFilter),
                    const SizedBox(width: 7),
                    const ChipWidget(label: '🔥 급한 일만'),
                    const SizedBox(width: 7),
                    const ChipWidget(label: '📍 가까운 순'),
                  ],
                ),
              ),
              if (feed.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: Text('조건에 맞는 일이 없어요. 필터를 넓혀보세요.', style: TextStyle(color: AppColors.sub, fontSize: 13))),
                )
              else
                ...feed.map((it) => TaskCard(it: it, onOpen: () => onOpenDetail(it), onApply: () => onApply(it), st: status[it.id])),
            ],
            if (mode == 'home' || mode == 'together') ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Text('같이할 사람', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
              ),
              if (mode == 'together')
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(12)),
                  child: const Text('🛡 본인인증한 이웃만 · 공개 장소 · 미성년자 보호', style: TextStyle(fontSize: 12, color: Color(0xFF1B8A5A), fontWeight: FontWeight.w600)),
                ),
              ...free.map((it) => TaskCard(it: it, onOpen: () => onOpenDetail(it), onApply: () => onApply(it), st: status[it.id])),
            ],
            if (mode == 'home' || mode == 'share') ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Text('이웃 나눔 🎁', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
              ),
              ...shares.map((it) => TaskCard(it: it, onOpen: () => onOpenDetail(it), onApply: () => onApply(it), st: status[it.id])),
            ],
            if (mode == 'home')
              Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () => setMode('earn'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('오늘 근처에서\n벌 수 있는 예상 금액', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
                      Text('68,000원', style: TextStyle(color: AppColors.yellow, fontSize: 24, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class ModeCard extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  final Color bg, tcol;
  final String title;
  const ModeCard({super.key, required this.active, required this.onTap, required this.bg, required this.title, required this.tcol});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: active ? AppColors.ink : Colors.transparent, width: 2.5),
          ),
          child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: tcol)),
        ),
      ),
    );
  }
}

class ChipWidget extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const ChipWidget({super.key, required this.label, this.active = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : AppColors.card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: active ? AppColors.ink : AppColors.line),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.ink, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen, onApply;
  final String? st;
  const TaskCard({super.key, required this.it, required this.onOpen, required this.onApply, this.st});
  @override
  Widget build(BuildContext context) {
    final paid = it.mode == 'ask';
    final free = it.mode == 'together';
    final share = it.mode == 'share';
    final c = catOf(it.cat);
    return InkWell(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 11),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: it.hot ? AppColors.hot : Colors.transparent, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 46, height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: free ? AppColors.gray : share ? AppColors.greenSoft : AppColors.yellowSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(c?.icon ?? '🙌', style: const TextStyle(fontSize: 23)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      if (it.hot)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.hot, borderRadius: BorderRadius.circular(6)),
                          child: const Text('🔥 HOT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      Expanded(child: Text(it.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
                    ]),
                    const SizedBox(height: 4),
                    Text('${km(it.dist)}${paid ? ' · 약 ${it.mins}분' : ''} · ${it.place} · ${it.who}', style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
                    if ((free || share) && it.extra != null)
                      Padding(padding: const EdgeInsets.only(top: 3), child: Text(it.extra!, style: const TextStyle(fontSize: 11.5, color: AppColors.blue, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  share ? '무료 나눔' : paid ? won(it.price) : '사례 없음',
                  style: TextStyle(fontSize: paid ? 18 : 14, fontWeight: FontWeight.w900, color: share ? AppColors.green : AppColors.ink),
                ),
                StatusBtn(st: st, paid: paid, onApply: onApply),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBtn extends StatelessWidget {
  final String? st;
  final bool paid;
  final VoidCallback onApply;
  const StatusBtn({super.key, this.st, required this.paid, required this.onApply});
  @override
  Widget build(BuildContext context) {
    if (st == 'pending') {
      return _pill('매칭 중…', AppColors.yellowSoft, const Color(0xFFB8860B));
    }
    if (st == 'matched') {
      return _pill('매칭 완료 ✓', AppColors.greenSoft, const Color(0xFF1B8A5A));
    }
    return ElevatedButton(
      onPressed: onApply,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        elevation: 0,
      ),
      child: Text(paid ? '신청하기' : '같이 신청', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }

  Widget _pill(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
        child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12.5)),
      );
}

class EarnView extends StatelessWidget {
  final void Function(TaskItem) onOpenDetail;
  final void Function(TaskItem) onApply;
  final Map<int, String> status;
  const EarnView({super.key, required this.onOpenDetail, required this.onApply, required this.status});
  @override
  Widget build(BuildContext context) {
    final bundle = [items[1], items[3], items[2]];
    final total = bundle.fold<int>(0, (s, i) => s + i.price);
    final mins = bundle.fold<int>(0, (s, i) => s + i.mins);
    final asks = items.where((i) => i.mode == 'ask').toList()..sort((a, b) => (b.hot ? 1 : 0) - (a.hot ? 1 : 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('오늘 내 주변 예상 수익', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              const SizedBox(height: 4),
              const Text('68,000원', style: TextStyle(color: AppColors.yellow, fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('🔥 HOT 1건 포함 · 지금 잡을 수 있는 일 기준', style: TextStyle(color: Colors.white54, fontSize: 11.5)),
            ],
          ),
        ),
        const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('🔗 이 동선으로 묶어봤어요', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink))),
        const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 10), child: Text('가까운 일을 한 번에 돌면 이동시간이 줄어요', style: TextStyle(fontSize: 12, color: AppColors.sub))),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.blueSoft, width: 1.5)),
          child: Column(
            children: [
              for (int i = 0; i < bundle.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i < bundle.length - 1 ? 12 : 0),
                  child: Row(children: [
                    Column(children: [
                      Container(
                        width: 26, height: 26, alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                        child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                      if (i < bundle.length - 1) Container(width: 2, height: 22, color: AppColors.blueSoft, margin: const EdgeInsets.only(top: 2)),
                    ]),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bundle[i].title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          Text('${bundle[i].place} · ${km(bundle[i].dist)} · ${bundle[i].mins}분', style: const TextStyle(fontSize: 11, color: AppColors.sub)),
                        ],
                      ),
                    ),
                    Text(won(bundle[i].price), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ]),
                ),
              Container(
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line, width: 1))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('총 ${mins ~/ 60}시간 ${mins % 60}분 예상', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                    Text(won(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.blue)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => bundle.forEach(onApply),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    elevation: 0,
                  ),
                  child: const Text('이 동선 한 번에 신청', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                ),
              ),
            ],
          ),
        ),
        const Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, 8), child: Text('낱개로 잡기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink))),
        ...asks.map((it) => TaskCard(it: it, onOpen: () => onOpenDetail(it), onApply: () => onApply(it), st: status[it.id])),
      ],
    );
  }
}

class MapView extends StatefulWidget {
  final Map<int, String> status;
  final void Function(TaskItem) onOpenDetail;
  const MapView({super.key, required this.status, required this.onOpenDetail});
  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  String filter = 'all';
  @override
  Widget build(BuildContext context) {
    final pins = items.where((i) => filter == 'all' ? true : filter == 'hot' ? i.hot : i.mode == filter).toList();
    return Stack(children: [
      Container(color: const Color(0xFFE7ECE4)),
      Positioned.fill(
        child: LayoutBuilder(builder: (context, box) {
          return Stack(children: [
            Positioned(left: box.maxWidth * .5, top: box.maxHeight * .35, child: Container(width: box.maxWidth * .25, height: 90, decoration: BoxDecoration(color: const Color(0xFFCDE6CD), shape: BoxShape.circle))),
            Positioned(left: box.maxWidth * .05, top: 30, child: Container(width: box.maxWidth * .35, height: 120, decoration: BoxDecoration(color: const Color(0xFFDDE4D6), borderRadius: BorderRadius.circular(6)))),
            Positioned(right: box.maxWidth * .05, top: 60, child: Container(width: box.maxWidth * .35, height: 100, decoration: BoxDecoration(color: const Color(0xFFDDE4D6), borderRadius: BorderRadius.circular(6)))),
            Positioned(left: box.maxWidth * .1, bottom: 60, child: Container(width: box.maxWidth * .3, height: 140, decoration: BoxDecoration(color: const Color(0xFFDDE4D6), borderRadius: BorderRadius.circular(6)))),
            Positioned(left: box.maxWidth * .5, top: box.maxHeight * .44 - 20, child: Container(
              width: 40, height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
              child: Container(width: 16, height: 16, decoration: BoxDecoration(color: AppColors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3))),
            )),
            for (final it in pins)
              Positioned(
                left: box.maxWidth * (it.x / 100) - 24,
                top: box.maxHeight * (it.y / 100) - 40,
                child: _Pin(it: it, status: widget.status[it.id], onTap: () => widget.onOpenDetail(it)),
              ),
          ]);
        }),
      ),
      Positioned(
        top: 14, left: 14, right: 14,
        child: SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final e in [['all', '전체'], ['hot', '🔥 급한 일'], ['ask', '부탁'], ['together', '같이'], ['share', '나눔']])
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: InkWell(
                    onTap: () => setState(() => filter = e[0]),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: filter == e[0] ? AppColors.black : Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 8)],
                      ),
                      child: Text(e[1], style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: filter == e[0] ? Colors.white : AppColors.ink)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      Positioned(
        bottom: 16, left: 14, right: 14,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 16)]),
          child: const Text('핀을 눌러 자세히 · 🔥빨강=급한 일, 검정=부탁, 초록=나눔', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.sub)),
        ),
      ),
    ]);
  }
}

class _Pin extends StatelessWidget {
  final TaskItem it;
  final String? status;
  final VoidCallback onTap;
  const _Pin({required this.it, required this.status, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final paid = it.mode == 'ask';
    final share = it.mode == 'share';
    final bg = status == 'matched' ? AppColors.green : it.hot ? AppColors.hot : paid ? AppColors.black : share ? AppColors.green : AppColors.card;
    final fg = share || it.hot || paid || status != null ? Colors.white : AppColors.ink;
    final label = status == 'matched' ? '완료' : it.hot ? '🔥${(it.price / 1000).round()}천' : paid ? '${(it.price / 1000).round()}천원' : share ? '나눔' : '같이';
    return InkWell(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12),
            border: (!paid && !share && !it.hot && status == null) ? Border.all(color: AppColors.line, width: 1.5) : null,
            boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
        CustomPaint(size: const Size(12, 7), painter: _TrianglePainter(bg)),
      ]),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()..moveTo(0, 0)..lineTo(size.width, 0)..lineTo(size.width / 2, size.height)..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}

class ChatView extends StatelessWidget {
  final Map<int, String> status;
  const ChatView({super.key, required this.status});
  @override
  Widget build(BuildContext context) {
    final rows = items.where((i) => status.containsKey(i.id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 18, 20, 12), child: Text('채팅', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink))),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 90),
            child: Center(child: Text('아직 이어진 이웃이 없어요.\n신청하면 여기서 매칭 상태를 볼 수 있어요.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.sub, fontSize: 13.5, height: 1.7))),
          ),
        Expanded(
          child: ListView(
            children: rows.map((it) {
              final pending = status[it.id] == 'pending';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                child: Row(children: [
                  Container(
                    width: 46, height: 46, alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.yellowSoft, shape: BoxShape.circle),
                    child: Text(catOf(it.cat)?.icon ?? '🙌', style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(it.who, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: pending ? AppColors.yellowSoft : AppColors.greenSoft, borderRadius: BorderRadius.circular(6)),
                            child: Text(pending ? '매칭 중' : '매칭 완료', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: pending ? const Color(0xFFB8860B) : const Color(0xFF1B8A5A))),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        Text(pending ? '상대의 수락을 기다리는 중…' : '이제 시간·장소를 정해요', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                      ],
                    ),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class MeView extends StatelessWidget {
  const MeView({super.key});
  @override
  Widget build(BuildContext context) {
    final rows = [
      ['🛡', '안전 · 본인인증', '인증 완료'],
      ['📍', '위치 노출 범위', '동 단위'],
      ['🚻', '매칭 성별 설정', '제한 없음'],
      ['🚫', '차단한 이웃', '0명'],
      ['⭐', '받은 후기', '4.9 (11)'],
    ];
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(children: [
            Container(
              width: 58, height: 58, alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.yellowSoft, shape: BoxShape.circle),
              child: const Text('🌱', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('새싹 이웃님', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
                Text('서초동 · 품온도 40.6℃', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
              ],
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('이번 달 번 돈', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('420,000원', style: TextStyle(color: AppColors.yellow, fontSize: 22, fontWeight: FontWeight.w900)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('완료', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('6건', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              ]),
            ],
          ),
        ),
        for (final r in rows)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Row(children: [
              Text(r[0], style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text(r[1], style: const TextStyle(fontSize: 14, color: AppColors.ink))),
              Text('${r[2]} ›', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
            ]),
          ),
      ],
    );
  }
}

class DetailPage extends StatelessWidget {
  final TaskItem item;
  final String? status;
  final VoidCallback onClose;
  final void Function(TaskItem) onApply;
  const DetailPage({super.key, required this.item, required this.status, required this.onClose, required this.onApply});
  @override
  Widget build(BuildContext context) {
    final paid = item.mode == 'ask';
    final free = item.mode == 'together';
    final share = item.mode == 'share';
    final c = catOf(item.cat);
    return Positioned.fill(
      child: Material(
        color: AppColors.page,
        child: Column(children: [
          Container(
            height: 150,
            width: double.infinity,
            alignment: Alignment.center,
            color: free ? AppColors.gray : share ? AppColors.greenSoft : AppColors.yellowSoft,
            child: Stack(children: [
              Center(child: Text(c?.icon ?? '🙌', style: const TextStyle(fontSize: 56))),
              Positioned(
                top: 16, left: 16,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    width: 36, height: 36, alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), shape: BoxShape.circle),
                    child: const Text('‹', style: TextStyle(fontSize: 17)),
                  ),
                ),
              ),
              if (item.hot)
                Positioned(
                  top: 18, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.hot, borderRadius: BorderRadius.circular(8)),
                    child: const Text('🔥 급한 일 · 최상단 노출', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: share ? AppColors.greenSoft : paid ? AppColors.yellowSoft : AppColors.blueSoft, borderRadius: BorderRadius.circular(8)),
                    child: Text(share ? '나눔' : paid ? (catOf(item.cat)?.label ?? '') : '같이해요', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: share ? AppColors.green : paid ? AppColors.ink : AppColors.blue)),
                  ),
                  Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.35)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line), bottom: BorderSide(color: AppColors.line))),
                    child: Row(children: [
                      Container(width: 42, height: 42, alignment: Alignment.center, decoration: const BoxDecoration(color: AppColors.greenSoft, shape: BoxShape.circle), child: const Text('🌱', style: TextStyle(fontSize: 20))),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.who, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                            Text('${item.gender} · ${item.age}대 인증 · 품온도 ${item.temp}℃', style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                          ],
                        ),
                      ),
                      const Text('🛡 본인인증', style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10, crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    children: [
                      _Info(label: '거리', v: km(item.dist)),
                      _Info(label: paid ? '예상 소요' : '형태', v: paid ? '약 ${item.mins}분' : (free ? '동행' : '직접 수령')),
                      _Info(label: '위치', v: item.place),
                      _Info(label: share ? '' : '사례비', v: share ? '무료 나눔' : paid ? won(item.price) : '사례 없음'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('상세 내용', style: TextStyle(fontSize: 13, color: AppColors.sub, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(item.desc, style: const TextStyle(fontSize: 14, color: AppColors.ink, height: 1.7)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🛡 안전 안내', style: TextStyle(fontSize: 11.5, color: AppColors.sub, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 7),
                        Text(
                          '· 공개된 장소에서 만나요\n· 매칭 후 실시간 위치가 공유돼요\n· 언제든 신고·차단할 수 있어요${!paid ? '\n· 본인인증한 이웃만 신청돼요' : ''}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.ink, height: 1.65),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
            child: Column(children: [
              if (status == 'pending')
                Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(14)),
                  child: const Text('매칭 중… 상대의 수락을 기다려요', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFB8860B), fontWeight: FontWeight.w800, fontSize: 15)),
                )
              else if (status == 'matched')
                Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(14)),
                  child: const Text('매칭 완료! 채팅에서 이어가요 ✓', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF1B8A5A), fontWeight: FontWeight.w800, fontSize: 15)),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onApply(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(share ? '이거 받고 싶어요' : paid ? '신청하기' : '같이 신청하기', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              const SizedBox(height: 8),
              const Text('신청하면 상대가 수락해야 매칭돼요', style: TextStyle(fontSize: 11, color: AppColors.sub)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label, v;
  const _Info({required this.label, required this.v});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.sub)),
          const SizedBox(height: 3),
          Text(v, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
        ],
      ),
    );
  }
}

class FilterSheet extends StatefulWidget {
  final Filters flt;
  final VoidCallback onClose;
  final void Function(Filters) onApplyFilters;
  const FilterSheet({super.key, required this.flt, required this.onClose, required this.onApplyFilters});
  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Filters f;
  @override
  void initState() {
    super.initState();
    f = widget.flt.copy();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: const Color(0x80141420),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
              decoration: const BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
                  const Text('필터', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  const SizedBox(height: 18),
                  _frow('최대 금액', won(f.maxPrice),
                      Slider(value: f.maxPrice.toDouble(), min: 5000, max: 30000, divisions: 25, activeColor: AppColors.black, onChanged: (v) => setState(() => f.maxPrice = v.round()))),
                  _frow('최대 거리', '${_fmtDist(f.maxDist)}km 이내',
                      Slider(value: f.maxDist, min: 0.3, max: 2, divisions: 17, activeColor: AppColors.black, onChanged: (v) => setState(() => f.maxDist = v))),
                  const Text('상대 성별', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final e in [['all', '전체'], ['여', '여성'], ['남', '남성']])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => setState(() => f.gender = e[0]),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: f.gender == e[0] ? AppColors.ink : AppColors.card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: f.gender == e[0] ? AppColors.ink : AppColors.line, width: 1.5),
                                ),
                                child: Text(e[1], style: TextStyle(color: f.gender == e[0] ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _frow('나이대', '${f.ageMin} ~ ${f.ageMax}세',
                      RangeSlider(
                        values: RangeValues(f.ageMin.toDouble(), f.ageMax.toDouble()),
                        min: 20, max: 60, divisions: 8, activeColor: AppColors.black,
                        onChanged: (r) => setState(() {
                          f.ageMin = r.start.round();
                          f.ageMax = r.end.round();
                        }),
                      )),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => widget.onApplyFilters(f),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('이 조건으로 보기', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _frow(String label, String v, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
              Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.blue)),
            ],
          ),
          child,
        ],
      ),
    );
  }
}
