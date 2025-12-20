# Custom ID Generation System 🆔

## Overview

This system provides human-readable, meaningful IDs for Firestore documents instead of random auto-generated IDs. This makes it easier to identify and debug documents directly in the Firestore console.

## ID Formats

### 1. **Subscriptions**
**Format:** `SUB-{YEAR}{SEMESTER}-{INITIALS}-{TIMESTAMP}`

**Examples:**
- `SUB-2024F-JD-1734567890` - Fall 2024, John Doe
- `SUB-2025S-MA-1734567891` - Spring 2025, Marie Antoinette
- `SUB-2024W-AB-1734567892` - Winter 2024, Alice Brown

**Components:**
- `SUB` - Prefix identifying subscriptions
- `{YEAR}` - Subscription year (e.g., 2024)
- `{SEMESTER}` - First letter of semester (F=Fall, S=Spring, W=Winter)
- `{INITIALS}` - Student name initials (2-3 letters)
- `{TIMESTAMP}` - Unix timestamp in seconds for uniqueness

### 2. **Bus Stops**
**Format:** `STOP-{NAME_SLUG}-{HASH}`

**Examples:**
- `STOP-POSTE-CENTRALE-A1B2` - Poste Centrale stop
- `STOP-CAMPUS-NORD-C3D4` - Campus Nord stop
- `STOP-GARE-ROUTIERE-E5F6` - Gare Routière stop

**Components:**
- `STOP` - Prefix identifying bus stops
- `{NAME_SLUG}` - URL-friendly version of stop name (uppercase, max 20 chars)
- `{HASH}` - 4-character alphanumeric hash for uniqueness

### 3. **Students**
**Format:** `STU-{EMAIL_PREFIX}-{HASH}`

**Examples:**
- `STU-JOHN-DOE-A1B2` - john.doe@example.com
- `STU-MARIE-CURIE-C3D4` - marie.curie@example.com
- `STU-ALICE-BROWN-E5F6` - alice.brown@example.com

**Components:**
- `STU` - Prefix identifying students
- `{EMAIL_PREFIX}` - Part before @ in email (slugified)
- `{HASH}` - 4-character alphanumeric hash for uniqueness

### 4. **Admins**
**Format:** `ADM-{EMAIL_PREFIX}-{HASH}`

**Examples:**
- `ADM-ADMIN-USER-A1B2` - admin.user@example.com
- `ADM-SUPER-ADMIN-C3D4` - super.admin@example.com

**Components:**
- `ADM` - Prefix identifying admins
- `{EMAIL_PREFIX}` - Part before @ in email (slugified)
- `{HASH}` - 4-character alphanumeric hash for uniqueness

### 5. **Semesters**
**Format:** `SEM-{YEAR}{SEMESTER}`

**Examples:**
- `SEM-2024F` - Fall 2024
- `SEM-2025S` - Spring 2025
- `SEM-2024W` - Winter 2024

**Components:**
- `SEM` - Prefix identifying semesters
- `{YEAR}` - Semester year
- `{SEMESTER}` - First letter of semester name

## Usage

### Creating a Subscription

```dart
// In SubscriptionsController or similar
final subscription = await SubscriptionService.instance.createSubscription(
  subscription: BusSubscription(...),
  proofUrl: proofImageUrl,
  studentName: 'John Doe', // Required for ID generation
);

// Generated ID will be like: SUB-2024F-JD-1734567890
```

### Creating a Bus Stop

```dart
// In BusStopsController or similar
final stop = await BusStopService.instance.createBusStop(
  BusStop(
    id: '', // Leave empty, will be auto-generated
    name: 'Poste Centrale',
    // ... other fields
  ),
  currentUserId,
);

// Generated ID will be like: STOP-POSTE-CENTRALE-A1B2
```

### Creating a User

```dart
// In AuthService or similar
final userId = await AuthService.instance.createUserDocument(
  email: 'john.doe@example.com',
  name: 'John Doe',
  role: UserRole.student,
  // ... other fields
);

// Generated ID will be like: STU-JOHN-DOE-A1B2
```

## Collision Handling

The system automatically handles ID collisions:

1. **First Attempt:** Generates base ID (e.g., `STOP-POSTE-CENTRALE-A1B2`)
2. **Check Existence:** Queries Firestore to see if ID exists
3. **If Collision:** Appends suffix `-1`, `-2`, etc. (e.g., `STOP-POSTE-CENTRALE-A1B2-1`)
4. **Max Attempts:** 10 attempts, then falls back to Firestore auto-ID
5. **Result:** Always returns a unique ID

