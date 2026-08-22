import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/widgets/error_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String? _creatingChatForUserId;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    // Debounce to avoid firing a search request on every keystroke
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(userSearchProvider.notifier).search(value);
    });
  }

  Future<void> _startChat(UserModel user) async {
    setState(() => _creatingChatForUserId = user.id);
    try {
      final chat = await ref
          .read(chatListProvider.notifier)
          .openOrCreateChat(user.id);
      if (!mounted) return;

      context.pushReplacement('/chat/${chat.id}', extra: user);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _creatingChatForUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(userSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          style: const TextStyle(color: Colors.black),
          decoration: const InputDecoration(
            hintText: 'Search by name or email...',
            hintStyle: TextStyle(color: Colors.black),
            border: InputBorder.none,
          ),
        ),
      ),
      body: searchState.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorStateWidget(message: error.toString()),
        data: (users) {
          if (_controller.text.trim().isEmpty) {
            return const EmptyState(
              icon: Icons.search,
              title: 'Search for people',
              subtitle: 'Find users by their name or email to start chatting',
            );
          }
          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.person_off_outlined,
              title: AppStrings.noUsersFound,
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isCreating = _creatingChatForUserId == user.id;

              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  backgroundImage: user.avatar.isNotEmpty
                      ? CachedNetworkImageProvider(user.avatar)
                      : null,
                  child: user.avatar.isEmpty
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: isCreating ? null : () => _startChat(user),
              );
            },
          );
        },
      ),
    );
  }
}
