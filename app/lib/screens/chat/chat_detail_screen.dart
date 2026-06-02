import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatDetailScreen({
    required this.chatId,
    required this.otherUserId,
    super.key,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _otherUserName = '';
  String _listingTitle = '';
  int _prevDocCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMeta();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().firebaseUser!.uid;
      context.read<ChatProvider>().markAsRead(widget.chatId, uid);
      _scrollToBottom();
    });
  }

  Future<void> _loadMeta() async {
    final chatProvider = context.read<ChatProvider>();
    final results = await Future.wait([
      chatProvider.getOtherUserName(widget.otherUserId),
      _loadListingTitle(chatProvider),
    ]);
    if (mounted) {
      setState(() {
        _otherUserName = results[0];
        _listingTitle = results[1];
      });
    }
  }

  Future<String> _loadListingTitle(ChatProvider provider) async {
    final chatDoc = await FirebaseFirestore.instance
        .collection(AppConstants.collectionChats)
        .doc(widget.chatId)
        .get();
    final listingId = chatDoc.data()?['listingId'] as String? ?? '';
    if (listingId.isEmpty) return '';
    return provider.getListingTitle(listingId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    _messageController.clear();

    await context.read<ChatProvider>().sendMessage(
          chatId: widget.chatId,
          senderId: uid,
          text: text,
        );

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final chatProvider = context.read<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _otherUserName.isNotEmpty ? _otherUserName : 'Chat',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            if (_listingTitle.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _listingTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatProvider.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  _prevDocCount = 0;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          AppConstants.msgNoMessages,
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                if (docs.length > _prevDocCount && _prevDocCount > 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }
                _prevDocCount = docs.length;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final msgData =
                        docs[i].data() as Map<String, dynamic>;
                    final senderId =
                        msgData['senderId'] as String? ?? '';
                    final text = msgData['text'] as String? ?? '';
                    final isMe = senderId == uid;
                    final timestamp =
                        (msgData['createdAt'] as Timestamp?)?.toDate();
                    final timeStr = timestamp != null
                        ? DateFormat('h:mm a').format(timestamp)
                        : '';

                    final showDateSeparator = i == 0 ||
                        _needsDateSeparator(
                            docs[i - 1], docs[i]);

                    return Column(
                      children: [
                        if (showDateSeparator)
                          _DateSeparator(
                              date: timestamp),
                        _MessageBubble(
                          text: text,
                          time: timeStr,
                          isMe: isMe,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(
            controller: _messageController,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  bool _needsDateSeparator(
      DocumentSnapshot prev, DocumentSnapshot current) {
    final prevTime =
        (prev.data() as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
    final curTime =
        (current.data() as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
    if (prevTime == null || curTime == null) return false;
    return prevTime.toDate().day != curTime.toDate().day;
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime? date;

  const _DateSeparator({this.date});

  @override
  Widget build(BuildContext context) {
    if (date == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date!.year, date!.month, date!.day);
    final diff = today.difference(messageDay).inDays;

    String label;
    if (diff == 0) {
      label = 'Today';
    } else if (diff == 1) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d, y').format(date!);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _sendScale;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _sendScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _animController.forward();
  void _onTapUp(TapUpDetails _) {
    _animController.reverse();
    widget.onSend();
  }
  void _onTapCancel() => _animController.reverse();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: AppConstants.msgChatHint,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                textInputAction: TextInputAction.newline,
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              child: ScaleTransition(
                scale: _sendScale,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : Colors.grey.shade200,
          border: isMe
              ? null
              : Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
