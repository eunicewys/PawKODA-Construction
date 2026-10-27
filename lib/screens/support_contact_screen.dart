import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'widgets/fringe_header.dart';

/// SupportContactScreen: Lightweight dedicated admin help screen showing
/// the Admin contact email (single line) and Report Issue action button.
class SupportContactScreen extends StatefulWidget {
  const SupportContactScreen({super.key});

  @override
  State<SupportContactScreen> createState() => _SupportContactScreenState();
}

class _SupportContactScreenState extends State<SupportContactScreen> {
  static const String adminEmail = 'support@pawkoda.com';

  // Specified Color Palette
  final Color _fadedCopper = const Color(0xFFB08968);
  final Color _tan = const Color(0xFFDDB892);
  final Color _blackText = const Color(0xFF2D3142);
  final Color _subText = const Color(0xFF505050);

  void _copyEmailToClipboard() {
    Clipboard.setData(const ClipboardData(text: adminEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.content_copy_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text("Admin email copied to clipboard! (support@pawkoda.com)"),
          ],
        ),
        backgroundColor: _fadedCopper,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showReportProblemSheet() {
    final emailCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String selectedCategory = 'General Inquiry';
    bool isSubmitting = false;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final loggedInEmail = firebaseUser?.email ?? Provider.of<UserProvider>(context, listen: false).email;
    if (loggedInEmail != null && loggedInEmail.isNotEmpty) {
      emailCtrl.text = loggedInEmail;
    }

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
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
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
                          Icon(Icons.support_agent_rounded, color: _fadedCopper, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Report Issue / Contact Admin",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _blackText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 22, color: Colors.grey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: "Close",
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Submit your inquiry directly to the PawKODA Administrator.",
                        style: TextStyle(fontSize: 11, color: _subText),
                      ),
                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        isExpanded: true,
                        style: TextStyle(fontSize: 13, color: _blackText, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: "Category *",
                          labelStyle: TextStyle(fontSize: 12, color: _subText),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _fadedCopper),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'General Inquiry', child: Text("General Inquiry", style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Application / Registration Status', child: Text("Application / Registration Status", style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Account & Sign In Help', child: Text("Account & Sign In Help", style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Technical Support', child: Text("Technical Support", style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (val) {
                          if (val != null) setSheetState(() => selectedCategory = val);
                        },
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(fontSize: 13, color: _blackText),
                        decoration: InputDecoration(
                          labelText: "Email Address *",
                          labelStyle: TextStyle(fontSize: 12, color: _subText),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          hintText: "e.g., yourname@domain.com",
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: messageCtrl,
                        maxLines: 3,
                        style: TextStyle(fontSize: 13, color: _blackText),
                        decoration: InputDecoration(
                          labelText: "Detailed Message *",
                          labelStyle: TextStyle(fontSize: 12, color: _subText),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          hintText: "Describe your inquiry or issue...",
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 42,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade400),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () {
                                        FocusScope.of(context).unfocus();
                                        Navigator.pop(context);
                                      },
                                child: Text("Cancel", style: TextStyle(color: _blackText, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 42,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _fadedCopper,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        FocusScope.of(context).unfocus();

                                        final email = emailCtrl.text.trim();
                                        final message = messageCtrl.text.trim();

                                        if (email.isEmpty || message.isEmpty) {
                                          _showErrorDialog(
                                            "Incomplete Info",
                                            "Please enter both your Email Address and Detailed Message before submitting.",
                                          );
                                          return;
                                        }

                                        if (!email.contains('@') || !email.contains('.')) {
                                          _showErrorDialog(
                                            "Invalid Email Address",
                                            "Please enter a valid email address so the Administrator can reply to your inquiry.",
                                          );
                                          return;
                                        }

                                        setSheetState(() => isSubmitting = true);

                                        final currentUser = FirebaseAuth.instance.currentUser;
                                        final uid = currentUser?.uid ?? Provider.of<UserProvider>(context, listen: false).uid ?? '';

                                        try {
                                          await FirebaseFirestore.instance.collection('SUPPORT_TICKETS').add({
                                            'userId': uid.isNotEmpty ? uid : 'guest',
                                            'userEmail': email,
                                            'contactEmail': email,
                                            'category': selectedCategory,
                                            'subject': selectedCategory,
                                            'message': message,
                                            'status': 'OPEN',
                                            'createdAt': FieldValue.serverTimestamp(),
                                          }).timeout(const Duration(seconds: 10));

                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            _showSuccessDialog(
                                              "Enquiry Submitted!",
                                              "Your enquiry has been submitted. We will get back to you shortly",
                                            );
                                          }
                                        } on FirebaseException catch (e) {
                                          setSheetState(() => isSubmitting = false);
                                          if (context.mounted) {
                                            if (e.code == 'permission-denied') {
                                              _showErrorDialog(
                                                "Permission Denied",
                                                "Unable to submit ticket due to Firebase permissions. Please make sure you are signed in or check Firestore Security Rules for SUPPORT_TICKETS.",
                                              );
                                            } else {
                                              _showErrorDialog(
                                                "Submission Error",
                                                "Firebase error (${e.code}): ${e.message}",
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          setSheetState(() => isSubmitting = false);
                                          if (context.mounted) {
                                            _showErrorDialog(
                                              "Submission Error",
                                              "Unable to submit ticket: $e",
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
                                        "Submit to Admin",
                                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: _blackText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: _blackText, fontSize: 13),
        ),
        actions: [
          SizedBox(
            width: 100,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _fadedCopper,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Okay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actionsAlignment: MainAxisAlignment.center,
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: _blackText, fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(message, style: TextStyle(color: _blackText, fontSize: 13)),
        actions: [
          SizedBox(
            width: 100,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _fadedCopper,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Done", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _tan,
      body: Column(
        children: [
          FringeHeader(
            title: "Admin Contact Desk",
            subtitle: "PawKODA Support",
            backgroundColor: _fadedCopper,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _fadedCopper.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.admin_panel_settings_rounded, color: _fadedCopper, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "PawKODA Administrator",
                                    style: TextStyle(
                                      color: _blackText,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Official Support and Help Desk",
                                    style: TextStyle(color: _subText, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Admin Email Section
                        Text(
                          "ADMIN CONTACT EMAIL",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _subText,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Strictly Single-Line Email Box
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _tan.withAlpha(60),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _fadedCopper.withAlpha(100)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.email_outlined, color: _fadedCopper, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: SelectableText(
                                    adminEmail,
                                    style: TextStyle(
                                      color: _blackText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _copyEmailToClipboard,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _fadedCopper,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "Copy",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Single Main Action Button: Report Issue
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _fadedCopper,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _showReportProblemSheet,
                            icon: const Icon(Icons.report_problem_outlined, size: 18),
                            label: const Text(
                              "Report Issue",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
