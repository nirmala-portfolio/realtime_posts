// lib/feed_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _controller = TextEditingController();
  final _db = FirebaseDatabase.instance;
  late final DatabaseReference _postsRef;

  @override
  void initState() {
    super.initState();
    _postsRef = _db.ref('posts');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String> _getDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Anonymous';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    // fallback: try reading from /users/{uid}/displayName if you stored it there
    final snap = await FirebaseDatabase.instance
        .ref('users/${user.uid}/displayName')
        .get();
    if (snap.exists && snap.value != null) return snap.value.toString();
    return user.email ?? 'User';
  }

  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _controller.text.trim();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in')),
      );
      return;
    }
    if (text.isEmpty) return;

    final displayName = await _getDisplayName();

    try {
      final newRef = _postsRef.push();
      await newRef.set({
        'uid': user.uid,
        'displayName': displayName,
        'caption': text,
        'likes': 0,
        // Realtime Database server timestamp:
        'createdAt': ServerValue.timestamp,
      });
      _controller.clear();
    } catch (e) {
      debugPrint('Error writing post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post: $e')),
      );
    }
  }

  Future<void> _incrementLikes(String key) async {
    final likeRef = _postsRef.child(key).child('likes');
    try {
      final snap = await likeRef.get();
      final current = (snap.value is int) ? snap.value as int : int.tryParse('${snap.value}') ?? 0;
      await likeRef.set(current + 1);
    } catch (e) {
      debugPrint('Error incrementing likes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like: $e')),
      );
    }
  }

  List<_Post> _mapSnapshotToList(DatabaseEvent event) {
    final val = event.snapshot.value;
    if (val == null) return [];
    final map = Map<String, dynamic>.from(val as Map);
    final list = <_Post>[];
    map.forEach((key, raw) {
      try {
        final r = Map<String, dynamic>.from(raw as Map);
        final created = r['createdAt'];
        int createdMs = 0;
        if (created is int) {
          createdMs = created;
        } else if (created is double) {
          createdMs = created.toInt();
        } else if (created is String) {
          createdMs = int.tryParse(created) ?? 0;
        }
        final likes = (r['likes'] is int) ? r['likes'] as int : int.tryParse('${r['likes']}') ?? 0;
        list.add(_Post(
          key: key,
          uid: r['uid']?.toString() ?? '',
          displayName: r['displayName']?.toString() ?? '',
          caption: r['caption']?.toString() ?? '',
          createdAtMillis: createdMs,
          likes: likes,
        ));
      } catch (_) {
        // skip malformed entry
      }
    });
    // newest first
    list.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Write a post...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _createPost,
                  child: const Text('Post'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _postsRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('No posts yet.'));
                }

                final posts = _mapSnapshotToList(snapshot.data!);
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, i) {
                    final p = posts[i];
                    final time = p.createdAtMillis > 0
                        ? DateTime.fromMillisecondsSinceEpoch(p.createdAtMillis)
                        : null;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(p.caption),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p.displayName} • ${time != null ? _formatTime(time) : 'just now'}'),
                            const SizedBox(height: 4),
                          ],
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite),
                              onPressed: () => _incrementLikes(p.key),
                            ),
                            Text('${p.likes}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _Post {
  final String key;
  final String uid;
  final String displayName;
  final String caption;
  final int createdAtMillis;
  final int likes;

  _Post({
    required this.key,
    required this.uid,
    required this.displayName,
    required this.caption,
    required this.createdAtMillis,
    required this.likes,
  });
}
