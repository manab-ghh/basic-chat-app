import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/message_provider.dart';
import 'package:frontend/providers/socket_provider.dart';
import 'package:frontend/widgets/error_widget.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import 'widgets/message_bubble.dart';
import 'widgets/typing_indicator.dart';
import 'widgets/chat_input_field.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final UserModel otherUser;

  const ChatScreen({super.key, required this.chatId, required this.otherUser});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasScrolledToBottomInitially = false;
  bool _isCurrentlyTyping = false;
  Timer? _typingStopTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _typingStopTimer?.cancel();
    if (_isCurrentlyTyping) {
      ref
          .read(socketServiceProvider)
          .emitStopTyping(widget.chatId, widget.otherUser.id);
    }
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(chatMessagesProvider(widget.chatId).notifier).loadMore();
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _onTextChanged(String value) {
    final socketService = ref.read(socketServiceProvider);

    if (value.isNotEmpty && !_isCurrentlyTyping) {
      _isCurrentlyTyping = true;
      socketService.emitTyping(widget.chatId, widget.otherUser.id);
    }

    // Debounce stop_typing: reset the timer on every keystroke, only fire
    // stop_typing after the user pauses for 1.5s.
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_isCurrentlyTyping) {
        _isCurrentlyTyping = false;
        socketService.emitStopTyping(widget.chatId, widget.otherUser.id);
      }
    });

    if (value.isEmpty && _isCurrentlyTyping) {
      _isCurrentlyTyping = false;
      _typingStopTimer?.cancel();
      socketService.emitStopTyping(widget.chatId, widget.otherUser.id);
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    _textController.clear();

    // Stop typing indicator immediately on send
    _typingStopTimer?.cancel();
    if (_isCurrentlyTyping) {
      _isCurrentlyTyping = false;
      ref
          .read(socketServiceProvider)
          .emitStopTyping(widget.chatId, widget.otherUser.id);
    }

    await ref
        .read(chatMessagesProvider(widget.chatId).notifier)
        .sendMessage(receiverId: widget.otherUser.id, text: text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatMessagesProvider(widget.chatId));
    final currentUserId = ref.watch(authProvider).user?.id ?? '';
    final onlineUsers = ref.watch(onlineUsersProvider);
    final isOtherUserOnline =
        onlineUsers.contains(widget.otherUser.id) || widget.otherUser.isOnline;

    ref.listen(chatMessagesProvider(widget.chatId), (previous, next) {
      final gotNewMessage =
          previous != null && next.messages.length > previous.messages.length;
      final justFinishedLoading =
          !next.isLoading &&
          !_hasScrolledToBottomInitially &&
          next.messages.isNotEmpty;

      if (justFinishedLoading) {
        _hasScrolledToBottomInitially = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else if (gotNewMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: AppColors.chatBackground,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              backgroundImage: widget.otherUser.avatar.isNotEmpty
                  ? CachedNetworkImageProvider(widget.otherUser.avatar)
                  : null,
              child: widget.otherUser.avatar.isEmpty
                  ? Text(
                      widget.otherUser.name.isNotEmpty
                          ? widget.otherUser.name[0].toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.otherUser.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isOtherUserOnline ? 'Online' : 'Offline',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(state, currentUserId)),
          if (state.typingUserIds.isNotEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: TypingIndicator(),
            ),
          ChatInputField(
            controller: _textController,
            onSend: _sendMessage,
            onChanged: _onTextChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatMessagesState state, String currentUserId) {
    if (state.isLoading) return const LoadingIndicator();

    if (state.error != null && state.messages.isEmpty) {
      return ErrorStateWidget(
        message: state.error!,
        onRetry: () => ref
            .read(chatMessagesProvider(widget.chatId).notifier)
            .loadInitial(),
      );
    }

    if (state.messages.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: AppStrings.noMessagesYet,
      );
    }

    final reversedMessages = state.messages.reversed.toList();

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: reversedMessages.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == reversedMessages.length) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final message = reversedMessages[index];
        return MessageBubble(
          message: message,
          isMe: message.senderId == currentUserId,
        );
      },
    );
  }
}
