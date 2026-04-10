
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreInitService {
  static final FirestoreInitService _instance = FirestoreInitService._internal();
  factory FirestoreInitService() => _instance;
  FirestoreInitService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // collections
  static const String profiles = 'profiles';
  static const String projects = 'projects';
  static const String investments = 'investments';
  static const String milestones = 'milestones';
  static const String messages = 'messages';
  static const String appSettings = 'app_settings';

  // check if Firestore is already initialized
Future<bool> isInitialized() async {
  try {
    final doc = await _firestore.collection(appSettings).doc('init').get();
    return doc.exists && doc.data()?['initialized'] == true;
  } catch (e) {
    if (kDebugMode) {
      print('Error checking initialization: $e');
    }
    return false;
    }
  }

  Future<void> initialize() async {
  try {
    final alreadyInitialized = await isInitialized();
    if (alreadyInitialized) {
      if (kDebugMode) {
        print("Firestore already initialized");
      }
      return;
    }

    await _createCollections();
    await _documentIndexes();
    await _markAsInitialized();
  } catch (e) {
    if (kDebugMode) {
      print("Firestore init failed");
    }
  }
  }

  // Create all collections
  Future<void> _createCollections() async {
    if (kDebugMode) {
      print('📁 Creating collections...');
    }

    final collections = [
      profiles,
      projects,
      investments,
      milestones,
      messages,
      appSettings,
    ];

    for (final collection in collections) {
      // Create a temporary document to initialize the collection
      final tempRef = _firestore.collection(collection).doc('_init');
      await tempRef.set({
        'created_at': FieldValue.serverTimestamp(),
        'purpose': 'Collection initialization marker',
      });
      await tempRef.delete(); // Remove the temp document
      if (kDebugMode) {
        print('  ✓ Collection "$collection" created');
      }
    }
  }

  // Document required indexes (Firestore indexes must be created in console)
  Future<void> _documentIndexes() async {
    if (kDebugMode) {
      print('📋 Documenting required indexes...');
    }

    final indexRef = _firestore.collection(appSettings).doc('indexes');
    await indexRef.set({
      'required_indexes': [
        {
          'collection': projects,
          'fields': [
            {'field': 'status', 'order': 'ASC'},
            {'field': 'createdAt', 'order': 'DESC'},
          ],
        },
        {
          'collection': investments,
          'fields': [
            {'field': 'projectId', 'order': 'ASC'},
            {'field': 'createdAt', 'order': 'DESC'},
          ],
        },
        {
          'collection': investments,
          'fields': [
            {'field': 'investorId', 'order': 'ASC'},
            {'field': 'createdAt', 'order': 'DESC'},
          ],
        },
        {
          'collection': milestones,
          'fields': [
            {'field': 'projectId', 'order': 'ASC'},
            {'field': 'deadline', 'order': 'ASC'},
          ],
        },
        {
          'collection': messages,
          'fields': [
            {'field': 'projectId', 'order': 'ASC'},
            {'field': 'createdAt', 'order': 'DESC'},
          ],
        },
      ],
      'instructions': 'Create these indexes in Firebase Console → Firestore → Indexes',
      'created_at': FieldValue.serverTimestamp(),
    });

    if (kDebugMode) {
      print('  ✓ Index requirements documented');
    }
  }

  // Mark Firestore as initialized
  Future<void> _markAsInitialized() async {
    await _firestore.collection(appSettings).doc('init').set({
      'initialized': true,
      'version': '1.0.0',
      'initialized_at': FieldValue.serverTimestamp(),
      'collections': [
        profiles,
        projects,
        investments,
        milestones,
        messages,
      ],
    });
    if (kDebugMode) {
      print('  ✓ Marked as initialized');
    }
  }

  // Optional: Add sample projects for testing
  Future<void> _addSampleProjects() async {
    final projectsRef = _firestore.collection(projects);

    final sampleProjects = [
      {
        'title': 'Tech Startup Investment',
        'description': 'Invest in a promising tech startup focused on AI solutions.',
        'goalAmount': 100000,
        'raisedAmount': 25000,
        'status': 'active',
        'category': 'Technology',
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 90))),
      },
      {
        'title': 'Real Estate Development',
        'description': 'Commercial property development in downtown area.',
        'goalAmount': 500000,
        'raisedAmount': 150000,
        'status': 'active',
        'category': 'Real Estate',
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 180))),
      },
      {
        'title': 'Green Energy Project',
        'description': 'Solar farm installation for sustainable energy production.',
        'goalAmount': 250000,
        'raisedAmount': 250000,
        'status': 'completed',
        'category': 'Energy',
        'deadline': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
      },
    ];

    for (final project in sampleProjects) {
      await projectsRef.add({
        ...project,
        'ownerId': 'seed_owner',
        'investorIds': [],
        'totalInvestors': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (kDebugMode) {
      print('  ✓ Added ${sampleProjects.length} sample projects');
    }
  }

  // Optional: Add sample users for testing
  Future<void> _addSampleUsers() async {
    final profilesRef = _firestore.collection(profiles);

    // Don't overwrite existing users, just add seed test users
    await profilesRef.doc('seed_user_1').set({
      'email': 'investor1@example.com',
      'fullName': 'John Investor',
      'role': 'investor',
      'isVerified': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await profilesRef.doc('seed_user_2').set({
      'email': 'admin@example.com',
      'fullName': 'Admin User',
      'role': 'admin',
      'isVerified': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (kDebugMode) {
      print('  ✓ Added sample users');
    }
  }

  // Reset initialization (for development only!)
  Future<void> resetInitialization() async {
    if (kDebugMode) {
      print('⚠️  Resetting Firestore initialization...');
    }
    await _firestore.collection(appSettings).doc('init').delete();
    if (kDebugMode) {
      print('✓ Initialization reset. Will reinitialize on next app launch.');
    }
  }

  // Get initialization status
  Future<Map<String, dynamic>> getInitializationStatus() async {
    final doc = await _firestore.collection(appSettings).doc('init').get();

    if (!doc.exists) {
      return {'initialized': false, 'message': 'Not initialized yet'};
    }

    final data = doc.data()!;
    return {
      'initialized': data['initialized'] ?? false,
      'version': data['version'] ?? 'unknown',
      'initialized_at': data['initialized_at']?.toDate(),
      'collections': data['collections'] ?? [],
    };
  }
}
