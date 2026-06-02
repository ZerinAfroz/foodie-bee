import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final chatProvider = context.read<ChatProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
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
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text(AppConstants.btnRetry),
                  ),
                ],
              ),
            );
          }

          final allDocs = snapshot.data ?? [];
          final docs = allDocs.expand((s) => s.docs).toList();

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 20),
                    Text(AppConstants.msgNoChats,
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(AppConstants.msgNoChatsCta,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 14)),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        final auth = context.read<AuthProvider>();
                        final role = auth.role;
                        Navigator.pushNamed(
                          context,
                          role == 'donor'
                              ? Routes.myListings
                              : Routes.mapDiscovery,
                        );
                      },
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Find Food'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                Future.delayed(const Duration(milliseconds: 600)),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: docs.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 76),
              itemBuilder: (_, i) => _ChatTile(
                chat: docs[i],
                currentUid: uid,
              ),
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

class _ChatTile extends StatefulWidget {
  final DocumentSnapshot chat;
  final String currentUid;

  const _ChatTile({required this.chat, required this.currentUid});

  @override
  State<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<_ChatTile> {
  String _otherUserName = '';
  String _listingTitle = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant _ChatTile oldWidget) {
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
    final unreadBy =
        List<String>.from(data['unreadBy'] as List<dynamic>? ?? []);
    final isUnread = unreadBy.contains(widget.currentUid);

    final timeStr =
        lastMessageAt != null ? _relativeTime(lastMessageAt) : '';
    final initials = _otherUserName.isNotEmpty
        ? _otherUserName[0].toUpperCase()
        : '?';

    return InkWell(
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
            _AvatarWithBadge(
              initials: initials,
              isUnread: isUnread,
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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread
                              ? AppTheme.primaryColor
                              : Colors.grey[500],
                          fontWeight: isUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
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
                      color: isUnread
                          ? Colors.black87
                          : Colors.grey[500],
                      fontWeight: isUnread
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class _AvatarWithBadge extends StatelessWidget {
  final String initials;
  final bool isUnread;

  const _AvatarWithBadge({
    required this.initials,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: isUnread
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.15),
          child: Text(
            initials,
            style: TextStyle(
              color:
                  isUnread ? Colors.white : AppTheme.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isUnread)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                    BorderSide(color: Colors.white, width: 2)),
              ),
            ),
          ),
      ],
    );
  }
}
