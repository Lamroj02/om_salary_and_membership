import 'package:om_salary_and_membership/membershipRoutes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//Tests member entity manipulation in firestore

// Create a mock class using Mockito
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();

    // Correcting the types here
    when(mockFirestore.collection('Members')).thenReturn(mockCollection);
    when(mockCollection.doc('001')).thenReturn(mockDocument);
  });

  test('uploadMember uploads a member to Firestore!', () async {
    final member = Member(
      id: '123',
      name: 'John Doe',
      email: 'john.doe@example.com',
      contactNum: '1234567890',
      points: 100,
      voucher: DateTime.now(),
    );

    when(mockDocument.set(any as Map<String,dynamic>)).thenAnswer((_) async => null);

    await uploadMember(member);

    verify(mockCollection.doc('123')).called(1);
    verify(mockDocument.set({
      'name': 'John Doe',
      'email': 'john.doe@example.com',
      'contactNumber': '1234567890',
      'points': 100,
      'voucherExpiry': member.voucher,
    })).called(1);
  });

  test('deleteMemberStored deletes a member from Firestore!', () async {
    when(mockDocument.delete()).thenAnswer((_) async => null);

    await deleteMemberStored('123');

    verify(mockCollection.doc('123')).called(1);
    verify(mockDocument.delete()).called(1);
  });
}

