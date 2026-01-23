import '../../models/school_model.dart';
import '../../../core/database/database_connection_manager.dart';
import '../../../core/database/soft_delete_support.dart';

/// Direct DB datasource for schools (PostgreSQL)
class SchoolDbDataSource {
  final DatabaseConnectionManager db;

  SchoolDbDataSource(this.db);

  Future<List<SchoolModel>> getSchools() async {
    try {
      final rows = await db.query('''
        SELECT id, name, location, phone, email, website, logo_url, established_year, is_active,
               created_at, updated_at
        FROM schools
        WHERE deleted_at IS NULL
        ORDER BY name
      ''');
      return rows.map((r) => SchoolModel.fromJson(r)).toList();
    } catch (e) {
      if (SoftDeleteSupport.isMissingDeletedAtColumn(e is Object ? e : Exception('Unknown error'))) {
        final rows = await db.query('''
          SELECT id, name, location, phone, email, website, logo_url, established_year, is_active,
                 created_at, updated_at
          FROM schools
          ORDER BY name
        ''');
        return rows.map((r) => SchoolModel.fromJson(r)).toList();
      }
      rethrow;
    }
  }

  Future<SchoolModel?> getSchool(String id) async {
    try {
      final rows = await db.query('''
        SELECT id, name, location, phone, email, website, logo_url, established_year, is_active,
               created_at, updated_at
        FROM schools
        WHERE id = @0 AND deleted_at IS NULL
        LIMIT 1
      ''', [id]);

      if (rows.isEmpty) return null;
      return SchoolModel.fromJson(rows.first);
    } catch (e) {
      if (SoftDeleteSupport.isMissingDeletedAtColumn(e is Object ? e : Exception('Unknown error'))) {
        final rows = await db.query('''
          SELECT id, name, location, phone, email, website, logo_url, established_year, is_active,
                 created_at, updated_at
          FROM schools
          WHERE id = @0
          LIMIT 1
        ''', [id]);

        if (rows.isEmpty) return null;
        return SchoolModel.fromJson(rows.first);
      }
      rethrow;
    }
  }

  Future<SchoolModel?> createSchool(SchoolModel school) async {

    final id = school.id;
    if (id == null || id.isEmpty) {
      throw Exception('School.id is required for direct DB create');
    }

    await db.execute('''
      INSERT INTO schools (id, name, location, phone, email, website, logo_url, established_year, is_active, created_at, updated_at)
      VALUES (@0, @1, @2, @3, @4, @5, @6, @7, @8, NOW(), NOW())
    ''', [
      id,
      school.name,
      school.location,
      school.phone,
      school.email,
      school.website,
      school.logoUrl,
      school.establishedYear,
      school.isActive,
    ]);

    return getSchool(id);
  }

  Future<SchoolModel?> updateSchool(String id, SchoolModel school) async {
    try {
      await db.execute('''
        UPDATE schools
        SET name = @0,
            location = @1,
            phone = @2,
            email = @3,
            website = @4,
            logo_url = @5,
            established_year = @6,
            is_active = @7,
            updated_at = NOW()
        WHERE id = @8 AND deleted_at IS NULL
      ''', [
        school.name,
        school.location,
        school.phone,
        school.email,
        school.website,
        school.logoUrl,
        school.establishedYear,
        school.isActive,
        id,
      ]);

      return getSchool(id);
    } catch (e) {
      if (SoftDeleteSupport.isMissingDeletedAtColumn(e is Object ? e : Exception('Unknown error'))) {
        await db.execute('''
          UPDATE schools
          SET name = @0,
              location = @1,
              phone = @2,
              email = @3,
              website = @4,
              logo_url = @5,
              established_year = @6,
              is_active = @7,
              updated_at = NOW()
          WHERE id = @8
        ''', [
          school.name,
          school.location,
          school.phone,
          school.email,
          school.website,
          school.logoUrl,
          school.establishedYear,
          school.isActive,
          id,
        ]);

        return getSchool(id);
      }
      rethrow;
    }
  }

  Future<bool> deleteSchool(String id) async {
    try {
      final affected = await db.execute('''
        UPDATE schools
        SET deleted_at = NOW(), updated_at = NOW()
        WHERE id = @0 AND deleted_at IS NULL
      ''', [id]);

      return affected > 0;
    } catch (e) {
      if (SoftDeleteSupport.isMissingDeletedAtColumn(e is Object ? e : Exception('Unknown error'))) {
        final affected = await db.execute('DELETE FROM schools WHERE id = @0', [id]);
        return affected > 0;
      }
      rethrow;
    }
  }
}
