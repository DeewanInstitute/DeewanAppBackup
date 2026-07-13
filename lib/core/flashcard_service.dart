import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FlashcardDeck {
  final String id;
  final String label;
  const FlashcardDeck(this.id, this.label);
}

class FlashcardDecks {
  FlashcardDecks._();

  static const beginner = FlashcardDeck('beginner', 'Beginner');
  static const intermediate = FlashcardDeck('intermediate', 'Intermediate');
  static const advanced = FlashcardDeck('advanced', 'Advanced');
  static const custom = FlashcardDeck('custom', 'My Custom Cards');

  static const all = [beginner, intermediate, advanced, custom];

  static FlashcardDeck byId(String id) => all.firstWhere((d) => d.id == id, orElse: () => custom);
}

/// Stores user-saved dictionary words into decks, per signed-in user, in
/// Firestore at users/{uid}/savedWords/{wordId}.
class FlashcardService {
  FlashcardService._();

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static bool get isSignedIn => _uid != null;

  static CollectionReference<Map<String, dynamic>>? get _savedWords {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('savedWords');
  }

  /// Saves [word] under [wordId] into [deckId], moving it out of any deck it
  /// was previously saved to. Returns the new total card count for that deck.
  static Future<int> saveWord({
    required String wordId,
    required Map<String, dynamic> word,
    required String deckId,
  }) async {
    final collection = _savedWords;
    if (collection == null) throw StateError('User is not signed in.');
    await collection.doc(wordId).set({
      'english': word['english'],
      'arabic': word['arabic'],
      'deck': deckId,
      'savedAt': FieldValue.serverTimestamp(),
    });
    return deckCount(deckId);
  }

  static Future<int> deckCount(String deckId) async {
    final collection = _savedWords;
    if (collection == null) return 0;
    final snapshot = await collection.where('deck', isEqualTo: deckId).count().get();
    return snapshot.count ?? 0;
  }
}
