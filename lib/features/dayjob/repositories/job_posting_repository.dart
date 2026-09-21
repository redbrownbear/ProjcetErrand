import '../../../core/storage/local_store.dart';
import '../models/job_posting.dart';

/// 내가 올린 단기알바 모집글. 시안과 같이 **이 기기에만** 남는다.
///
/// 실제 서비스에서는 사업자 확인과 지원 접수가 필요하므로 서버가 갖고 있어야 한다.
/// 화면에도 "실제 지원 접수는 연동 전"이라고 밝혀 둔다.
class JobPostingRepository {
  static const _key = 'jobPostings';

  static List<JobPosting> load() {
    final raw = LocalStore.read<List<dynamic>>(_key, const []);
    final list = <JobPosting>[];
    for (final e in raw) {
      if (e is! Map<String, dynamic>) continue;
      final job = JobPosting.fromJson(e);
      if (job != null) list.add(job);
    }
    return list;
  }

  static void save(List<JobPosting> list) => LocalStore.write(_key, [for (final j in list) j.toJson()]);

  /// 새 모집글을 맨 앞에 넣고 저장한다.
  static List<JobPosting> add(JobPosting job) {
    final next = [job, ...load()];
    save(next);
    return next;
  }
}
