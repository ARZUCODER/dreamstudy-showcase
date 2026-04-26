import 'dart:typed_data';
import 'package:dreamstudy/features/interactive_mentor/domain/models/mentor_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/interactive_mentor_provider.dart';
import '../widgets/mentor_markdown.dart';

class InteractiveMentorScreen extends ConsumerStatefulWidget {
  const InteractiveMentorScreen({super.key});

  @override
  ConsumerState<InteractiveMentorScreen> createState() => _InteractiveMentorScreenState();
}

class _InteractiveMentorScreenState extends ConsumerState<InteractiveMentorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Uint8List? _selectedImage;
  bool _isCustomSubject = false;
  final TextEditingController _customSubjectController = TextEditingController();

  final List<String> _subjects = [
    "Matematika", "Fizika", "Kimyo", "Biologiya",
    "Ona tili", "Tarix", "Ingliz tili", "Dasturlash", "Boshqa..."
  ];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    ref.read(interactiveMentorProvider.notifier).sendMessage(text, imageBytes: _selectedImage);
    _controller.clear();
    setState(() => _selectedImage = null);
    _scrollToBottom();
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (xFile != null) {
      final bytes = await xFile.readAsBytes();
      setState(() => _selectedImage = bytes);
    }
  }

  void _handleQuickAction(String prompt) {
    ref.read(interactiveMentorProvider.notifier).sendMessage(prompt);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(interactiveMentorProvider);
    final selectedSubject = ref.watch(selectedSubjectProvider);

    // Xabarlar yangilanganda avto-skroll
    ref.listen(interactiveMentorProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // slate-950 equivalent
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A), // slate-900
        titleSpacing: 0,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 10)],
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("AI Ustoz", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text("OTM ga tayyorlanamiz", style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          _buildSubjectDropdown(selectedSubject),
        ],
      ),
      body: Column(
        children: [
          if (_isCustomSubject)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _customSubjectController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Fanni kiriting va Saqlash ni bosing...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle, color: Color(0xFF3B82F6)),
                    onPressed: () {
                      if (_customSubjectController.text.isNotEmpty) {
                        ref.read(selectedSubjectProvider.notifier).state = _customSubjectController.text;
                        setState(() => _isCustomSubject = false);
                      }
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ).animate().slideY(),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          _buildQuickActions(selectedSubject),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MentorMessage msg) {
    if (msg.isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, right: 60),
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF60A5FA))),
              SizedBox(width: 12),
              Text("O'ylab ko'ryapman...", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            ],
          ),
        ),
      ).animate().fadeIn();
    }

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16, left: msg.isUser ? 40 : 0, right: msg.isUser ? 0 : 40),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
          border: msg.isUser ? null : Border.all(color: const Color(0xFF334155)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(msg.imageBytes!),
                ),
              ),
            if (msg.text.isNotEmpty)
              msg.isUser
                  ? Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5))
                  : MentorMarkdown(text: msg.text),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildSubjectDropdown(String selected) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu_book_rounded, color: Color(0xFF93C5FD)),
      color: const Color(0xFF1E293B),
      onSelected: (value) {
        if (value == "Boshqa...") {
          setState(() => _isCustomSubject = true);
        } else {
          setState(() => _isCustomSubject = false);
          ref.read(selectedSubjectProvider.notifier).state = value;
        }
      },
      itemBuilder: (context) => _subjects.map((s) => PopupMenuItem(
        value: s,
        child: Text(s, style: TextStyle(color: s == selected ? const Color(0xFF38BDF8) : Colors.white)),
      )).toList(),
    );
  }

  Widget _buildQuickActions(String subject) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          _quickBtn("Yangi mavzu", Icons.auto_awesome, Colors.amber, "Menga $subject fanidan yangi va qiziqarli mavzuni tushuntirib ber."),
          _quickBtn("Test ishlash", Icons.fact_check_outlined, Colors.greenAccent, "Menga hozirgacha o'rganganlarim yoki umumiy $subject bo'yicha test ber."),
          _quickBtn("O'yin", Icons.sports_esports_rounded, Colors.purpleAccent, "$subject faniga oid qiziqarli va mantiqiy o'yin o'ynaymiz."),
          _quickBtn("Motivatsiya", Icons.local_fire_department_rounded, Colors.deepOrange, "Hozir o'qishga motivatsiyam yo'q. Menga OTM ga kirish nega muhimligi haqida dalda ber."),
        ],
      ),
    );
  }

  Widget _quickBtn(String title, IconData icon, Color color, String prompt) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: const Color(0xFF1E293B),
        side: const BorderSide(color: Color(0xFF334155)),
        avatar: Icon(icon, color: color, size: 16),
        label: Text(title, style: const TextStyle(color: Color(0xFFCBD5E1))),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => _handleQuickAction(prompt),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_selectedImage != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF3B82F6))),
                  child: Stack(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(_selectedImage!)),
                      Positioned(
                        top: -5, right: -5,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => setState(() => _selectedImage = null),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(),

            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 4,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: "Misol yozing yoki rasm yuklang...",
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
                          onPressed: _pickImage,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 10)],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text("AI xato qilishi mumkin. Muhim ma'lumotlarni tekshirib ko'ring.", style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}