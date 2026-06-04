import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';

class ArchivedChatsScreen extends StatelessWidget {
  const ArchivedChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final chatProvider = context.read<ChatProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Archived Chats')),
      body: StreamBuilder<List<QuerySnapshot>>(
        stream: _combineChats(chatProvider, uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(AppConstants.msgSomethingWentWrong,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          final allDocs = snapshot.data ?? [];
          var docs = allDocs.expand((s) => s.docs).toList();

          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final archivedBy =
                List<String>.from(data['archivedBy'] as List<dynamic>? ?? []);
            return archivedBy.contains(uid);
          }).toList();

          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime =
                (aData['lastMessageAt'] as Timestamp?)?.toDate() ??
                    DateTime(0);
            final bTime =
                (bData['lastMessageAt'] as Timestamp?)?.toDate() ??
                    DateTime(0);
            return bTime.compareTo(aTime);
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.archive_outlined,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text(
                    'No archived chats',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: docs.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 76),
            itemBuilder: (_, i) => _ArchivedChatTile(
              chat: docs[i],
              currentUid: uid,
            ),
          );
        },
      ),
    );
  }

  Stream<List<QuerySnapshot>> _combineChats(
      ChatProvider provider, String uid) async* {
    final donorStream = provider.getChatsForUser(uid);
    final distributorStream =
        provider.getChatsForUserAsDistributor(uid);

    await for (final donorSnap in donorStream) {
      await for (final distSnap in distributorStream) {
        yield [donorSnap, distSnap];
      }
    }
  }
}

class _ArchivedChatTile extends StatefulWidget {
  final DocumentSnapshot chat;
  final String currentUid;

  const _ArchivedChatTile({required this.chat, required this.currentUid});

  @override
  State<_ArchivedChatTile> createState() => _ArchivedChatTileState();
}

class _ArchivedChatTileState extends State<_ArchivedChatTile> {
  String _otherUserName = '';
  String _listingTitle = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant _ArchivedChatTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chat.id != widget.chat.id) _loadData();
  }

  Future<void> _loadData() async {
    final data = widget.chat.data() as Map<String, dynamic>;
    final donorId = data['donorId'] as String? ?? '';
    final distributorId = data['distributorId'] as String? ?? '';
    final otherUserId =
        widget.currentUid == donorId ? distributorId : donorId;
    final listingId = data['listingId'] as String? ?? '';

    final chatProvider = context.read<ChatProvider>();
    final results = await Future.wait([
      chatProvider.getOtherUserName(otherUserId),
      chatProvider.getListingTitle(listingId),
    ]);

    if (mounted) {
      setState(() {
        _otherUserName = results[0];
        _listingTitle = results[1];
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.chat.data() as Map<String, dynamic>;
    final donorId = data['donorId'] as String? ?? '';
    final distributorId = data['distributorId'] as String? ?? '';
    final otherUserId =
        widget.currentUid == donorId ? distributorId : donorId;
    final lastMessage = data['lastMessage'] as String? ?? '';
    final lastMessageAt =
        (data['lastMessageAt'] as Timestamp?)?.toDate();

    final timeStr =
        lastMessageAt != null ? _relativeTime(lastMessageAt) : '';
    final initials = _otherUserName.isNotEmpty
        ? _otherUserName[0].toUpperCase()
        : '?';

    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.unarchive),
                  title: const Text('Unarchive'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await context.read<ChatProvider>().unarchiveChat(
                        widget.chat.id, widget.currentUid);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                  title: const Text('Delete',
                      style: TextStyle(color: AppTheme.errorColor)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await context.read<ChatProvider>().deleteChatForMe(
                        widget.chat.id, widget.currentUid);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.chatDetail,
            arguments: {
              'chatId': widget.chat.id,
              'otherUserId': otherUserId,
            },
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _loaded ? _otherUserName : 'Loading...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (_listingTitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          _listingTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Text(
                      lastMessage.isNotEmpty
                          ? lastMessage
                          : 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.month}/${date.day}';
  }
}
