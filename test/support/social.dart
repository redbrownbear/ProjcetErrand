import 'package:gyeomsa/app/app_nav.dart';
import 'package:gyeomsa/app/neighbor_store.dart';
import 'package:gyeomsa/features/errand/navigation/errand_actions.dart';
import 'package:gyeomsa/features/errand/repositories/errand_repository.dart';

/// 화면 테스트용 v77 길목. 화면을 여는 콜백은 아무 일도 하지 않는다.
AppNav testSocial({NeighborStore? store, List<String>? toasts}) {
  final items = LocalErrandRepository().fetchSeedItems();
  return AppNav(
    store: store ?? NeighborStore(),
    nickname: () => '테스트',
    area: () => '서초구',
    items: () => items,
    actions: () => ErrandActions(
      grabbed: const [],
      onGrab: (_) {},
      onOffer: (_, _, _) {},
      offers: const {},
      isSaved: (_) => false,
      toggleSave: (_) {},
    ),
    flash: (m) => toasts?.add(m),
    openAskForm: () {},
    openSeaForm: () {},
    goCommunity: (_, {place}) {},
    requestDelivery: (_) {},
  );
}
