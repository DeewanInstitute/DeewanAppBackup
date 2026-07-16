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

/// A user-defined grouping of custom cards (e.g. "Food", "Travel"), with how
/// many cards currently carry that tag.
class CustomCategory {
  final String name;
  final int count;
  const CustomCategory(this.name, this.count);
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
  /// in the custom deck, tagged under [category]. Returns the new total card
  /// count for that deck.
  static Future<int> createCustomCard({
    required String english,
    required String arabic,
    required String category,
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
      'category': category,
      if (transliteration != null && transliteration.isNotEmpty) 'transliteration': transliteration,
      if (exampleArabic != null && exampleArabic.isNotEmpty) 'exampleArabic': exampleArabic,
      if (exampleTransliteration != null && exampleTransliteration.isNotEmpty) 'exampleTransliteration': exampleTransliteration,
      if (exampleEnglish != null && exampleEnglish.isNotEmpty) 'exampleEnglish': exampleEnglish,
      'deck': FlashcardDecks.custom.id,
      'savedAt': FieldValue.serverTimestamp(),
    });
    return deckCount(FlashcardDecks.custom.id);
  }

  /// Groups the user's custom cards by their [category] tag, newest category
  /// activity first. Cards saved before categories existed fall back to
  /// "General" so old data still shows up.
  static Future<List<CustomCategory>> getCustomCategories() async {
    final words = await getDeckWords(FlashcardDecks.custom.id);
    final counts = <String, int>{};
    for (final w in words) {
      final category = (w['category'] as String?)?.trim();
      final key = (category == null || category.isEmpty) ? 'General' : category;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts.entries.map((e) => CustomCategory(e.key, e.value)).toList();
  }

  /// Fetches the custom cards tagged under [category] for study.
  static Future<List<Map<String, dynamic>>> getCategoryWords(String category) async {
    final words = await getDeckWords(FlashcardDecks.custom.id);
    return words.where((w) {
      final c = (w['category'] as String?)?.trim();
      final key = (c == null || c.isEmpty) ? 'General' : c;
      return key == category;
    }).toList();
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
