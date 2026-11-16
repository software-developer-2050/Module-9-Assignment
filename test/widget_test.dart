import 'package:flutter_test/flutter_test.dart';
import 'package:module_9_assignment/models/contact.dart';

void main() {
  test('Contact map round-trip preserves all fields', () {
    const contact = Contact(
      id: 1,
      name: 'Alice',
      phone: '+8801700000000',
      email: 'alice@example.com',
      address: 'Dhaka',
      isFavorite: true,
    );
    final restored = Contact.fromMap(contact.toMap());
    expect(restored.id, 1);
    expect(restored.name, 'Alice');
    expect(restored.phone, '+8801700000000');
    expect(restored.email, 'alice@example.com');
    expect(restored.address, 'Dhaka');
    expect(restored.isFavorite, isTrue);
  });
}
