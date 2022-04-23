import 'dart:async';
//import 'dart:html' as html;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';

class CloudFiretore extends StatelessWidget {
  CloudFiretore({Key? key}) : super(key: key);

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _userSubscribe = null;
  @override
  Widget build(BuildContext context) {
    //ID
    debugPrint(_firestore.collection('users').id);
    debugPrint(_firestore.collection('users').doc().id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Firestore'),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
                onPressed: () => dataAdd(), child: const Text('Add Data')),
            ElevatedButton(
                onPressed: () => dataSet(), child: const Text('Set Data')),
            ElevatedButton(
                onPressed: () => dataUpdate(),
                child: const Text('Update Data')),
            ElevatedButton(
                onPressed: () => dataDelete(),
                child: const Text('Delete Data')),
            ElevatedButton(
                onPressed: () => readDataOneTime(),
                child: const Text('Read Data One Time')),
            ElevatedButton(
                onPressed: () => readDataRealTime(),
                child: const Text('Read Data Real Time')),
            ElevatedButton(
                onPressed: () => streamStop(),
                child: const Text('Stop Stream')),
            ElevatedButton(
                onPressed: () => batchGet(), child: const Text('Batch')),
            ElevatedButton(
                onPressed: () => transactionGet(),
                child: const Text('Transaction')),
            ElevatedButton(
                onPressed: () => queryingData(),
                child: const Text('Data Query')),
            ElevatedButton(
                onPressed: () => camGalleryImageUpload(),
                child: const Text('Camera & Gallery Image')),
          ],
        ),
      ),
    );
  }

  dataAdd() async {
    Map<String, dynamic> _data = <String, dynamic>{};
    _data['name'] = 'emir';
    _data['age'] = '21';
    _data['student'] = true;
    _data['address'] = {'country': 'Turkey', 'province': 'Ankara'};
    _data['colors'] = FieldValue.arrayUnion(['blue', 'green']);
    _data['createdAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('users').add(_data);
  }

  dataSet() async {
    var _newDocID = _firestore.collection('users').doc().id;

    await _firestore.doc('users/$_newDocID').set({
      'name': 'emir',
      'userID': _newDocID,
    });

    await _firestore.doc('users/jy7rxAUITIhEkhuEc49H').set(
        {'education': 'Ankara University', 'age': FieldValue.increment(1)},
        SetOptions(merge: true));
  }

  dataUpdate() async {
    await _firestore.doc('users/jy7rxAUITIhEkhuEc49H').update({
      'address.province': 'Istanbul',
      'age': 21,
    });
  }

  dataDelete() async {
    //  await _firestore.doc('users/jy7rxAUITIhEkhuEc49H').delete();
    await _firestore
        .doc('users/jy7rxAUITIhEkhuEc49H')
        .update({'education': FieldValue.delete()});
  }

  readDataOneTime() async {
    var _userDocuments = await _firestore.collection('users').get();
    debugPrint(_userDocuments.size.toString());
    debugPrint(_userDocuments.docs.length.toString());
    for (var user in _userDocuments.docs) {
      debugPrint('User Id ${user.id}');
      Map userMap = user.data();
      debugPrint(userMap['name']);
    }
    var _adminDoc = await _firestore.doc('users/jy7rxAUITIhEkhuEc49H').get();
    debugPrint(_adminDoc.data().toString());
  }

  readDataRealTime() async {
    var _userStream = await _firestore.collection('users').snapshots();
    _userSubscribe = _userStream.listen((event) {
      /*  event.docChanges.forEach((element) {
        debugPrint(element.doc.data().toString());
      });*/
      event.docs.forEach((element) {
        debugPrint(element.data().toString());
      });
    });
  }

  streamStop() {
    _userSubscribe?.cancel();
  }

  batchGet() async {
    WriteBatch _batch = _firestore.batch();
    CollectionReference _counterCollectionRef =
        _firestore.collection('counter');

    /* for (int i = 0; i < 100; i++) {
      var _newDoc = _counterCollectionRef.doc();
      _batch.set(_newDoc, {'counter': ++i, 'id': _newDoc.id});
    }*/

    var _counterDocs = await _counterCollectionRef.get();
    _counterDocs.docs.forEach((element) {
      _batch.update(
          element.reference, {'createdAt': FieldValue.serverTimestamp()});
    });

    /*
    var _counterDocs = await _counterCollectionRef.get();
    _counterDocs.docs.forEach((element) {
      _batch.delete(element.reference);
    });*/
    await _batch.commit();
  }

  transactionGet() async {
    _firestore.runTransaction((transaction) async {
      DocumentReference<Map<String, dynamic>> user1Ref =
          _firestore.doc('users/EUWOMJYR1VaT2IEUFo2N');
      DocumentReference<Map<String, dynamic>> user2Ref =
          _firestore.doc('users/jy7rxAUITIhEkhuEc49H');

      var _user1Snapshot = await transaction.get(user1Ref);
      var _user1Balance = _user1Snapshot.data()!['money'];
      if (_user1Balance > 200) {
        var _newBalance = _user1Snapshot.data()!['money'] - 100;
        transaction.update(user1Ref, {'money': _newBalance});
        transaction.update(user2Ref, {'money': FieldValue.increment(100)});
      }
    });
  }

  queryingData() async {
    var _userRef = _firestore.collection('users');

    var _data = await _userRef.where('age', isEqualTo: 21).get();
/*
    for (var user in _data.docs) {
      debugPrint(user.data().toString());
    }*/

    var _sort = await _userRef.orderBy('age', descending: true).get();
    for (var user in _sort.docs) {
      debugPrint(user.data().toString());
    }
  }

  camGalleryImageUpload() async {
    final ImagePicker _picker = ImagePicker();

    XFile? _file =
        await _picker.pickImage(source: ImageSource.camera /*.gallery*/);
    var _profileRef = FirebaseStorage.instance.ref('users/profile_pics');
    var _task = _profileRef.putFile(File(_file!.path));

    _task.whenComplete(() async {
      var _url = await _profileRef.getDownloadURL();
      _firestore
          .doc('users/jy7rxAUITIhEkhuEc49H')
          .set({'profile_pic': _url.toString()}, SetOptions(merge: true));
      debugPrint(_url);
    });
  }
}
