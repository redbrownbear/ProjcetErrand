import 'package:flutter/material.dart';

import '../models/filters.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';

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
                  _frow('최대 거리', '${fmtDist(f.maxDist)}km 이내',
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
