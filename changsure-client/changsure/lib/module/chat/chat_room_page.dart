import 'dart:io';
import 'package:changsure/core/theme.dart';
import 'package:changsure/state/notifications/realtime_provider.dart';
import 'package:changsure/state/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/models/chat/chat_model.dart';
import '../../../../data/models/chat/chat_helper.dart';
import '../../../../data/services/chat_service.dart';
import '../../../../state/chat_provider.dart';
import '../../../../state/user_provider.dart';
import 'package:changsure/core/constants/realtime_events.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  final int bookingId;
  final String? title;
  final String? otherPersonImg;
  final int? technicianId;
  final int? roomId;
  final ChatParticipantInfo? participantInfo;

  const ChatRoomPage({
    super.key,
    required this.bookingId,
    this.title,
    this.otherPersonImg,
    this.technicianId,
    this.roomId,
    this.participantInfo,
  });

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  ChatParticipantInfo? _participantInfo;
  bool _isMarkingAsRead = false;

  @override
  void initState() {
    super.initState();
    if (widget.technicianId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.listen(technicianProfileProvider(widget.technicianId!), (_, state) {
          state.whenData((profile) {
            if (profile != null && mounted) {
              setState(() {
                _participantInfo = ChatParticipantInfo.fromTechnicianProfile(
                  profile,
                );
              });
            }
          });
        });
      });
    }
    _initializePage();

    _listenForRoomStatusChanges();
  }

  void _listenForRoomStatusChanges() {
    ref.listenManual(realtimeStreamProvider, (previous, next) {
      next.whenData((event) {
        final type = event['type'] as String?;
        final data = event['data'] as Map<String, dynamic>?;

        if (type == null || data == null) return;

        final eventBookingId = data['booking_id'];
        if (eventBookingId != widget.bookingId) return;

        switch (type) {
          case RealtimeEvents.chatRoomLocked:
            final reason = data['reason'] as String? ?? 'แชทถูกล็อค';
            _showInfoSnackBar(reason);
            break;

          case RealtimeEvents.chatRoomUpdated:
            final status = data['status'] as String?;
            final canChat = data['can_chat'] as bool? ?? true;

            if (!canChat) {
              _showInfoSnackBar('สถานะงานเปลี่ยนเป็น: $status');
            }
            break;

          case RealtimeEvents.jobCompleted:
          case RealtimeEvents.bookingCancelled:
            _showInfoSnackBar('แชทถูกล็อคเนื่องจากงานสิ้นสุดแล้ว');
            break;
        }
      });
    });
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _resolveParticipantInfo();
    await _markRoomAsRead();
  }

  Future<void> _markRoomAsRead() async {
    if (_isMarkingAsRead) return;

    try {
      _isMarkingAsRead = true;
      final service = ref.read(chatServiceProvider);
      final token = ref.read(userProvider)?.token;

      if (token != null) {
        await service.markRoomAsRead(token, widget.bookingId);

        ref.read(chatRoomsProvider.notifier).refresh();
      }
    } on ChatServiceException catch (e) {
      debugPrint('Failed to mark room as read: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error marking room as read: $e');
    } finally {
      _isMarkingAsRead = false;
    }
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
      // ✅ ใช้ค่าที่ส่งมาจากหน้า Booking ก่อน
      if (widget.participantInfo != null && mounted) {
        setState(() {
          _participantInfo = widget.participantInfo;
        });
        return; // หยุดเลย ไม่ต้องไป fallback
      }

      // ✅ เปลี่ยนเป็น
      if (widget.technicianId != null) {
        ref.read(technicianProfileProvider(widget.technicianId!)).whenData((
          profile,
        ) {
          if (profile != null && mounted) {
            setState(() {
              _participantInfo = ChatParticipantInfo.fromTechnicianProfile(
                profile,
              );
            });
          }
        });
        return;
      }

      // 🔹 fallback จาก title
      if (_participantInfo == null &&
          widget.title != null &&
          widget.title!.isNotEmpty &&
          mounted) {
        setState(() {
          _participantInfo = ChatParticipantInfo(
            userId: 0,
            name: widget.title!,
            avatarUrl: widget.otherPersonImg,
          );
        });
      }

      // 🔹 fallback สุดท้าย
      if (_participantInfo == null && mounted) {
        setState(() {
          _participantInfo = ChatParticipantInfo.unknown;
        });
      }
    } catch (e) {
      debugPrint('Error resolving participant info: $e');
      if (mounted) {
        setState(() {
          _participantInfo = ChatParticipantInfo.unknown;
        });
      }
    }
  }

  Future<void> _handleImageSelection() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return;

      if (!mounted) return;

      final file = File(image.path);
      final fileSize = await file.length();
      const maxSize = 10 * 1024 * 1024;

      if (fileSize > maxSize) {
        _showErrorSnackBar('รูปภาพมีขนาดใหญ่เกินไป (สูงสุด 10MB)');
        return;
      }

      await _sendImage(file);
    } on ChatServiceException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (e) {
      debugPrint('Error selecting image: $e');
      _showErrorSnackBar('เลือกรูปภาพไม่สำเร็จ');
    }
  }

  Future<void> _sendImage(File imageFile) async {
    try {
      await ref
          .read(chatControllerProvider.notifier)
          .sendImage(widget.bookingId, imageFile);

      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    } on ValidationException catch (e) {
      _showErrorSnackBar(e.message);
    } on NetworkException catch (_) {
      _showErrorSnackBar('ไม่มีการเชื่อมต่ออินเทอร์เน็ต');
    } on ChatServiceException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (e) {
      debugPrint('Error sending image: $e');
      _showErrorSnackBar('ส่งรูปภาพไม่สำเร็จ');
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();

    final validationError = ChatHelper.validateMessageContent(
      text,
      MessageType.text,
    );

    if (validationError != null) {
      _showErrorSnackBar(validationError);
      return;
    }

    _messageController.clear();

    try {
      await ref
          .read(chatControllerProvider.notifier)
          .sendMessage(widget.bookingId, text);

      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    } on ValidationException catch (e) {
      _messageController.text = text;
      _showErrorSnackBar(e.message);
    } on NetworkException catch (_) {
      _messageController.text = text;
      _showErrorSnackBar('ไม่มีการเชื่อมต่ออินเทอร์เน็ต');
    } on ChatServiceException catch (e) {
      _messageController.text = text;
      _showErrorSnackBar(e.message);
    } catch (e) {
      _messageController.text = text;
      debugPrint('Error sending message: $e');
      _showErrorSnackBar('ส่งข้อความไม่สำเร็จ');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'ปิด',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
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
                scrollController: _scrollController,
              ),
              loading: () => const _LoadingView(),
              error: (error, stack) => _ErrorView(
                error: error,
                onRetry: () {
                  ref.invalidate(chatHistoryProvider(widget.bookingId));
                },
              ),
            ),
          ),

          if (chatState.isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
            ),

          _ChatInputArea(
            controller: _messageController,
            onImagePressed: _handleImageSelection,
            onSendPressed: _handleSendMessage,
            isLoading: chatState.isLoading,
            bookingId: widget.bookingId,
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
        elevation: 0,
        toolbarHeight: 80,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'กำลังโหลด...',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 110,
      leadingWidth: 60,
      titleSpacing: 0,
      iconTheme: const IconThemeData(color: Colors.black),

      title: Row(
        children: [
          _ParticipantAvatar(participantInfo: participantInfo!),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              participantInfo!.displayName,
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

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.colorStroke),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ParticipantAvatar extends StatelessWidget {
  final ChatParticipantInfo participantInfo;

  const _ParticipantAvatar({required this.participantInfo});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = participantInfo.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    if (!hasAvatar) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey[300],
        backgroundImage: AssetImage('assets/image/Technician.png'),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(
            width: 36,
            height: 36,
            child: Center(child: CircularProgressIndicator(strokeWidth: 1)),
          ),
          errorWidget: (context, url, error) => Image.asset(
            'assets/image/Technician.png',
            width: 36,
            height: 36,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _ChatMessagesList extends ConsumerWidget {
  final List<ChatMessage> messages;
  final int? myId;
  final ChatParticipantInfo? participantInfo;
  final ScrollController scrollController;

  const _ChatMessagesList({
    required this.messages,
    required this.myId,
    required this.scrollController,
    this.participantInfo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีข้อความ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final currentUser = ref.watch(userProvider);

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      itemCount: messages.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemBuilder: (context, index) {
        final message = messages[index];
        final previousMessage = index < messages.length - 1
            ? messages[index + 1]
            : null;
        final nextMessage = index > 0 ? messages[index - 1] : null;

        final isMe = message.senderId == currentUser?.id;

        final showDateSeparator = ChatHelper.shouldShowDateSeparator(
          message,
          previousMessage,
        );

        final shouldGroupWithNext = ChatHelper.shouldGroupMessages(
          message,
          nextMessage,
        );

        return Column(
          children: [
            if (showDateSeparator) _DateSeparator(date: message.createdAt),
            _ChatBubble(
              message: message,
              isMe: isMe,
              participantInfo: participantInfo,
              showAvatar: !shouldGroupWithNext,
              showTimestamp: !shouldGroupWithNext,
            ),
          ],
        );
      },
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          ChatHelper.formatDateSeparator(date),
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
  final ChatMessage message;
  final bool isMe;
  final ChatParticipantInfo? participantInfo;
  final bool showAvatar;
  final bool showTimestamp;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    this.participantInfo,
    this.showAvatar = true,
    this.showTimestamp = true,
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
          if (!isMe) ...[_buildAvatar(), const SizedBox(width: 8)],
          if (isMe && showTimestamp) ...[
            _MessageTimestamp(
              timestamp: message.createdAt,
              isMe: true,
              isRead: message.isRead,
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: _MessageBubbleContent(message: message, isMe: isMe),
          ),
          if (!isMe && showTimestamp) ...[
            const SizedBox(width: 10),
            _MessageTimestamp(
              timestamp: message.createdAt,
              isMe: false,
              isRead: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (!showAvatar) {
      return const SizedBox(width: 35);
    }

    return _UserAvatar(participantInfo: participantInfo);
  }
}

class _MessageBubbleContent extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubbleContent({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    if (message.isImageMessage) {
      return _ImageMessage(imageUrl: message.content);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : AppColors.colorStroke,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: isMe
              ? const Radius.circular(18)
              : const Radius.circular(0),
          bottomRight: isMe
              ? const Radius.circular(0)
              : const Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _TextMessage(text: message.content, isMe: isMe),
    );
  }
}

class _MessageTimestamp extends StatelessWidget {
  final DateTime timestamp;
  final bool isMe;
  final bool isRead;

  const _MessageTimestamp({
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
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'อ่านแล้ว',
              style: TextStyle(color: AppColors.primaryBorder, fontSize: 12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Text(
            ChatHelper.formatMessageTime(timestamp),
            style: TextStyle(color: AppColors.primaryBorder, fontSize: 12),
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
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    if (!hasAvatar) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey[300],
        backgroundImage: AssetImage('assets/image/Technician.png'),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(
            width: 36,
            height: 36,
            child: Center(child: CircularProgressIndicator(strokeWidth: 1)),
          ),
          errorWidget: (context, url, error) => Image.asset(
            'assets/image/Technician.png',
            width: 36,
            height: 36,
            fit: BoxFit.cover,
          ),
        ),
      ),
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
    final isLocalFile =
        !imageUrl.startsWith('http') && !imageUrl.startsWith('https');

    return GestureDetector(
      onTap: () => _showFullScreenImage(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isLocalFile ? _buildLocalImage() : _buildNetworkImage(),
      ),
    );
  }

  Widget _buildLocalImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.file(File(imageUrl), width: 200, height: 150, fit: BoxFit.cover),

        Container(
          width: 200,
          height: 150,
          color: Colors.black26,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkImage() {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 200,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: 200,
        height: 150,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => _buildErrorWidget(),
      memCacheWidth: 600,
      memCacheHeight: 450,
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 200,
      height: 150,
      color: Colors.grey[200],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 50, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'โหลดรูปภาพไม่สำเร็จ',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(
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
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInputArea extends ConsumerWidget {
  final TextEditingController controller;
  final VoidCallback onImagePressed;
  final VoidCallback onSendPressed;
  final bool isLoading;
  final int bookingId;

  const _ChatInputArea({
    required this.controller,
    required this.onImagePressed,
    required this.onSendPressed,
    required this.isLoading,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(chatRoomsProvider);

    bool isChatLocked = false;
    String lockReason = '';

    roomsAsync.whenData((rooms) {
      final room = rooms.firstWhere(
        (r) => r.bookingId == bookingId,
        orElse: () => ChatRoom(
          bookingId: 0,
          bookingNumber: '',
          bookingStatus: BookingStatus.pending,
          serviceCategory: '',
          otherPersonId: 0,
          otherPersonName: '',
          otherPersonImg: '',
          lastMessage: '',
          lastMsgType: MessageType.text,
          lastMsgTime: DateTime.now(),
          lastSender: '',
          unreadCount: 0,
          canSendMessage: false,
        ),
      );

      isChatLocked = !room.canSendMessage;

      if (isChatLocked) {
        switch (room.bookingStatus) {
          case BookingStatus.pending:
            lockReason = 'รอช่างยอมรับงานก่อน';
            break;
          case BookingStatus.completed:
            lockReason = 'งานเสร็จสิ้นแล้ว';
            break;
          case BookingStatus.cancelled:
            lockReason = 'งานถูกยกเลิกแล้ว';
            break;
          default:
            lockReason = 'ไม่สามารถส่งข้อความได้';
        }
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isChatLocked ? Colors.grey.shade200 : AppColors.primaryBGHover,
      ),
      child: SafeArea(
        child: isChatLocked
            ? _buildLockedMessage(lockReason)
            : Row(
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/imageChat.svg',
                      width: 40,
                      height: 40,
                    ),
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
                ],
              ),
      ),
    );
  }

  Widget _buildLockedMessage(String reason) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.colorStroke),
      ),
      child: TextField(
        controller: controller,
        enabled: !isLoading,
        maxLines: null,
        maxLength: 5000,
        textInputAction: TextInputAction.send,
        keyboardType: TextInputType.multiline,
        onSubmitted: (text) {
          if (text.trim().isNotEmpty && !isLoading) {
            onSendPressed();
          }
        },
        buildCounter:
            (context, {required currentLength, required isFocused, maxLength}) {
              if (currentLength < 4500) return null;
              return Text(
                '$currentLength / $maxLength',
                style: TextStyle(
                  fontSize: 10,
                  color: currentLength > 4900 ? Colors.red : Colors.grey,
                ),
              );
            },
        decoration: InputDecoration(
          hintText: 'ส่งข้อความ...',
          border: InputBorder.none,
          hintStyle: const TextStyle(color: Colors.grey),
          isDense: true,

          contentPadding: const EdgeInsets.symmetric(vertical: 12),

          suffixIconConstraints: const BoxConstraints(
            minHeight: 40,
            minWidth: 40,
          ),

          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: isLoading ? null : onSendPressed,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : SvgPicture.asset(
                          "assets/icons/sendButton.svg",
                          width: 24,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  String _getErrorMessage(Object error) {
    if (error is NetworkException) {
      return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต\nกรุณาตรวจสอบการเชื่อมต่อ';
    } else if (error is AuthenticationException) {
      return 'กรุณาเข้าสู่ระบบอีกครั้ง';
    } else if (error is ChatServiceException) {
      return error.message;
    }
    return 'เกิดข้อผิดพลาดที่ไม่คาดคิด';
  }

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
              _getErrorMessage(error),
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