```dart
// Automatic collision handling
final uniqueId = await IdGenerator.generateUniqueId(
  collection: 'stops',
  baseId: 'STOP-POSTE-CENTRALE-A1B2',
  maxAttempts: 10, // Optional, defaults to 10
);
```

## Utility Methods

### Extract Initials
```dart
IdGenerator._extractInitials('John Doe') // Returns 'JD'
IdGenerator._extractInitials('Marie Antoinette Curie') // Returns 'MAC'
IdGenerator._extractInitials('Alice') // Returns 'AL'
```

### Slugify Text
```dart
IdGenerator._slugify('Poste Centrale') // Returns 'POSTE-CENTRALE'
IdGenerator._slugify('Gare Routière') // Returns 'GARE-ROUTIERE'
IdGenerator._slugify('Campus-Nord!!!') // Returns 'CAMPUS-NORD'
```

### Generate Short Hash
```dart
IdGenerator._generateShortHash() // Returns '4-char hash like 'A1B2'
```

## Benefits

### 1. **Human Readable**
- Easy to identify documents at a glance
- No need to decode random UUIDs
- Meaningful in logs and debugging

### 2. **Searchable**
- Can filter by prefix in Firestore console
- Easy to find related documents
- Better organization

### 3. **Consistent**
- All IDs follow predictable patterns
- Easy to understand structure
- Clear naming conventions

### 4. **Debuggable**
- Can identify document type from prefix
- Embedded metadata (year, semester, etc.)
- Easier troubleshooting

### 5. **Collision-Safe**
- Automatic collision detection
- Incremental suffix on conflict
- Fallback to auto-generated IDs

## Migration

For existing documents with auto-generated IDs:

### Option 1: Leave As-Is
- Old documents keep their IDs
- New documents get custom IDs
- No migration needed

### Option 2: Gradual Migration
- Create new documents with custom IDs
- Update references over time
- Deprecate old IDs gradually

### Option 3: Batch Migration
```dart
// Example migration script (use with caution)
Future<void> migrateSubscriptions() async {
  final oldDocs = await FirebaseFirestore.instance
      .collection('subscriptions')
      .get();
  
  for (final doc in oldDocs.docs) {
    final data = doc.data();
    final newId = IdGenerator.generateSubscriptionId(
      studentName: data['studentName'],
      year: data['year'],
      semester: data['semester'],
    );
    
    // Create new doc with custom ID
    await FirebaseFirestore.instance
        .collection('subscriptions')
        .doc(newId)
        .set(data);
    
    // Delete old doc
    await doc.reference.delete();
  }
}
```

## Best Practices

### 1. **Always Provide Required Data**
```dart
// ✅ Good - Provides student name for initials
createSubscription(
  subscription: subscription,
  studentName: student.name,
);

// ❌ Bad - Missing student name, will use 'Student' as fallback
createSubscription(
  subscription: subscription,
);
```

### 2. **Handle Uniqueness**
```dart
// ✅ Good - Uses generateUniqueId with collision check
final id = await IdGenerator.generateUniqueId(
  collection: 'stops',
  baseId: baseId,
);

// ❌ Bad - Direct generation without collision check
final id = IdGenerator.generateBusStopId(stopName);
```

### 3. **Log Generated IDs**
```dart
// ✅ Good - Logs for debugging
if (kDebugMode) {
  debugPrint('[Service] Created document with ID: $customId');
}
```

## Firestore Console View

With custom IDs, your Firestore console will look like:

```
📁 subscriptions
  ├── SUB-2024F-JD-1734567890
  ├── SUB-2024F-MA-1734567891
  ├── SUB-2025S-AB-1734567892
  └── SUB-2025S-CD-1734567893

📁 stops
  ├── STOP-POSTE-CENTRALE-A1B2
  ├── STOP-CAMPUS-NORD-C3D4
  └── STOP-GARE-ROUTIERE-E5F6

📁 users
  ├── STU-JOHN-DOE-A1B2
  ├── STU-MARIE-CURIE-C3D4
  └── ADM-ADMIN-USER-E5F6
```

Much easier to navigate than random IDs! 🎉

## Implementation Files

- **ID Generator:** `lib/utils/id_generator.dart`
- **Subscription Service:** `lib/services/subscription_service.dart`
- **Bus Stop Service:** `lib/services/bus_stop_service.dart`
- **Auth Service:** `lib/services/auth_service.dart`
- **Semester Service:** `lib/services/semester_service.dart` (already had custom IDs)

---

**The custom ID system is now fully implemented and ready to use!** 🚀

