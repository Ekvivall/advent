import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'advent_model.dart';

class AdventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String collectionName;

  AdventService({required this.collectionName});

  Stream<List<AdventDay>> getAdventDays() {
    return _firestore.collection(collectionName).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdventDay.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> markAsFoundInCloud(String docId) async {
    await _firestore.collection(collectionName).doc(docId).update({
      'isFound': true,
    });
  }


  Future<void> updateDayData(String docId, Map<String, dynamic> newData) async {
    await _firestore
        .collection(collectionName)
        .doc(docId)
        .set(newData, SetOptions(merge: true));
    if (collectionName == 'calendar') {
      await propagateChangesToOthers(docId, newData);
    }
  }

    Future<String> uploadFile(File file, String folderName) async {
      final ref = _storage.ref().child(
        '$collectionName/$folderName/${DateTime
            .now()
            .millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(file);
      return await ref.getDownloadURL();
    }

    Future<String> uploadAudio(File file) async {
      final ref = _storage.ref().child(
        '$collectionName/music/${DateTime
            .now()
            .millisecondsSinceEpoch}.mp3',
      );
      final metadata = SettableMetadata(contentType: 'audio/mpeg');

      await ref.putFile(file, metadata);
      return await ref.getDownloadURL();
    }


Future<void> propagateChangesToOthers(String docId,
    Map<String, dynamic> masterData,) async {
  try {
    final registryDoc = await _firestore
        .collection('metadata')
        .doc('registry')
        .get();
    if (!registryDoc.exists) return;

    final List<dynamic> calendars = registryDoc.data()?['calendars'] ?? [];

    final batch = _firestore.batch();
    int updatesCount = 0;

    for (final targetId in calendars) {
      if (targetId == 'calendar') continue;

      final targetRef = _firestore.collection(targetId).doc(docId);
      final targetSnapshot = await targetRef.get();
      final targetData = targetSnapshot.data();

      Map<String, dynamic> updates = {};



      if (masterData.containsKey('description') &&
          (targetData?['description'] == null ||
              targetData!['description'] == '' )) {
        updates['description'] = masterData['description'];
      }

      if (masterData.containsKey('hintImageUrl') &&
          (targetData?['hintImageUrl'] == null ||
              targetData!['hintImageUrl'] == '')) {
        updates['hintImageUrl'] = masterData['hintImageUrl'];
      }

      if (masterData.containsKey('audioUrl') &&
          (targetData?['audioUrl'] == null ||
              targetData!['audioUrl'] == '')) {
        updates['audioUrl'] = masterData['audioUrl'];
      }

      if (updates.isNotEmpty) {
        batch.set(targetRef, updates, SetOptions(merge: true));
        updatesCount++;
      }
    }

    if (updatesCount > 0) {
      await batch.commit();
      print(
        "🔄 Автоматично оновлено $updatesCount календарів даними з шаблону!",
      );
    }
  } catch (e) {
    print("Помилка розсилки змін: $e");
  }
}

}