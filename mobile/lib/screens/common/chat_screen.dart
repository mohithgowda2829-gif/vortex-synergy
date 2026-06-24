import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/chat_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../models/chat_message.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state_card.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.claimId,
    required this.title,
  });

  final String claimId;
  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Future<List<ChatMessage>> _future;
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<List<ChatMessage>> _load() async {
    final AuthProvider auth = context.read<AuthProvider>();
    return ChatApi(auth.apiClient).conversation(auth.token!, widget.claimId);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: widget.title,
      onLogout: () => auth.logout(),
      child: Column(
        children: <Widget>[
          Expanded(
            child: FutureBuilder<List<ChatMessage>>(
              future: _future,
              builder: (BuildContext context, AsyncSnapshot<List<ChatMessage>> snapshot) {
                if (snapshot.hasError) {
                  return ListView(
                    children: <Widget>[
                      EmptyStateCard(
                        title: 'Unable to load chat',
                        message: AppFeedback.messageFromError(snapshot.error!),
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                    ],
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final List<ChatMessage> messages = snapshot.data!;
                if (messages.isEmpty) {
                  return ListView(
                    children: const <Widget>[
                      EmptyStateCard(
                        title: 'No messages yet',
                        message: 'Use this conversation to coordinate pickup, delivery, and resource questions.',
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                    ],
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() => _future = _load()),
                  child: ListView.builder(
                    reverse: false,
                    itemCount: messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ChatMessage message = messages[index];
                      final bool mine = message.senderId == auth.user?.id;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 320),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: mine ? const Color(0xFFE7FAF5) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                mine ? 'You' : message.senderName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(message.message),
                              const SizedBox(height: 6),
                              Text(
                                formatDateTime(message.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Type a coordination message',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _sending ? null : _send,
                child: Text(_sending ? 'Sending...' : 'Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final String message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await ChatApi(auth.apiClient).send(auth.token!, claimId: widget.claimId, message: message);
      _messageController.clear();
      if (!mounted) return;
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}
