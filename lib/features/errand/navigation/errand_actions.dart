import 'package:flutter/material.dart';

import '../../benefits/services/mission_tracker.dart';
import '../../community/screens/community_post_screen.dart';
import '../models/offer.dart';
import '../models/task_item.dart';
import '../screens/detail_page.dart';

/// 부탁 상세(또는 같이해요 게시글)를 여는 데 필요한 데이터·콜백 묶음.
/// 여러 화면에서 반복되는 grabbed/onGrab/onOffer/offers/관심 저장 파라미터를 하나로 묶어서 내려줌.
class ErrandActions {
  final List<int> grabbed;
  final void Function(TaskItem) onGrab;
  final void Function(TaskItem, int, String) onOffer;
  final Map<int, List<Offer>> offers;
  final bool Function(int id) isSaved;
  final void Function(int id) toggleSave;
  const ErrandActions({
    required this.grabbed, required this.onGrab, required this.onOffer, required this.offers,
    required this.isSaved, required this.toggleSave,
  });

  void open(BuildContext context, TaskItem it) {
    // '근처 부탁 3개 열어보기' 미션 진행도. 상세를 여는 길목이 여기 하나뿐이라
    // 어느 화면에서 들어왔든 한 번만 세진다. 같은 부탁을 여러 번 열어도 1회다.
    MissionTracker.bump(MissionTracker.openDetail, unique: it.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => it.mode == 'together'
            ? CommunityPostScreen(it: it, grabbed: grabbed, onGrab: onGrab, isSaved: isSaved, toggleSave: toggleSave)
            : DetailPage(it: it, grabbed: grabbed, myOffers: offers[it.id] ?? const [], onGrab: onGrab, onOffer: onOffer, isSaved: isSaved, toggleSave: toggleSave),
      ),
    );
  }
}
