import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/widgets/error_widget.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import 'widgets/chat_list_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatListState = ref.watch(chatListProvider);
    final currentUser = ref.watch(authProvider).user;

    if (currentUser == null) {
      // Shouldn't happen given router guards, but guards against a null-state edge case.
      return const Scaffold(body: LoadingIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: chatListState.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.read(chatListProvider.notifier).loadChats(),
        ),
        data: (chats) {
          if (chats.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: AppStrings.noChatsYet,
              subtitle: AppStrings.noChatsSubtitle,
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(chatListProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 78),
              itemBuilder: (context, index) {
                final chat = chats[index];
                final otherUser = chat.otherParticipant(currentUser.id);
                return ChatListTile(
                  chat: chat,
                  currentUserId: currentUser.id,
                  onTap: () =>
                      context.push('/chat/${chat.id}', extra: otherUser),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/search'),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}
