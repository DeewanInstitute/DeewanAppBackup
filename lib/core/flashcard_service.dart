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

  /// Creates a brand-new user-authored card (not tied to a dictionary entry)
  /// in the custom deck. Returns the new total card count for that deck.
  static Future<int> createCustomCard({
    required String english,
    required String arabic,
    String? transliteration,
    String? exampleArabic,
    String? exampleTransliteration,
    String? exampleEnglish,
  }) async {
    final collection = _savedWords;
    if (collection == null) throw StateError('User is not signed in.');
    await collection.add({
      'english': english,
      'arabic': arabic,
      if (transliteration != null && transliteration.isNotEmpty) 'transliteration': transliteration,
      if (exampleArabic != null && exampleArabic.isNotEmpty) 'exampleArabic': exampleArabic,
      if (exampleTransliteration != null && exampleTransliteration.isNotEmpty) 'exampleTransliteration': exampleTransliteration,
      if (exampleEnglish != null && exampleEnglish.isNotEmpty) 'exampleEnglish': exampleEnglish,
      'deck': FlashcardDecks.custom.id,
      'savedAt': FieldValue.serverTimestamp(),
    });
    return deckCount(FlashcardDecks.custom.id);
  }

  /// Fetches all saved words for [deckId], newest first, shaped for
  /// FlashcardSession (english/arabic/transliteration/exampleArabic/...).
  static Future<List<Map<String, dynamic>>> getDeckWords(String deckId) async {
    final collection = _savedWords;
    if (collection == null) return [];
    final snapshot = await collection.where('deck', isEqualTo: deckId).orderBy('savedAt', descending: true).get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// A stable identifier for a word map: the Firestore doc id if it has one
  /// (custom/saved cards), otherwise a slug derived from its English text
  /// (dictionary words, which aren't Firestore-backed).
  static String wordKeyOf(Map<String, dynamic> word) {
    final id = word['id'] as String?;
    if (id != null) return id;
    return (word['english'] as String).toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
  }

  /// Reads either the dictionary's fusha_sentences or a custom/incorrect
  /// card's standalone example fields, whichever is present.
  static Map<String, String>? extractExample(Map<String, dynamic> word) {
    final fusha = (word['fusha_sentences'] as List?)?.cast<Map>();
    if (fusha != null && fusha.isNotEmpty) {
      final s = fusha.first;
      return {
        'arabic': s['arabic'] as String? ?? '',
        'transliteration': s['transliteration'] as String? ?? '',
        'english': s['english'] as String? ?? '',
      };
    }
    if (word['exampleArabic'] != null) {
      return {
        'arabic': word['exampleArabic'] as String,
        'transliteration': word['exampleTransliteration'] as String? ?? '',
        'english': word['exampleEnglish'] as String? ?? '',
      };
    }
    return null;
  }

  static CollectionReference<Map<String, dynamic>>? get _incorrectCards {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('incorrectCards');
  }

  /// Marks [word] as needing review. Safe to call repeatedly; no-ops if
  /// signed out rather than interrupting study.
  static Future<void> markIncorrect(Map<String, dynamic> word) async {
    final collection = _incorrectCards;
    if (collection == null) return;
    final example = extractExample(word);
    await collection.doc(wordKeyOf(word)).set({
      'english': word['english'],
      'arabic': word['arabic'],
      if (word['transliteration'] != null) 'transliteration': word['transliteration'],
      if (example != null && (example['arabic'] ?? '').isNotEmpty) 'exampleArabic': example['arabic'],
      if (example != null && (example['transliteration'] ?? '').isNotEmpty) 'exampleTransliteration': example['transliteration'],
      if (example != null && (example['english'] ?? '').isNotEmpty) 'exampleEnglish': example['english'],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes [wordKey] from the review list, whether because the user
  /// mastered it or dismissed it manually.
  static Future<void> removeIncorrect(String wordKey) async {
    final collection = _incorrectCards;
    if (collection == null) return;
    await collection.doc(wordKey).delete();
  }

  static Future<List<Map<String, dynamic>>> getIncorrectCards() async {
    final collection = _incorrectCards;
    if (collection == null) return [];
    final snapshot = await collection.orderBy('updatedAt', descending: true).get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  static Future<int> incorrectCount() async {
    final collection = _incorrectCards;
    if (collection == null) return 0;
    final snapshot = await collection.count().get();
    return snapshot.count ?? 0;
  }
}
