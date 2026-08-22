import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_strings.dart';

class MessageInput extends StatefulWidget {
  final FocusNode focusNode;
  final Function(String) onSend;
  final Function(String) onTyping;
  final Function(String) onSendImage;
  final Function(String) onSendFile;

  const MessageInput({
    super.key,
    required this.focusNode,
    required this.onSend,
    required this.onTyping,
    required this.onSendImage,
    required this.onSendFile,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isComposing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSend(_controller.text.trim());
      _controller.clear();
      setState(() {
        _isComposing = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      widget.onSendImage(image.path);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        widget.onSendFile(file.path!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button
          PopupMenuButton<String>(
            icon: Icon(Icons.attach_file, color: AppTheme.primaryColor),
            onSelected: (value) {
              if (value == 'image') {
                _pickImage();
              } else if (value == 'file') {
                _pickFile();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'image',
                child: Row(
                  children: [
                    Icon(Icons.image, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    const Text('Photo/Video'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'file',
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    const Text('Document'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(width: 4),

          // Text input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              decoration: InputDecoration(
                hintText: AppStrings.typeMessage,
                hintStyle: TextStyle(color: AppTheme.hintColor),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              onChanged: (text) {
                setState(() {
                  _isComposing = text.isNotEmpty;
                });
                widget.onTyping(text);
              },
              onSubmitted: (_) => _handleSend(),
            ),
          ),

          const SizedBox(width: 4),

          // Send button
          CircleAvatar(
            backgroundColor: _isComposing
                ? AppTheme.primaryColor
                : AppTheme.borderColor,
            child: IconButton(
              icon: Icon(
                _isComposing ? Icons.send : Icons.mic,
                color: _isComposing ? Colors.white : AppTheme.hintColor,
                size: 20,
              ),
              onPressed: _isComposing ? _handleSend : null,
            ),
          ),
        ],
      ),
    );
  }
}
