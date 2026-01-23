/// Soft-delete support helper.
///
/// Some older DB schemas might not have `deleted_at` columns.
/// When they don't exist, we should avoid filtering by them.
class SoftDeleteSupport {
  static bool isMissingDeletedAtColumn(Object e) {
    final msg = e.toString();
    return msg.contains('column') && msg.contains('deleted_at') && msg.contains('does not exist');
  }
}
