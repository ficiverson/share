import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/models/user.dart';

void main() {
  group('AppUser', () {
    test('constructor asigna todos los campos', () {
      final u = AppUser(id: 'uid', email: 'a@e.com', displayName: 'Alice', photoUrl: 'http://img');
      expect(u.id, 'uid');
      expect(u.email, 'a@e.com');
      expect(u.displayName, 'Alice');
      expect(u.photoUrl, 'http://img');
    });

    test('photoUrl es nullable', () {
      final u = AppUser(id: 'uid', email: 'a@e.com', displayName: 'Alice');
      expect(u.photoUrl, isNull);
    });

    test('toJson serializa correctamente', () {
      final u = AppUser(id: 'uid', email: 'a@e.com', displayName: 'Alice', photoUrl: 'http://img');
      final json = u.toJson();
      expect(json['id'], 'uid');
      expect(json['email'], 'a@e.com');
      expect(json['displayName'], 'Alice');
      expect(json['photoUrl'], 'http://img');
    });

    test('fromJson deserializa correctamente', () {
      final json = {'id': 'uid', 'email': 'a@e.com', 'displayName': 'Alice', 'photoUrl': null};
      final u = AppUser.fromJson(json);
      expect(u.id, 'uid');
      expect(u.email, 'a@e.com');
      expect(u.displayName, 'Alice');
      expect(u.photoUrl, isNull);
    });

    test('round-trip toJson/fromJson conserva todos los campos', () {
      final original = AppUser(id: 'uid', email: 'a@e.com', displayName: 'Alice', photoUrl: 'http://p');
      final restored = AppUser.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.email, original.email);
      expect(restored.displayName, original.displayName);
      expect(restored.photoUrl, original.photoUrl);
    });
  });
}
