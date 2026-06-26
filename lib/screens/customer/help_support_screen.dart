import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isSending = false;

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I create a rescue request?',
      'a': 'Go to Dashboard, select your problem type, enter a fare and tap "Find Rescuers".',
    },
    {
      'q': 'How is the price estimated?',
      'a': 'ResQRide uses AI to predict fair prices based on your location, service type and distance.',
    },
    {
      'q': 'What if no rescuer responds?',
      'a': 'Try increasing your offered fare. Rescuers in your area will see your request and respond.',
    },
    {
      'q': 'How do I track the rescuer?',
      'a': 'After accepting an offer, you will see the rescuer\'s live location on the tracking screen.',
    },
    {
      'q': 'How do I cancel a request?',
      'a': 'On the Offers or Tracking screen, tap "Cancel Request" button.',
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': _messageController.text.trim(),
        'type': 'user',
        'time': TimeOfDay.now().format(context),
      });
      _isSending = true;
    });

    _messageController.clear();

    // Auto reply after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text':
                'Thank you for contacting ResQRide support! Our team will get back to you within 24 hours. For urgent help call 1122.',
            'type': 'support',
            'time': TimeOfDay.now().format(context),
          });
          _isSending = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Help & Support'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chat Support', icon: Icon(Icons.chat)),
              Tab(text: 'FAQs', icon: Icon(Icons.quiz)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ─── Chat Tab ──────────────────────────────────────────────
            Column(
              children: [
                // Contact options
                Container(
                  padding: const EdgeInsets.all(12),
                  color: AppColors.primary.withOpacity(0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ContactButton(
                        icon: Icons.phone,
                        label: 'Call Us',
                        onTap: () => launchUrl(Uri.parse('tel:1122')),
                      ),
                      _ContactButton(
                        icon: Icons.email,
                        label: 'Email',
                        onTap: () => launchUrl(
                            Uri.parse('mailto:support@resqride.pk')),
                      ),
                      _ContactButton(
                        icon: Icons.emergency,
                        label: 'Emergency',
                        onTap: () => launchUrl(Uri.parse('tel:1122')),
                      ),
                    ],
                  ),
                ),

                // Chat messages
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.support_agent,
                                  size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text('How can we help you?',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey)),
                              const SizedBox(height: 8),
                              const Text(
                                'Send us a message and we\'ll\nrespond as soon as possible',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isUser = msg['type'] == 'user';
                            return Align(
                              alignment: isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.75),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? AppColors.primary
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isUser)
                                      const Text('ResQRide Support',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary)),
                                    Text(
                                      msg['text']!,
                                      style: TextStyle(
                                          color: isUser
                                              ? Colors.white
                                              : Colors.black87),
                                    ),
                                    Text(
                                      msg['time']!,
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: isUser
                                              ? Colors.white60
                                              : Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Message input
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, -2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : IconButton(
                                icon: const Icon(Icons.send,
                                    color: Colors.white, size: 20),
                                onPressed: _sendMessage,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ─── FAQs Tab ──────────────────────────────────────────────
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _faqs.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    leading: const Icon(Icons.question_answer,
                        color: AppColors.primary),
                    title: Text(_faqs[index]['q']!,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(_faqs[index]['a']!,
                            style: const TextStyle(
                                color: AppColors.textSecondary, height: 1.5)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
