import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gyeomsa/core/storage/local_store.dart';

/// 저장소 접두사를 'gyumsa:v3:'에서 'gyeomsa:v3:'로 고치면서,
/// 이미 기기에 있던 값이 사라지지 않는지 확인한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('옛 접두사로 저장된 값이 새 접두사로 옮겨진다', () async {
    SharedPreferences.setMockInitialValues({
      'gyumsa:v3:bookmarks': '[1,2,3]',
      'gyumsa:v3:requests': '[]',
      // 우리 것이 아닌 키는 건드리지 않는다.
      // shared_preferences는 'flutter.' 접두사를 붙여 보관하고 읽을 때 떼어낸다.
      'flutter.other': 'keep',
    });

    await LocalStore.init();

    expect(LocalStore.read<List<dynamic>>('bookmarks', const []), [1, 2, 3]);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('gyeomsa:v3:bookmarks'), '[1,2,3]');
    expect(prefs.getString('gyumsa:v3:bookmarks'), isNull, reason: '옛 키는 지워져야 한다');
    expect(prefs.getString('other'), 'keep');
  });

  test('새 접두사 값이 이미 있으면 옛 값이 덮어쓰지 않는다', () async {
    SharedPreferences.setMockInitialValues({
      'gyumsa:v3:bookmarks': '[1]',
      'gyeomsa:v3:bookmarks': '[9,9]',
    });

    await LocalStore.init();

    expect(LocalStore.read<List<dynamic>>('bookmarks', const []), [9, 9]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('gyumsa:v3:bookmarks'), isNull);
  });

  test('읽기·쓰기·삭제가 새 접두사로 동작한다', () async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.init();

    LocalStore.write('goalTest', 12345);
    expect(LocalStore.read<int>('goalTest', 0), 12345);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('gyeomsa:v3:goalTest'), '12345');

    LocalStore.remove('goalTest');
    expect(LocalStore.read<int>('goalTest', 0), 0);
  });
}
