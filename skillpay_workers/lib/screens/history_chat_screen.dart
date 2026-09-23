import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../services/messages_service.dart';
import '../services/cloudinary_service.dart';
import '../models/message_model.dart';
import '../widgets/chat_skeleton.dart';
import 'package:intl/intl.dart';

const Color _kPrimary = Color(0xFFFFC107);

class HistoryChatScreen extends StatefulWidget {
  final String conversationId;
  final String clientName;
  final String? clientAvatarUrl;
  final String? jobTitle;

  const HistoryChatScreen({
    super.key,
    required this.conversationId,
    required this.clientName,
    this.clientAvatarUrl,
    this.jobTitle,
  });

  @override
  State<HistoryChatScreen> createState() => _HistoryChatScreenState();
}

class _HistoryChatScreenState extends State<HistoryChatScreen>
    with TickerProviderStateMixin {
  final _messagesService = MessagesService();
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final _recorder = AudioRecorder();
  final Map<String, AudioPlayer> _players = {};
  final Map<String, PlayerState> _playerStates = {};
  final Map<String, Duration> _playerPositions = {};
  final Map<String, Duration> _playerDurations = {};

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _myUserId;
  bool _isUploading = false;
  bool _isOtherUserTyping = false;
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _typingTimer;
  Timer? _recordTimer;
  late AnimationController _recordPulse;

  String _getInitials(String name) {
    if (name.isEmpty) return 'H';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _recordPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    final cached = _messagesService.getCachedMessages(widget.conversationId);
    if (cached != null && cached.isNotEmpty) {
      final seen = <String>{};
      final msgs = cached.reversed.toList();
      _messages = msgs.where((m) => seen.add(m.id)).toList();
      _isLoading = false;
    }

    _messagesService.getMyPrismaUserId().then((id) {
      if (mounted) {
        setState(() => _myUserId = id);
        if (!_isLoading) _setupRealtime();
      }
    });
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _messagesService.fetchMessages(widget.conversationId);
      if (mounted) {
        final seen = <String>{};
        final msgs = messages.reversed.toList();
        setState(() {
          _messages = msgs.where((m) => seen.add(m.id)).toList();
          _isLoading = false;
        });
        _setupRealtime();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _errorMessage = e.toString(); _isLoading = false; });
      }
    }
  }

  void _addOrUpdateMessage(MessageModel message) {
    if (!mounted) return;
    setState(() {
      if (_messages.any((m) => m.id == message.id)) return;
      final idx = _messages.indexWhere(
        (m) => m.id.startsWith('optimistic_') && m.message == message.message,
      );
      if (idx != -1) {
        _messages[idx] = message;
      } else {
        _messages.insert(0, message);
      }
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _setupRealtime() {
    if (_myUserId == null) return;
    _messagesService.subscribeToMessages(
      conversationId: widget.conversationId,
      currentUserId: _myUserId!,
      onMessage: _addOrUpdateMessage,
      onTyping: (t) { if (mounted) setState(() => _isOtherUserTyping = t); },
    );
  }

  @override
  void dispose() {
    _recordPulse.dispose();
    _typingTimer?.cancel();
    _recordTimer?.cancel();
    _messagesService.unsubscribe();
    _recorder.dispose();
    for (final p in _players.values) { p.dispose(); }
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Attachment sheet ───────────────────────────────────────────────────────

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _sheetTile(Icons.photo_rounded, Colors.blue, 'Photo', () {
                Navigator.pop(context); _pickImage();
              }),
              _sheetTile(Icons.insert_drive_file_rounded, Colors.red, 'Document (PDF)', () {
                Navigator.pop(context); _pickDocument();
              }),
              _sheetTile(Icons.mic_rounded, _kPrimary, 'Voice Note', () {
                Navigator.pop(context); _startVoiceRecording();
              }),
            ],
          ),
        ),
      ),
    );
  }

  ListTile _sheetTile(IconData icon, Color color, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) await _uploadAndSend(File(picked.path));
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result?.files.single.path != null) {
      await _uploadAndSend(File(result!.files.single.path!));
    }
  }

  // ─── Voice recording ────────────────────────────────────────────────────────

  Future<void> _startVoiceRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')));
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() { _isRecording = true; _recordDuration = Duration.zero; });
    _recordPulse.repeat(reverse: true);
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _stopAndSendVoice() async {
    _recordTimer?.cancel();
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    _recordPulse.stop();
    if (path == null) return;
    await _uploadAndSend(File(path));
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.stop();
    setState(() { _isRecording = false; _recordDuration = Duration.zero; });
    _recordPulse.stop();
  }

  // ─── Upload + send ──────────────────────────────────────────────────────────

  Future<void> _uploadAndSend(File file) async {
    setState(() => _isUploading = true);
    try {
      final url = await _messagesService.uploadAttachment(file);
      if (url != null) await _doSend('', attachmentUrls: [url]);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _onTypingChanged(String value) {
    if (_myUserId == null) return;
    _messagesService.updateTypingStatus(_myUserId!, true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      _messagesService.updateTypingStatus(_myUserId!, false);
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();
    await _doSend(text);
  }

  Future<void> _doSend(String text, {List<String>? attachmentUrls}) async {
    final optimistic = MessageModel(
      id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      senderId: _myUserId ?? '',
      senderRole: 'ARTISAN',
      message: text,
      attachmentUrls: attachmentUrls ?? [],
      seen: false,
      createdAt: DateTime.now(),
      isSending: true,
    );
    setState(() => _messages.insert(0, optimistic));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
    try {
      final sent = await _messagesService.sendMessage(
        conversationId: widget.conversationId,
        message: text,
        attachmentUrls: attachmentUrls ?? [],
      );
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == optimistic.id);
          if (_messages.any((m) => m.id == sent.id)) {
            if (idx != -1) _messages.removeAt(idx);
          } else if (idx != -1) {
            _messages[idx] = sent;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          optimistic.isSending = false;
          optimistic.hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  // ─── Audio playback ─────────────────────────────────────────────────────────

  AudioPlayer _getPlayer(String url) {
    if (!_players.containsKey(url)) {
      final p = AudioPlayer();
      _players[url] = p;
      p.onPlayerStateChanged.listen((s) {
        if (mounted) setState(() => _playerStates[url] = s);
      });
      p.onPositionChanged.listen((pos) {
        if (mounted) setState(() => _playerPositions[url] = pos);
      });
      p.onDurationChanged.listen((dur) {
        if (mounted) setState(() => _playerDurations[url] = dur);
      });
    }
    return _players[url]!;
  }

  Future<void> _togglePlay(String url) async {
    final p = _getPlayer(url);
    if ((_playerStates[url] ?? PlayerState.stopped) == PlayerState.playing) {
      await p.pause();
    } else {
      await p.play(UrlSource(url));
    }
  }

  // ─── Formatting helpers ──────────────────────────────────────────────────────

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(date.year, date.month, date.day);
    final timeStr = DateFormat('HH:mm').format(date);
    if (aDate == today) return 'Today $timeStr';
    if (aDate == today.subtract(const Duration(days: 1))) return 'Yesterday $timeStr';
    return '${DateFormat('dd MMM').format(date)} $timeStr';
  }

  String _fmtDur(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38, height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                ),
              ),
              child: ClipOval(
                child: (widget.clientAvatarUrl?.isNotEmpty == true)
                    ? Image.network(widget.clientAvatarUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(_getInitials(widget.clientName),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ))
                    : Center(child: Text(_getInitials(widget.clientName),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (widget.jobTitle?.isNotEmpty == true) ? widget.jobTitle! : widget.clientName,
                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isOtherUserTyping ? 'typing...' :
                        ((widget.jobTitle?.isNotEmpty == true) ? widget.clientName : 'Client'),
                    style: TextStyle(
                      fontSize: 11,
                      color: _isOtherUserTyping ? Colors.green.shade700 : Colors.grey.shade600,
                      fontWeight: _isOtherUserTyping ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isUploading)
              const LinearProgressIndicator(color: _kPrimary, minHeight: 3),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const ChatMessagesSkeleton()
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg.senderRole != null
                                ? msg.senderRole == 'ARTISAN'
                                : msg.senderId == _myUserId;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _buildBubble(
                                msg: msg,
                                isMe: isMe,
                                time: _formatTime(msg.createdAt),
                              ),
                            );
                          },
                        ),
            ),
            if (_isOtherUserTyping)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 4),
                child: Text('Typing...', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            if (_isRecording) _buildRecordingBar() else _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble({required MessageModel msg, required bool isMe, required String time}) {
    final hasAttachment = msg.attachmentUrls.isNotEmpty;
    final url = hasAttachment ? msg.attachmentUrls.first : null;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: isMe ? _kPrimary : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(3),
            bottomRight: isMe ? const Radius.circular(3) : const Radius.circular(16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 3, offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (url != null) ...[
              if (CloudinaryService.isVoiceNote(url))
                _buildVoiceBubble(url, isMe)
              else if (CloudinaryService.isImage(url))
                _buildImageBubble(url)
              else if (CloudinaryService.isDocument(url))
                _buildDocBubble(url, isMe),
              if (msg.message.isNotEmpty) const SizedBox(height: 6),
            ],
            if (msg.message.isNotEmpty)
              Text(msg.message,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15, height: 1.3, fontWeight: FontWeight.w400,
                )),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(),
                Text(time, style: TextStyle(
                  color: isMe ? Colors.white.withAlpha(190) : Colors.grey.shade600,
                  fontSize: 11,
                )),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  if (msg.isSending)
                    Icon(Icons.access_time, size: 12, color: Colors.white.withAlpha(190))
                  else if (msg.hasError)
                    const Icon(Icons.error_outline, size: 12, color: Colors.red)
                  else
                    Icon(Icons.done_all, size: 14, color: Colors.white.withAlpha(220)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBubble(String url) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(url, width: 200, height: 200, fit: BoxFit.cover,
          loadingBuilder: (_, child, prog) => prog == null ? child :
              const SizedBox(width: 200, height: 200,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))),
          errorBuilder: (_, __, ___) => const SizedBox(width: 200, height: 80,
              child: Center(child: Icon(Icons.broken_image, color: Colors.grey)))),
      ),
    );
  }

  Widget _buildDocBubble(String url, bool isMe) {
    final name = Uri.parse(url).pathSegments.last;
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withAlpha(40) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, color: isMe ? Colors.white : Colors.red.shade400, size: 28),
            const SizedBox(width: 8),
            Flexible(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                color: isMe ? Colors.white : Colors.black87))),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceBubble(String url, bool isMe) {
    final player = _getPlayer(url);
    final state = _playerStates[url] ?? PlayerState.stopped;
    final position = _playerPositions[url] ?? Duration.zero;
    final duration = _playerDurations[url] ?? const Duration(seconds: 1);
    final isPlaying = state == PlayerState.playing;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _togglePlay(url),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isMe ? Colors.white.withAlpha(50) : _kPrimary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: isMe ? Colors.white : _kPrimary, size: 20,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: isMe ? Colors.white : _kPrimary,
                  inactiveTrackColor: isMe ? Colors.white.withAlpha(70) : Colors.grey.shade300,
                  thumbColor: isMe ? Colors.white : _kPrimary,
                ),
                child: Slider(
                  value: progress.toDouble(),
                  onChanged: (v) => player.seek(
                      Duration(milliseconds: (v * duration.inMilliseconds).round())),
                ),
              ),
              Text('${_fmtDur(position)} / ${_fmtDur(duration)}',
                style: TextStyle(fontSize: 10,
                  color: isMe ? Colors.white.withAlpha(180) : Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Recording bar ──────────────────────────────────────────────────────────

  Widget _buildRecordingBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _recordPulse,
                  builder: (_, __) => Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withAlpha((_recordPulse.value * 255).round()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_fmtDur(_recordDuration),
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red)),
                const SizedBox(width: 8),
                Text('Recording...', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _stopAndSendVoice,
            child: Container(
              width: 46, height: 46,
              decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Input area ─────────────────────────────────────────────────────────────

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _showAttachmentOptions,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.attach_file_rounded, color: Colors.black54, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _msgController,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onChanged: _onTypingChanged,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _msgController,
            builder: (_, value, __) {
              final hasText = value.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: _isUploading ? null : (hasText ? _sendMessage : _showAttachmentOptions),
                onLongPress: hasText ? null : _startVoiceRecording,
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: _isUploading ? Colors.grey : _kPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: Padding(
                            padding: EdgeInsets.all(11),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                        )
                      : Icon(hasText ? Icons.send_rounded : Icons.mic_rounded,
                          color: Colors.white, size: 22),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
