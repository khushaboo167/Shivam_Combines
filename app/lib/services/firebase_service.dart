import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String uid;
  final String email;
  final bool isAdmin;
  const AppUser({required this.uid, required this.email, this.isAdmin = false});
}

class UserProfile {
  final String name;
  final String phone;
  final String email;
  final bool isAdmin;
  const UserProfile({required this.name, required this.phone, required this.email, this.isAdmin = false});
}

class Complaint {
  final String id;
  final String customerId;
  final String name;
  final String phone;
  final String meterId;
  final String address;
  final String category;
  final String description;
  final String status;
  final DateTime createdAt;

  const Complaint({
    required this.id,
    required this.customerId,
    required this.name,
    required this.phone,
    required this.meterId,
    required this.address,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  Complaint copyWith({String? status}) => Complaint(
        id: id,
        customerId: customerId,
        name: name,
        phone: phone,
        meterId: meterId,
        address: address,
        category: category,
        description: description,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}

class DeviceReading {
  final double vllAvg;
  final double currentAvg;
  final double? vllRy;
  final double? vllYb;
  final double? vllBr;
  final double? curR;
  final double? curY;
  final double? curB;
  final DateTime timestamp;

  const DeviceReading({
    required this.vllAvg,
    required this.currentAvg,
    this.vllRy,
    this.vllYb,
    this.vllBr,
    this.curR,
    this.curY,
    this.curB,
    required this.timestamp,
  });
}

class Device {
  final String id;
  final String ownerId;
  final String meterSerial;
  final String visibility;
  final DateTime? lastSeen;
  final DeviceReading? lastReading;

  const Device({
    required this.id,
    required this.ownerId,
    required this.meterSerial,
    required this.visibility,
    this.lastSeen,
    this.lastReading,
  });

  Device copyWith({DateTime? lastSeen, DeviceReading? lastReading}) => Device(
        id: id,
        ownerId: ownerId,
        meterSerial: meterSerial,
        visibility: visibility,
        lastSeen: lastSeen ?? this.lastSeen,
        lastReading: lastReading ?? this.lastReading,
      );
}

class FirebaseService {
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseFunctions get _functions => FirebaseFunctions.instance;

  static AppUser? _demoUser;
  static final Map<String, UserProfile> _demoProfiles = {
    'demo-customer': const UserProfile(name: 'Demo Customer', phone: '9876543210', email: 'customer@demo.com'),
    'demo-admin': const UserProfile(name: 'Demo Admin', phone: '9876500000', email: 'admin@demo.com', isAdmin: true),
    'demo-power': const UserProfile(name: 'Demo Meter Owner', phone: '9876511111', email: 'power@demo.com'),
  };
  static final List<Complaint> _demoComplaints = [
    Complaint(
      id: 'CMP-DEMO-001',
      customerId: 'demo-customer',
      name: 'Demo Customer',
      phone: '9876543210',
      meterId: 'MTR-DEMO-001',
      address: 'Shivam Combines Demo Site',
      category: 'Meter fault',
      description: 'Meter display is showing an intermittent error.',
      status: 'in_progress',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];
  static final List<Device> _demoDevices = [
    Device(
      id: 'SHV-DEMO-001',
      ownerId: 'demo-power',
      meterSerial: 'METER-DEMO-001',
      visibility: 'private',
      lastSeen: DateTime.now(),
      lastReading: DeviceReading(
        vllAvg: 413.2,
        currentAvg: 12.4,
        vllRy: 412.9,
        vllYb: 413.1,
        vllBr: 413.6,
        curR: 12.1,
        curY: 12.6,
        curB: 12.5,
        timestamp: DateTime.now(),
      ),
    ),
  ];

  static AppUser? get currentUser {
    if (demoMode) return _demoUser;
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppUser(uid: user.uid, email: user.email ?? '');
  }

  static Stream<AppUser?> authState() {
    if (demoMode) return Stream.value(_demoUser);
    return _auth.authStateChanges().map((u) => u == null ? null : AppUser(uid: u.uid, email: u.email ?? ''));
  }

  static Future<AppUser> signIn(String email, String pass) async {
    if (email.trim().isEmpty || !email.contains('@')) throw Exception('Enter a valid email address.');
    if (pass.length < 6) throw Exception('Password must be at least 6 characters.');
    if (demoMode) {
      final normalized = email.trim().toLowerCase();
      final id = normalized == 'admin@demo.com'
          ? 'demo-admin'
          : normalized == 'power@demo.com'
              ? 'demo-power'
              : 'demo-customer';
      _demoUser = AppUser(uid: id, email: normalized, isAdmin: id == 'demo-admin');
      return _demoUser!;
    }
    final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: pass);
    return AppUser(uid: cred.user!.uid, email: cred.user!.email ?? email.trim());
  }

  static Future<AppUser> signUp(String email, String pass) async {
    if (email.trim().isEmpty || !email.contains('@')) throw Exception('Enter a valid email address.');
    if (pass.length < 6) throw Exception('Password must be at least 6 characters.');
    if (demoMode) {
      final uid = 'demo-${DateTime.now().millisecondsSinceEpoch}';
      _demoProfiles[uid] = UserProfile(name: 'Demo User', phone: '', email: email.trim());
      _demoUser = AppUser(uid: uid, email: email.trim());
      return _demoUser!;
    }
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: pass);
    return AppUser(uid: cred.user!.uid, email: cred.user!.email ?? email.trim());
  }

  static Future<void> signOut() async {
    if (demoMode) {
      _demoUser = null;
      return;
    }
    await _auth.signOut();
  }

  static Future<void> createUserProfile({
    required String uid,
    required String name,
    required String phone,
    required String email,
    bool isAdmin = false,
  }) async {
    if (demoMode) {
      _demoProfiles[uid] = UserProfile(name: name, phone: phone, email: email, isAdmin: isAdmin);
      return;
    }
    // Admin status is intentionally ignored here. Admin accounts must be provisioned
    // server-side; clients must never be allowed to self-promote.
    await _db.collection('users').doc(uid).set({
      'name': name,
      'phone': phone,
      'email': email,
      'isAdmin': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<UserProfile?> getUserProfile(String uid) async {
    if (demoMode) return _demoProfiles[uid];
    final snap = await _db.collection('users').doc(uid).get();
    final d = snap.data();
    if (d == null) return null;
    return UserProfile(
      name: (d['name'] ?? '').toString(),
      phone: (d['phone'] ?? '').toString(),
      email: (d['email'] ?? '').toString(),
      isAdmin: d['isAdmin'] == true,
    );
  }

  static Future<int> adminCount() async {
    if (demoMode) return _demoProfiles.values.where((p) => p.isAdmin).length;
    final snap = await _db.collection('users').where('isAdmin', isEqualTo: true).get();
    return snap.docs.length;
  }

  static Stream<List<Device>> myDevices(String uid) {
    if (demoMode) return Stream.periodic(const Duration(milliseconds: 700), (_) => _demoDevices.where((d) => d.ownerId == uid).toList());
    return _db.collection('devices').where('ownerId', isEqualTo: uid).snapshots().map((snap) => snap.docs.map(_deviceFromDoc).toList());
  }

  static Device _deviceFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final last = d['lastReading'] as Map<String, dynamic>?;
    final ts = last?['timestamp'];
    return Device(
      id: doc.id,
      ownerId: (d['ownerId'] ?? '').toString(),
      meterSerial: (d['meterSerial'] ?? '').toString(),
      visibility: (d['visibility'] ?? 'private').toString(),
      lastSeen: (d['lastSeen'] as Timestamp?)?.toDate(),
      lastReading: last == null
          ? null
          : DeviceReading(
              vllAvg: ((last['vll_avg'] ?? 0) as num).toDouble(),
              currentAvg: ((last['cur_avg'] ?? 0) as num).toDouble(),
              vllRy: (last['vll_ry'] as num?)?.toDouble(),
              vllYb: (last['vll_yb'] as num?)?.toDouble(),
              vllBr: (last['vll_br'] as num?)?.toDouble(),
              curR: (last['cur_r'] as num?)?.toDouble(),
              curY: (last['cur_y'] as num?)?.toDouble(),
              curB: (last['cur_b'] as num?)?.toDouble(),
              timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
            ),
    );
  }

  static Future<Map<String, dynamic>> pairDevice(String deviceId, String meterSerial) async {
    if (deviceId.trim().isEmpty || meterSerial.trim().isEmpty) throw Exception('Device ID and meter serial are required.');
    if (demoMode) {
      final apiKey = List.generate(24, (_) => Random().nextInt(16).toRadixString(16)).join();
      final ownerId = currentUser?.uid ?? 'demo-power';
      _demoDevices.add(Device(id: deviceId.trim(), ownerId: ownerId, meterSerial: meterSerial.trim(), visibility: 'private', lastSeen: DateTime.now(), lastReading: DeviceReading(vllAvg: 415.0, currentAvg: 8.6, vllRy: 414.7, vllYb: 415.2, vllBr: 415.1, curR: 8.3, curY: 8.7, curB: 8.8, timestamp: DateTime.now())));
      return {'deviceId': deviceId.trim(), 'apiKey': apiKey};
    }
    final result = await _functions.httpsCallable('createDevice').call({'deviceId': deviceId.trim(), 'meterSerial': meterSerial.trim()});
    return Map<String, dynamic>.from(result.data);
  }

  static Future<void> updateSharing(String deviceId, String visibility, List<String> emails) async {
    if (demoMode) return;
    await _functions.httpsCallable('updateSharing').call({'deviceId': deviceId, 'visibility': visibility, 'sharedEmails': emails});
  }

  static Future<void> submitComplaint(Map<String, dynamic> data) async {
    if (demoMode) {
      _demoComplaints.insert(0, Complaint(
        id: 'CMP-DEMO-${DateTime.now().millisecondsSinceEpoch}',
        customerId: (data['customerId'] ?? '').toString(),
        name: (data['name'] ?? '').toString(),
        phone: (data['phone'] ?? '').toString(),
        meterId: (data['meterId'] ?? '').toString(),
        address: (data['address'] ?? '').toString(),
        category: (data['category'] ?? 'Other').toString(),
        description: (data['description'] ?? '').toString(),
        status: 'new',
        createdAt: DateTime.now(),
      ));
      return;
    }
    await _db.collection('complaints').add({...data, 'status': 'new', 'createdAt': FieldValue.serverTimestamp()});
  }

  static Stream<List<Complaint>> myComplaints(String uid) {
    if (demoMode) return Stream.periodic(const Duration(milliseconds: 700), (_) => _demoComplaints.where((c) => c.customerId == uid).toList());
    return _db.collection('complaints').where('customerId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots().map((snap) => snap.docs.map(_complaintFromDoc).toList());
  }

  static Stream<List<Complaint>> allComplaints() {
    if (demoMode) return Stream.periodic(const Duration(milliseconds: 700), (_) => List.unmodifiable(_demoComplaints));
    return _db.collection('complaints').orderBy('createdAt', descending: true).snapshots().map((snap) => snap.docs.map(_complaintFromDoc).toList());
  }

  static Complaint _complaintFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Complaint(
      id: doc.id,
      customerId: (d['customerId'] ?? '').toString(),
      name: (d['name'] ?? '').toString(),
      phone: (d['phone'] ?? '').toString(),
      meterId: (d['meterId'] ?? '').toString(),
      address: (d['address'] ?? '').toString(),
      category: (d['category'] ?? '').toString(),
      description: (d['description'] ?? '').toString(),
      status: (d['status'] ?? 'new').toString(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Future<void> updateComplaintStatus(String id, String status) async {
    if (demoMode) {
      final i = _demoComplaints.indexWhere((c) => c.id == id);
      if (i >= 0) _demoComplaints[i] = _demoComplaints[i].copyWith(status: status);
      return;
    }
    await _db.collection('complaints').doc(id).update({'status': status});
  }
}
