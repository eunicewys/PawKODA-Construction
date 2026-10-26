import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../widgets/fringe_header.dart';

/// HelpSupportScreen: Displays searchable FAQ questions & solutions and
/// official PawKODA Support Desk contact options (email, mailto launcher, support ticket submission).
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // Morandi Palette
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _lightBronze = const Color(0xFFCB997E);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _darkCharcoal = const Color(0xFF2D3142);
  final Color _ashGrey = const Color(0xFF8A8A7C);

  static const String supportEmail = 'support@pawkoda.com';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _allFaqs = [
    {
      'category': 'Pet Health & Reminders',
      'question': 'How do vaccination & deworming reminders work?',
      'answer':
          'When you log a vaccination or deworming booster date for your pet, PawKODA automatically schedules daily phone notifications starting 3 days prior (at 9:00 AM) up to the due date to ensure you never miss a dose.',
    },
    {
      'category': 'Pet Health & Reminders',
      'question': 'How do I log medical issues or daily activity?',
      'answer':
          'Navigate to the Health tab, select your pet, and tap "Health Issues" or "Daily Activity" to record symptoms, veterinary diagnosis, medications, or activity logs.',
    },
    {
      'category': 'Penang Vet Bookings',
      'question': 'Which Penang clinics are available on PawKODA?',
      'answer':
          'PawKODA features top Penang veterinary hospitals including Kenique Veterinary Centre (George Town) and Grace Veterinary Clinic branches (Bayan Lepas, Tanjung Tokong, and Butterworth). You can view operating hours, ratings, and book appointments directly.',
    },
    {
      'category': 'Penang Vet Bookings',
      'question': 'How do I get directions to a vet clinic?',
      'answer':
          'In the Booking tab, tap on any clinic card and click "Get Directions" or "Open in Google Maps" to launch turn-by-turn navigation.',
    },
    {
      'category': 'Pet Nutrition Engine',
      'question': 'How is my pet\'s daily caloric requirement calculated?',
      'answer':
          'Our Nutrition Engine uses scientific WSAVA formulas: Resting Energy Requirement RER = 70 × (Weight in kg)^0.75, adjusted by a Daily Energy Requirement (DER) factor based on species, life stage, neuter status, and activity level.',
    },
    {
      'category': 'Pet Nutrition Engine',
      'question': 'Can I check custom recipe safety for my pet?',
      'answer':
          'Yes! In the Nutrition tab, select ingredients and quantities. The engine automatically warns you about clinical risks (such as toxic items like onions/garlic or inappropriate calcium/phosphorus ratios for growing puppies).',
    },
    {
      'category': 'Notifications & Account',
      'question': 'How long are past notifications saved in my account?',
      'answer':
          'Past notifications are automatically stored in your Notification Center for 30 days. After 30 days, old notifications are automatically purged to keep your storage clean.',
    },
    {
      'category': 'Notifications & Account',
      'question': 'How do I filter past notifications?',
      'answer':
          'In Profile > Notifications, use the filter chips at the top to filter by "Past 7 days", "Past 14 days", "Past 21 days", or "Past 30 days".',
    },
    {
      'category': 'Notifications & Account',
      'question': 'How do I change my account password?',
      'answer':
          'Go to Profile > Privacy & Security > Change Password. Enter your current password and new password to update.',
    },
  ];

  Future<void> _launchSupportEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': 'PawKODA App Support Request',
        'body': 'Hello PawKODA Support Team,\n\nI need help with:\n\n[Please describe your problem here]\n\nUser ID: ${Provider.of<UserProvider>(context, listen: false).uid ?? "N/A"}',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(emailUri, mode: LaunchMode.externalNonBrowserApplication);
      }
    } catch (e) {
      _copyEmailToClipboard();
    }
  }

  void _copyEmailToClipboard() {
    Clipboard.setData(const ClipboardData(text: supportEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.content_copy_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text("Support email copied to clipboard! (support@pawkoda.com)"),
          ],
        ),
        backgroundColor: _dustyOlive,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showReportProblemSheet() {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String selectedCategory = 'General Issue';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.support_agent_rounded, color: _dustyOlive, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          "Report Problem / Contact Support",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _darkCharcoal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Submit an inquiry to our support desk. We will respond within 24 hours.",
                      style: TextStyle(fontSize: 11, color: _ashGrey),
                    ),
                    const SizedBox(height: 14),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      isExpanded: true,
                      style: TextStyle(fontSize: 13, color: _darkCharcoal, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: "Issue Category *",
                        labelStyle: const TextStyle(fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'General Issue', child: Text("General Issue", style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Vaccine / Health Reminders', child: Text("Vaccine / Health Reminders", style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Vet Clinic Bookings', child: Text("Vet Clinic Bookings", style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Nutrition Engine & Recipes', child: Text("Nutrition Engine & Recipes", style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Account & Password', child: Text("Account & Password", style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Subject Field
                    TextField(
                      controller: subjectCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Subject / Brief Summary *",
                        labelStyle: const TextStyle(fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: "e.g., Reminder notification delayed",
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description Field
                    TextField(
                      controller: messageCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Detailed Description *",
                        labelStyle: const TextStyle(fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: "Please describe the problem you encountered...",
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dustyOlive,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final subject = subjectCtrl.text.trim();
                                final message = messageCtrl.text.trim();

                                if (subject.isEmpty || message.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Please fill in subject and description.")),
                                  );
                                  return;
                                }

                                setSheetState(() => isSubmitting = true);

                                final uid = Provider.of<UserProvider>(context, listen: false).uid ?? '';
                                final email = Provider.of<UserProvider>(context, listen: false).email ?? '';

                                try {
                                  await FirebaseFirestore.instance.collection('SUPPORT_TICKETS').add({
                                    'userId': uid,
                                    'userEmail': email,
                                    'category': selectedCategory,
                                    'subject': subject,
                                    'message': message,
                                    'status': 'OPEN',
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    _showSuccessDialog(
                                      "Ticket Submitted!",
                                      "Your ticket has been sent to support desk ($supportEmail). We will get back to you shortly.",
                                    );
                                  }
                                } catch (e) {
                                  setSheetState(() => isSubmitting = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error submitting ticket: $e")),
                                    );
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "Submit Support Ticket",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: TextStyle(color: _darkCharcoal)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _dustyOlive),
            onPressed: () => Navigator.pop(context),
            child: const Text("Done", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _allFaqs.where((faq) {
      final q = faq['question']!.toLowerCase();
      final a = faq['answer']!.toLowerCase();
      final c = faq['category']!.toLowerCase();
      final s = _searchQuery.toLowerCase();
      return q.contains(s) || a.contains(s) || c.contains(s);
    }).toList();

    const Color beachBg = Color(0xFFE6CCB2);

    return Scaffold(
      backgroundColor: beachBg,
      body: Column(
        children: [
          FringeHeader(
            title: "Help & Support",
            subtitle: "FAQ & Support Desk",
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Support Desk Highlight Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_dustyOlive, const Color(0xFF585D4B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _dustyOlive.withAlpha(60),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "PawKODA Support Desk",
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "Mon - Fri • 9:00 AM – 6:00 PM (MYT)",
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.email_outlined, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  supportEmail,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: _copyEmailToClipboard,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Copy",
                                    style: TextStyle(color: _dustyOlive, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _dustyOlive,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _showReportProblemSheet,
                            icon: const Icon(Icons.report_problem_outlined, size: 16),
                            label: const Text("Report Issue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // FAQ Section Title & Search Bar
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      "FREQUENTLY ASKED QUESTIONS",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _ashGrey,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Search TextField
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(fontSize: 13, color: _darkCharcoal),
                    decoration: InputDecoration(
                      hintText: "Search questions or keywords...",
                      hintStyle: TextStyle(fontSize: 12, color: _ashGrey),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: Icon(Icons.search_rounded, color: _ashGrey, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // FAQs List
                  if (filteredFaqs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.help_outline_rounded, size: 36, color: _ashGrey),
                            const SizedBox(height: 8),
                            Text("No matching FAQ questions found.", style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text("Try searching for terms like 'vaccine', 'booking', or 'calories'.", style: TextStyle(color: _ashGrey, fontSize: 11)),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredFaqs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final faq = filteredFaqs[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(5),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: Material(
                              color: Colors.transparent,
                              child: ExpansionTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                                leading: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(color: _powderPetal, borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.question_answer_rounded, color: _dustyOlive, size: 18),
                                ),
                                title: Text(
                                  faq['question']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _darkCharcoal,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    faq['category']!,
                                    style: TextStyle(fontSize: 10, color: _lightBronze, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                children: [
                                  Text(
                                    faq['answer']!,
                                    style: TextStyle(fontSize: 12, color: _darkCharcoal.withAlpha(220), height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
