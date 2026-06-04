import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../config/theme.dart';

class ForwardPickerScreen extends StatefulWidget {
  final String textToForward;

  const ForwardPickerScreen({required this.textToForward, super.key});

  @override
  State<ForwardPickerScreen> createState() => _ForwardPickerScreenState();
}

class _ForwardPickerScreenState extends State<ForwardPickerScreen> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final chats = await context.read<ChatProvider>().getChatsForUserSimple(uid);
    if (mounted) {
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forward to')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 20),
                      Text(
                        'No chats available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _chats.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final chat = _chats[i];
                    final name = chat['otherUserName'] as String? ?? '';
                    final listing = chat['listingTitle'] as String? ?? '';
                    final initials =
                        name.isNotEmpty ? name[0].toUpperCase() : '?';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.15),
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: listing.isNotEmpty
                          ? Text(
                              listing,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[500]),
                            )
                          : null,
                      onTap: () async {
                        final uid =
                            context.read<AuthProvider>().firebaseUser!.uid;
                        final chatId = chat['chatId'] as String;
                        final chatProvider = context.read<ChatProvider>();
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        await chatProvider.forwardMessage(
                              chatId: chatId,
                              senderId: uid,
                              text: widget.textToForward,
                            );
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                              content: Text('Message forwarded')),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
