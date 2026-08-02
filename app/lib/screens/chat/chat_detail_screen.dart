import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';

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
  final _searchController = TextEditingController();
  String _otherUserName = '';
  String _listingTitle = '';
  bool _isSearching = false;
  final ValueNotifier<bool> _showScrollToBottom = ValueNotifier(false);
  Stream<DocumentSnapshot>? _otherUserStatusStream;
  StreamSubscription<DocumentSnapshot>? _otherUserStatusSub;
  DateTime? _otherUserLastSeen;
  Stream<DocumentSnapshot>? _chatStream;
  StreamSubscription<DocumentSnapshot>? _chatStreamSub;
  bool _isOtherUserTyping = false;
  DateTime? _lastTypingUpdate;
  bool _isTyping = false;
  Map<String, dynamic>? _replyToMessage;
  ChatProvider? _chatProvider;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    _uid = context.read<AuthProvider>().firebaseUser?.uid;
    _loadMeta();
    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().firebaseUser!.uid;
      _chatProvider!.markAsRead(widget.chatId, uid);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final currentScroll = _scrollController.position.pixels;
    _showScrollToBottom.value = currentScroll > 200;
  }

  void _onTextChanged() {
    final text = _messageController.text;
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final hasText = text.trim().isNotEmpty;

    if (hasText == _isTyping) return;

    final now = DateTime.now();
    if (_lastTypingUpdate != null && now.difference(_lastTypingUpdate!).inSeconds < 3) {
      return;
    }

    _isTyping = hasText;
    _lastTypingUpdate = now;
    context.read<ChatProvider>().setTyping(widget.chatId, uid, hasText);
  }

  Widget _buildStatusText() {
    if (_isOtherUserTyping) {
      return Row(
        children: [
          Text(
            'typing',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 2),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      );
    }

    if (_otherUserLastSeen == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final diff = now.difference(_otherUserLastSeen!);
    final isOnline = diff.inMinutes < 2;

    String statusText;
    if (isOnline) {
      statusText = 'online';
    } else if (diff.inMinutes < 60) {
      statusText = 'last seen ${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      statusText = 'last seen ${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      statusText = 'last seen yesterday';
    } else {
      statusText = 'last seen ${diff.inDays}d ago';
    }

    return Row(
      children: [
        if (isOnline)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(
              color: Colors.lightGreenAccent,
              shape: BoxShape.circle,
            ),
          ),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Future<void> _loadMeta() async {
    final chatProvider = context.read<ChatProvider>();
    final uid = context.read<AuthProvider>().firebaseUser!.uid;

    String otherUserId = widget.otherUserId;
    if (otherUserId.isEmpty) {
      final chatDoc = await FirebaseFirestore.instance
          .collection(AppConstants.collectionChats)
          .doc(widget.chatId)
          .get();
      final data = chatDoc.data();
      if (data != null) {
        final donorId = data['donorId'] as String? ?? '';
        final distributorId = data['distributorId'] as String? ?? '';
        otherUserId = uid == donorId ? distributorId : donorId;
      }
    }

    final results = await Future.wait([
      chatProvider.getOtherUserName(otherUserId),
      _loadListingTitle(chatProvider),
    ]);
    if (mounted) {
      setState(() {
        _otherUserName = results[0];
        _listingTitle = results[1];
      });

      _otherUserStatusStream = chatProvider.getOtherUserStatus(otherUserId);
      _otherUserStatusSub = _otherUserStatusStream!.listen((doc) {
        if (!mounted) return;
        final data = doc.data() as Map<String, dynamic>?;
        final lastSeen = (data?['lastSeen'] as Timestamp?)?.toDate();
        if (mounted) {
          setState(() => _otherUserLastSeen = lastSeen);
        }
      });

      _chatStream = chatProvider.getChatStream(widget.chatId);
      _chatStreamSub = _chatStream!.listen((doc) {
        if (!mounted) return;
        final data = doc.data() as Map<String, dynamic>?;
        final typing = List<String>.from(data?['typing'] as List<dynamic>? ?? []);
        final otherUserId = widget.otherUserId;
        if (mounted) {
          setState(() => _isOtherUserTyping = typing.contains(otherUserId));
        }
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
    if (_uid != null) {
      _chatProvider?.setTyping(widget.chatId, _uid!, false);
    }
    _otherUserStatusSub?.cancel();
    _chatStreamSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _showScrollToBottom.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final replyId = _replyToMessage?['id'] as String?;
    final replyText = _replyToMessage?['text'] as String?;
    final replySender = _replyToMessage?['senderName'] as String?;

    try {
      await context.read<ChatProvider>().sendMessage(
            chatId: widget.chatId,
            senderId: uid,
            text: text,
            replyToId: replyId,
            replyToText: replyText,
            replyToSender: replySender,
          );
      _messageController.clear();
      setState(() => _replyToMessage = null);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send message')),
      );
      return;
    }

    _isTyping = false;
    _chatProvider?.setTyping(widget.chatId, uid, false);

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _setReplyTo(Map<String, dynamic> message) {
    setState(() => _replyToMessage = message);
  }

  void _forwardMessage(String text) {
    Navigator.pushNamed(
      context,
      Routes.forwardPicker,
      arguments: {'text': text},
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final chatProvider = context.read<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUserName.isNotEmpty ? _otherUserName : 'Chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  _buildStatusText(),
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
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatProvider.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredDocs = _isSearching && _searchController.text.trim().isNotEmpty
                    ? docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final searchableText = data['searchableText'] as String? ??
                            (data['text'] as String? ?? '').toLowerCase();
                        return searchableText.contains(_searchController.text.trim().toLowerCase());
                      }).toList()
                    : docs;

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSearching ? Icons.search_off : Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isSearching ? 'No matching messages' : AppConstants.msgNoMessages,
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: filteredDocs.length,
                  itemBuilder: (_, i) {
                    final doc = filteredDocs[i];
                    final msgData =
                        doc.data() as Map<String, dynamic>;
                    final senderId =
                        msgData['senderId'] as String? ?? '';
                    final text = msgData['text'] as String? ?? '';
                    final isMe = senderId == uid;
                    final timestamp =
                        (msgData['createdAt'] as Timestamp?)?.toDate();
                    final timeStr = timestamp != null
                        ? DateFormat('h:mm a').format(timestamp)
                        : '';
                    final isDeleted =
                        msgData['isDeleted'] as bool? ?? false;
                    final isEdited =
                        msgData['isEdited'] as bool? ?? false;
                    final readBy =
                        (msgData['readBy'] as Map<String, dynamic>?) ?? {};
                    final reactions =
                        (msgData['reactions'] as Map<String, dynamic>?) ?? {};
                    final replyToId = msgData['replyToId'] as String?;
                    final replyToText = msgData['replyToText'] as String?;
                    final replyToSender = msgData['replyToSender'] as String?;

                    final showDateSeparator = i == filteredDocs.length - 1 ||
                        _needsDateSeparator(
                            filteredDocs[i], filteredDocs[i + 1]);

                    return Column(
                      children: [
                        if (showDateSeparator)
                          _DateSeparator(
                              date: timestamp),
                        _MessageBubble(
                          messageId: doc.id,
                          chatId: widget.chatId,
                          senderId: senderId,
                          text: text,
                          time: timeStr,
                          isMe: isMe,
                          isDeleted: isDeleted,
                          isEdited: isEdited,
                          createdAt: timestamp,
                          readBy: readBy,
                          reactions: reactions,
                          searchQuery: _isSearching ? _searchController.text.trim() : '',
                          replyToId: replyToId,
                          replyToText: replyToText,
                          replyToSender: replyToSender,
                          onReply: _setReplyTo,
                          onForward: () => _forwardMessage(text),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_replyToMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to ${_replyToMessage!['senderName'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _replyToMessage!['text'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: Colors.grey[500]),
                    onPressed: () => setState(() => _replyToMessage = null),
                  ),
                ],
              ),
            ),
          _InputBar(
            controller: _messageController,
            onSend: _send,
          ),
        ],
      ),
      Positioned(
        bottom: MediaQuery.of(context).viewPadding.bottom + 72,
        right: 16,
        child: ValueListenableBuilder<bool>(
          valueListenable: _showScrollToBottom,
          builder: (_, show, child) {
            if (!show) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                radius: 18,
                child: Icon(Icons.keyboard_double_arrow_down, color: AppTheme.primaryColor, size: 22),
              ),
            );
          },
        ),
      ),
      ],
      ),
    );
  }

  bool _needsDateSeparator(
      DocumentSnapshot current, DocumentSnapshot next) {
    final curTime =
        (current.data() as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
    final nextTime =
        (next.data() as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
    if (curTime == null || nextTime == null) return false;
    return curTime.toDate().day != nextTime.toDate().day;
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

class _MessageBubble extends StatefulWidget {
  final String messageId;
  final String chatId;
  final String senderId;
  final String text;
  final String time;
  final bool isMe;
  final bool isDeleted;
  final bool isEdited;
  final DateTime? createdAt;
  final Map<String, dynamic> readBy;
  final Map<String, dynamic> reactions;
  final String searchQuery;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSender;
  final ValueChanged<Map<String, dynamic>>? onReply;
  final VoidCallback? onForward;

  const _MessageBubble({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.time,
    required this.isMe,
    this.isDeleted = false,
    this.isEdited = false,
    this.createdAt,
    this.readBy = const {},
    this.reactions = const {},
    this.searchQuery = '',
    this.replyToId,
    this.replyToText,
    this.replyToSender,
    this.onReply,
    this.onForward,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool get _canEdit {
    if (!widget.isMe || widget.isDeleted || widget.createdAt == null) return false;
    return DateTime.now().difference(widget.createdAt!).inMinutes < 30;
  }

  List<TextSpan> _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }
    final lower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(queryLower, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: const TextStyle(
          backgroundColor: Color(0x66FFC107),
          fontWeight: FontWeight.w600,
        ),
      ));
      start = idx + query.length;
    }
    return spans;
  }

  void _showContextMenu() {
    if (widget.isDeleted) return;

    final items = <PopupMenuItem<String>>[];

    items.add(const PopupMenuItem(
      value: 'react',
      child: ListTile(
        leading: Icon(Icons.emoji_emotions_outlined, size: 20),
        title: Text('React'),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    ));

    items.add(const PopupMenuItem(
      value: 'reply',
      child: ListTile(
        leading: Icon(Icons.reply, size: 20),
        title: Text('Reply'),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    ));

    items.add(const PopupMenuItem(
      value: 'forward',
      child: ListTile(
        leading: Icon(Icons.forward, size: 20),
        title: Text('Forward'),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    ));

    items.add(const PopupMenuItem(
      value: 'copy',
      child: ListTile(
        leading: Icon(Icons.copy, size: 20),
        title: Text('Copy'),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    ));

    if (widget.isMe && _canEdit) {
      items.add(const PopupMenuItem(
        value: 'edit',
        child: ListTile(
          leading: Icon(Icons.edit, size: 20),
          title: Text('Edit'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ));
    }

    if (widget.isMe) {
      items.add(const PopupMenuItem(
        value: 'delete',
        child: ListTile(
          leading: Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
          title: Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ));
    }

    if (items.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items,
        ),
      ),
    ).then((value) {
      if (value == null || !mounted) return;
      switch (value) {
        case 'react':
          _showReactionPicker();
          break;
        case 'reply':
          _handleReply();
          break;
        case 'forward':
          if (widget.onForward != null) widget.onForward!();
          break;
        case 'copy':
          Clipboard.setData(ClipboardData(text: widget.text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied')),
          );
          break;
        case 'edit':
          _showEditDialog();
          break;
        case 'delete':
          _confirmDelete();
          break;
      }
    });
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: widget.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty || newText == widget.text) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);
              if (!mounted) return;
              await context.read<ChatProvider>().editMessage(
                    widget.chatId,
                    widget.messageId,
                    newText,
                  );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReactionPicker() {
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final currentReaction = widget.reactions[uid] as String?;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: emojis.map((emoji) {
              final isSelected = currentReaction == emoji;
              return GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  if (isSelected) {
                    await context.read<ChatProvider>().removeReaction(
                          widget.chatId,
                          widget.messageId,
                          uid,
                        );
                  } else {
                    await context.read<ChatProvider>().addReaction(
                          widget.chatId,
                          widget.messageId,
                          uid,
                          emoji,
                        );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _handleReply() async {
    if (widget.onReply == null) return;

    final senderName =
        await context.read<ChatProvider>().getOtherUserName(widget.senderId);

    widget.onReply!({
      'id': widget.messageId,
      'text': widget.text,
      'senderName': senderName,
    });
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (!mounted) return;
              await context.read<ChatProvider>().deleteMessage(
                    widget.chatId,
                    widget.messageId,
                  );
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDeleted) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                'Message deleted',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool isReadByOther = widget.isMe && widget.readBy.isNotEmpty;
    final reactionEntries = widget.reactions.entries.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: _showContextMenu,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
              _handleReply();
            }
          },
          child: Align(
            alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: widget.isMe ? AppTheme.primaryColor : Colors.grey.shade200,
                border: widget.isMe
                    ? null
                    : Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(widget.isMe ? 18 : 6),
                  bottomRight: Radius.circular(widget.isMe ? 6 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.replyToId != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.isMe
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 30,
                            decoration: BoxDecoration(
                              color: widget.isMe
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.replyToSender ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: widget.isMe
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  widget.replyToText ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.isMe
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Builder(
                    builder: (context) {
                      final baseColor = widget.isMe ? Colors.white : Colors.black87;
                      final spans = _buildHighlightedText(widget.text, widget.searchQuery);
                      final styledChildren = spans.map((span) {
                        if (span.style == null) {
                          return TextSpan(
                            text: span.text,
                            style: TextStyle(color: baseColor, fontSize: 15, height: 1.3),
                          );
                        }
                        return TextSpan(
                          text: span.text,
                          style: span.style!.copyWith(color: baseColor, fontSize: 15, height: 1.3),
                        );
                      }).toList();
                      return RichText(text: TextSpan(children: styledChildren));
                    },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isEdited)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            'edited',
                            style: TextStyle(
                              color: widget.isMe
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.grey.shade500,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      Text(
                        widget.time,
                        style: TextStyle(
                          color: widget.isMe
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      if (widget.isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isReadByOther
                              ? Icons.done_all
                              : Icons.done,
                          size: 16,
                          color: isReadByOther
                              ? Colors.lightBlueAccent
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (reactionEntries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _buildReactionChips(reactionEntries),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildReactionChips(List<MapEntry<String, dynamic>> entries) {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;

    final grouped = <String, int>{};
    for (final entry in entries) {
      final emoji = entry.value as String;
      grouped[emoji] = (grouped[emoji] ?? 0) + 1;
    }

    return grouped.entries.map((entry) {
      final emoji = entry.key;
      final count = entry.value;
      final reacted = widget.reactions[uid] == emoji;

      return GestureDetector(
        onTap: () async {
          if (!mounted) return;
          if (reacted) {
            await context.read<ChatProvider>().removeReaction(
                  widget.chatId,
                  widget.messageId,
                  uid,
                );
          } else {
            await context.read<ChatProvider>().addReaction(
                  widget.chatId,
                  widget.messageId,
                  uid,
                  emoji,
                );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: reacted
                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: reacted
                  ? AppTheme.primaryColor.withValues(alpha: 0.4)
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              if (count > 1) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }
}
