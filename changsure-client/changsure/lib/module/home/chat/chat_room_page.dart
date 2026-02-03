import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/chat/chat_model.dart';
import '../../../../data/models/chat/chat_helper.dart';
import '../../../../state/chat_provider.dart';
import '../../../../state/user_provider.dart';
import '../../../../state/public_technician_provider.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  final int bookingId;
  final String? title;
  final String? otherPersonImg;
  
  final int? technicianId;

  const ChatRoomPage({
    super.key,
    required this.bookingId,
    this.title,
    this.otherPersonImg,
    this.technicianId,
  });

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  ChatParticipantInfo? _participantInfo;

  @override
  void initState() {
    super.initState();
    _resolveParticipantInfo();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _resolveParticipantInfo() async {
    try {
      if (widget.technicianId != null) {
        final profileAsync = ref.read(
          publicTechnicianProvider(widget.technicianId!),
        );

        await profileAsync.when(
          data: (profile) {
            if (profile != null && mounted) {
              setState(() {
                _participantInfo = ChatHelper.fromTechnicianProfile(profile);
              });
            }
          },
          loading: () {},
          error: (_, __) {},
        );
      }

      if (_participantInfo == null && widget.title != null) {
        setState(() {
          _participantInfo = ChatParticipantInfo(
            userId: 0,
            name: widget.title!,
            avatarUrl: widget.otherPersonImg,
          );
        });
      }

      if (_participantInfo == null) {
        setState(() {
          _participantInfo = ChatParticipantInfo.unknown;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _participantInfo = ChatParticipantInfo.unknown;
        });
      }
    }
  }

  Future<void> _onImagePressed() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null && mounted) {
        ref
            .read(chatControllerProvider.notifier)
            .sendImage(widget.bookingId, File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เลือกรูปภาพไม่สำเร็จ: $e')));
      }
    }
  }

  Future<void> _onSendPressed() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    try {
      await ref
          .read(chatControllerProvider.notifier)
          .sendMessage(widget.bookingId, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ส่งข้อความไม่สำเร็จ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatHistoryProvider(widget.bookingId));
    final myId = ref.watch(userProvider)?.id;
    final chatState = ref.watch(chatControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _ChatAppBar(
        participantInfo: _participantInfo,
        isLoading: _participantInfo == null,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _ChatMessagesList(
                messages: messages,
                myId: myId,
                participantInfo: _participantInfo,
                controller: _scrollController,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _ErrorView(
                error: error,
                onRetry: () {
                  ref.invalidate(chatHistoryProvider(widget.bookingId));
                },
              ),
            ),
          ),
          if (chatState.isLoading) const LinearProgressIndicator(minHeight: 2),
          _ChatInputArea(
            controller: _controller,
            onImagePressed: _onImagePressed,
            onSendPressed: _onSendPressed,
            isLoading: chatState.isLoading,
          ),
        ],
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatParticipantInfo? participantInfo;
  final bool isLoading;

  const _ChatAppBar({required this.participantInfo, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading || participantInfo == null) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'กำลังโหลด...',
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      iconTheme: const IconThemeData(color: Colors.black),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[300],
            backgroundImage:
                participantInfo!.avatarUrl != null &&
                    participantInfo!.avatarUrl!.isNotEmpty
                ? NetworkImage(participantInfo!.avatarUrl!)
                : null,
            child:
                participantInfo!.avatarUrl == null ||
                    participantInfo!.avatarUrl!.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              participantInfo!.name,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ChatMessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final int? myId;
  final ChatParticipantInfo? participantInfo;
  final ScrollController controller;

  const _ChatMessagesList({
    required this.messages,
    required this.myId,
    required this.controller,
    this.participantInfo,
  });

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'เริ่มการสนทนาได้เลย',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      reverse: true,
      itemCount: messages.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isMe = msg.senderId == myId;

        bool showDateHeader = false;
        final msgDateLocal = msg.createdAt.toLocal();

        if (index == messages.length - 1) {
          showDateHeader = true;
        } else {
          final olderMsg = messages[index + 1];
          final olderMsgDateLocal = olderMsg.createdAt.toLocal();

          if (!_isSameDay(msgDateLocal, olderMsgDateLocal)) {
            showDateHeader = true;
          }
        }

        return Column(
          children: [
            if (showDateHeader) _DateSeparator(date: msg.createdAt),
            _ChatBubble(msg: msg, isMe: isMe, participantInfo: participantInfo),
          ],
        );
      },
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'วันนี้';
    } else if (dateToCheck == yesterday) {
      return 'เมื่อวาน';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _formatDate(date.toLocal()),
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  final ChatParticipantInfo? participantInfo;

  const _ChatBubble({
    required this.msg,
    required this.isMe,
    this.participantInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _UserAvatar(participantInfo: participantInfo),
            const SizedBox(width: 8),
          ],
          if (isMe) ...[
            _MessageTimestampOutside(
              timestamp: msg.createdAt,
              isMe: true,
              isRead: msg.isRead,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: _MessageBubbleContent(msg: msg, isMe: isMe),
          ),
          if (!isMe) ...[
            const SizedBox(width: 4),
            _MessageTimestampOutside(
              timestamp: msg.createdAt,
              isMe: false,
              isRead: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageBubbleContent extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;

  const _MessageBubbleContent({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF0056D2) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: isMe
              ? const Radius.circular(18)
              : const Radius.circular(4),
          bottomRight: isMe
              ? const Radius.circular(4)
              : const Radius.circular(18),
        ),
      ),
      child: msg.type == MessageType.IMAGE
          ? _ImageMessage(imageUrl: msg.content)
          : _TextMessage(text: msg.content, isMe: isMe),
    );
  }
}

class _MessageTimestampOutside extends StatelessWidget {
  final DateTime timestamp;
  final bool isMe;
  final bool isRead;

  const _MessageTimestampOutside({
    required this.timestamp,
    required this.isMe,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (isMe && isRead)
          const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Text(
              'อ่านแล้ว',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            DateFormat('HH:mm').format(timestamp.toLocal()),
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final ChatParticipantInfo? participantInfo;

  const _UserAvatar({this.participantInfo});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = participantInfo?.avatarUrl;

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? const Icon(Icons.person, color: Colors.white, size: 18)
          : null,
    );
  }
}

class _TextMessage extends StatelessWidget {
  final String text;
  final bool isMe;

  const _TextMessage({required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: isMe ? Colors.white : Colors.black87,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }
}

class _ImageMessage extends StatelessWidget {
  final String imageUrl;

  const _ImageMessage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(10),
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 200,
            height: 150,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 50),
          ),
        ),
      ),
    );
  }
}

class _ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onImagePressed;
  final VoidCallback onSendPressed;
  final bool isLoading;

  const _ChatInputArea({
    required this.controller,
    required this.onImagePressed,
    required this.onSendPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined, color: Colors.blueGrey),
              onPressed: isLoading ? null : onImagePressed,
              tooltip: 'แนบรูปภาพ',
            ),
            Expanded(
              child: _MessageTextField(
                controller: controller,
                onSendPressed: onSendPressed,
                isLoading: isLoading,
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(onPressed: onSendPressed, isLoading: isLoading),
          ],
        ),
      ),
    );
  }
}

class _MessageTextField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendPressed;
  final bool isLoading;

  const _MessageTextField({
    required this.controller,
    required this.onSendPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'พิมพ์ข้อความ...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey),
          isDense: true,
        ),
        textInputAction: TextInputAction.send,
        enabled: !isLoading,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        onSubmitted: (text) {
          if (text.trim().isNotEmpty && !isLoading) {
            onSendPressed();
          }
        },
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _SendButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: isLoading ? Colors.grey : Colors.blue,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: onPressed,
              padding: EdgeInsets.zero,
            ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'ไม่สามารถโหลดข้อความได้',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
