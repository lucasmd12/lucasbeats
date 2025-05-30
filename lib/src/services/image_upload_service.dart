import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For ValueNotifier

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final ValueNotifier<bool> uploading = ValueNotifier<bool>(false);
  final ValueNotifier<double> progress = ValueNotifier<double>(0);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);

  // Generic image upload function
  Future<String?> _uploadImage({
    required File imageFile,
    required String path,
    bool updateFirestore = false,
    String? firestoreCollection,
    String? firestoreDocId,
    String? firestoreField,
  }) async {
    try {
      uploading.value = true;
      progress.value = 0;
      error.value = null;

      final storageRef = _storage.ref().child(path);
      final uploadTask = storageRef.putFile(imageFile);

      // Listen for state changes, errors, and completion of the upload.
      uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) {
        switch (taskSnapshot.state) {
          case TaskState.running:
            final progressValue = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
            progress.value = progressValue;
            break;
          case TaskState.paused:
            print("Upload is paused.");
            break;
          case TaskState.canceled:
            print("Upload was canceled");
             error.value = 'Upload cancelado.';
             uploading.value = false;
            break;
          case TaskState.error:
            print("Upload error");
            error.value = 'Falha ao fazer upload da imagem.';
            uploading.value = false;
            break;
          case TaskState.success:
            print("Upload successful");
            // Handled by the completion future below
            break;
        }
      });

      // Wait for the upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadURL = await snapshot.ref.getDownloadURL();

      // Update Firestore if requested
      if (updateFirestore && firestoreCollection != null && firestoreDocId != null && firestoreField != null) {
        try {
          final docRef = _firestore.collection(firestoreCollection).doc(firestoreDocId);
          await docRef.update({firestoreField: downloadURL});
        } catch (err) {
          print('Erro ao atualizar Firestore: $err');
          error.value = 'Falha ao atualizar informações após upload.';
          // Decide if you want to return null or the URL even if Firestore update fails
        }
      }

      uploading.value = false;
      return downloadURL;

    } catch (e) {
      print('Erro ao iniciar upload: $e');
      error.value = 'Falha ao processar imagem para upload.';
      uploading.value = false;
      return null;
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage({required File imageFile, String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
       error.value = "Usuário não autenticado.";
       return null;
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'profiles/$uid/profile_$timestamp.jpg'; // Unique path per user
    return _uploadImage(
      imageFile: imageFile,
      path: path,
      updateFirestore: true,
      firestoreCollection: 'users',
      firestoreDocId: uid,
      firestoreField: 'photoURL',
    );
  }

  // Upload clan image (banner)
  Future<String?> uploadClanImage({required File imageFile, required String clanId}) async {
     if (clanId.isEmpty) {
       error.value = "ID do clã inválido.";
       return null;
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'clans/$clanId/banner_$timestamp.jpg'; // Unique path per clan
    return _uploadImage(
      imageFile: imageFile,
      path: path,
      updateFirestore: true,
      firestoreCollection: 'clans',
      firestoreDocId: clanId,
      firestoreField: 'bannerURL',
    );
  }

  void dispose() {
     uploading.dispose();
     progress.dispose();
     error.dispose();
  }
}

