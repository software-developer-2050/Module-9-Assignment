import 'package:flutter_test/flutter_test.dart';
import 'package:module_9_assignment/database/database_helper.dart';
import 'package:module_9_assignment/models/contact.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('CRUD, search and favorites work', () async {
    final db = DatabaseHelper.instance;
    final id = await db.insertContact(const Contact(
      name: 'Zz Test User',
      phone: '01700000000',
      email: 'zz@test.com',
      address: 'Somewhere',
    ));
    expect(id, greaterThan(0));

    var found = await db.getContacts(query: 'zz test');
    expect(found.any((c) => c.id == id), isTrue);

    var favs = await db.getContacts(favoritesOnly: true);
    expect(favs.any((c) => c.id == id), isFalse);

    final contact = found.firstWhere((c) => c.id == id);
    await db.updateContact(contact.copyWith(phone: '01811111111'));
    await db.toggleFavorite(contact.copyWith(phone: '01811111111'));

    favs = await db.getContacts(favoritesOnly: true);
    final updated = favs.firstWhere((c) => c.id == id);
    expect(updated.phone, '01811111111');
    expect(updated.isFavorite, isTrue);

    await db.deleteContact(id);
    found = await db.getContacts(query: 'zz test');
    expect(found.any((c) => c.id == id), isFalse);
  });
}
