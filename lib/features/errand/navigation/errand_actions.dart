import 'package:flutter/material.dart';

import '../../community/screens/community_post_screen.dart';
import '../models/offer.dart';
import '../models/task_item.dart';
import '../screens/detail_page.dart';

/// 부탁 상세(또는 같이해요 게시글)를 여는 데 필요한 데이터·콜백 묶음.
/// 여러 화면에서 반복되는 grabbed/onGrab/onOffer/offers 4개 파라미터를 하나로 묶어서 내려줌.
class ErrandActions {
  final List<int> grabbed;
  final void Function(TaskItem) onGrab;
  final void Function(TaskItem, int, String) onOffer;
  final Map<int, List<Offer>> offers;
  const ErrandActions({required this.grabbed, required this.onGrab, required this.onOffer, required this.offers});

  void open(BuildContext context, TaskItem it) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => it.mode == 'together'
            ? CommunityPostScreen(it: it, grabbed: grabbed, onGrab: onGrab)
            : DetailPage(it: it, grabbed: grabbed, myOffers: offers[it.id] ?? const [], onGrab: onGrab, onOffer: onOffer),
      ),
    );
  }
}
