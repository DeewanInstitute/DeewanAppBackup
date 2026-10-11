import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Fetches dictionary words from the Firestore `dictionary` collection
/// (read-only for clients — see firestore rules). Caches the result in
/// memory for the app session so repeat visits to the search page don't
/// re-fetch all documents every time.
class DictionaryRepository {
  DictionaryRepository._();

  static List<Map<String, dynamic>>? _cache;

  static bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  static Future<List<Map<String, dynamic>>> load({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;
    final snapshot = await FirebaseFirestore.instance.collection('dictionary').get();
    _cache = snapshot.docs.map((doc) => doc.data()).toList();
    return _cache!;
  }

  /// Calls the `lookupWord` Cloud Function, which asks ChatGPT for a Fusha +
  /// Levantine entry, stores it in Firestore server-side, and returns it.
  /// Only used as a fallback when a word isn't already in [load]'s results.
  static Future<Map<String, dynamic>> lookupWithAi(String english) async {
    if (!isSignedIn) throw StateError('User is not signed in.');

    final callable = FirebaseFunctions.instance.httpsCallable('lookupWord');
    final result = await callable.call({'word': english});
    final entry = Map<String, dynamic>.from(result.data as Map);

    _cache = [...?_cache, entry];
    return entry;
  }

  /// Admin-only: re-checks the verb forms of already-stored words. Processes a
  /// batch per call — repeat until the result's `remaining` is 0.
  static Future<Map<String, dynamic>> reviewVerbs() async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'reviewVerbs',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 9)),
    );
    final result = await callable.call();
    _cache = null; // stored entries may have changed
    return Map<String, dynamic>.from(result.data as Map);
  }
}
