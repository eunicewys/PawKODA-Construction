import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawkoda_fyp/utils/image_helper.dart';
import 'package:pawkoda_fyp/screens/widgets/fringe_header.dart';
import 'package:pawkoda_fyp/services/booking_service.dart';

/// PastVetApplicationsScreen: Admin Database view displaying historical
/// approved and rejected veterinary organization applications.
class PastVetApplicationsScreen extends StatefulWidget {
  const PastVetApplicationsScreen({super.key});

  @override
  State<PastVetApplicationsScreen> createState() => _PastVetApplicationsScreenState();
}

class _PastVetApplicationsScreenState extends State<PastVetApplicationsScreen> {
  // Theme Palette
  final Color _yaleBlue = const Color(0xFF1B4965);
  final Color _softBg = const Color(0xFFF4F7F6);
  final Color _darkText = const Color(0xFF2D3142);
  final Color _subText = const Color(0xFF6C757D);

  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'All'; // 'All', 'Approved', 'Rejected'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Remove Vet Organization Permanently from USERS and CLINICS
  Future<void> _deleteApplication(String uid, String clinicName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Remove Vet Organization",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _darkText),
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to remove \"$clinicName\"? This action will erase ALL related data and info of the clinic.",
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove Vet", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('USERS').doc(uid).delete();
        await FirebaseFirestore.instance.collection('CLINICS').doc(uid).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Vet '$clinicName' and all related clinic data erased."),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error removing vet: $e")),
          );
        }
      }
    }
  }

  // Full Details Review Dialog
  void _showFullDetails(String uid, Map<String, dynamic> data) {
    final String clinicName = data['clinicName'] ?? data['displayName'] ?? 'Vet Organization';
    final String ssmNumber = data['ssmNumber'] ?? 'N/A';
    final String email = data['email'] ?? 'N/A';
    final String phone = data['phone'] ?? 'N/A';
    final String address = data['address'] ?? 'N/A';
    final String websiteUrl = data['websiteUrl'] ?? '';
    final String googleMapsUrl = data['googleMapsUrl'] ?? '';
    final String proofUrl = data['proofDocumentUrl'] ?? '';
    final String status = (data['status'] ?? 'pending').toString().toLowerCase();

    final Color statusColor = status == 'approved' ? Colors.green : Colors.red;
    final String statusLabel = status == 'approved' ? "APPROVED" : "REJECTED";

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 560, maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _yaleBlue,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history_edu_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Past Application Record",
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              clinicName,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _darkText),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor.withAlpha(100)),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      _buildDetailRow(Icons.badge_outlined, "SSM Registration Number", ssmNumber),
                      _buildDetailRow(Icons.email_outlined, "Organization Email", email),
                      _buildDetailRow(Icons.phone_outlined, "Contact Phone Number", BookingService.formatPhoneWithHyphen(phone)),
                      _buildDetailRow(Icons.location_on_outlined, "Clinic Address", address),
                      _buildDetailRow(Icons.language_outlined, "Website Link", websiteUrl.isNotEmpty ? websiteUrl : "Not provided"),
                      _buildDetailRow(Icons.map_outlined, "Google Maps Link", googleMapsUrl.isNotEmpty ? googleMapsUrl : "Not provided"),
                      _buildDetailRow(Icons.fingerprint, "Account UID", uid),

                      const SizedBox(height: 10),
                      Text(
                        "PROOF OF AUTHENTICITY (SSM / LICENSE PHOTO)",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _yaleBlue, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200, minHeight: 100),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: proofUrl.isNotEmpty && ImageHelper.getImageProvider(proofUrl) != null
                              ? Image(image: ImageHelper.getImageProvider(proofUrl)!, fit: BoxFit.contain)
                              : const Center(child: Text("No document uploaded", style: TextStyle(fontSize: 11))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text("Close", style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _deleteApplication(uid, clinicName);
                      },
                      icon: const Icon(Icons.delete_outline, size: 14),
                      label: const Text("Remove Vet", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: _yaleBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.5),
                ),
                const SizedBox(height: 1),
                SelectableText(
                  value,
                  style: TextStyle(fontSize: 11, color: _darkText, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
      body: Column(
        children: [
          FringeHeader(
            title: "Past Vet Applications",
            subtitle: "Approved & Rejected Verification History",
            backgroundColor: _yaleBlue,
            onBack: () => Navigator.pop(context),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(fontSize: 13, color: _darkText),
                  decoration: InputDecoration(
                    hintText: "Search by clinic name, email, or SSM number...",
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: _yaleBlue),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _yaleBlue, width: 1.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Approved', 'Rejected'].map((status) {
                      final isSelected = _statusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : _darkText)),
                          selected: isSelected,
                          selectedColor: _yaleBlue,
                          backgroundColor: Colors.white,
                          onSelected: (_) => setState(() => _statusFilter = status),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('USERS')
                  .where('role', isEqualTo: 'vet')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error loading records: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];

                // Filter for Approved / Rejected only
                List<QueryDocumentSnapshot> pastDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  final status = (data?['status'] ?? 'pending').toString().toLowerCase();
                  return status == 'approved' || status == 'rejected';
                }).toList();

                // Status Filter
                if (_statusFilter == 'Approved') {
                  pastDocs = pastDocs.where((doc) => (doc.get('status') ?? '').toString().toLowerCase() == 'approved').toList();
                } else if (_statusFilter == 'Rejected') {
                  pastDocs = pastDocs.where((doc) => (doc.get('status') ?? '').toString().toLowerCase() == 'rejected').toList();
                }

                // Search Query
                final query = _searchCtrl.text.trim().toLowerCase();
                if (query.isNotEmpty) {
                  pastDocs = pastDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    final name = (data?['clinicName'] ?? data?['displayName'] ?? '').toString().toLowerCase();
                    final email = (data?['email'] ?? '').toString().toLowerCase();
                    final ssm = (data?['ssmNumber'] ?? '').toString().toLowerCase();
                    return name.contains(query) || email.contains(query) || ssm.contains(query);
                  }).toList();
                }

                if (pastDocs.isEmpty) {
                  String emptyTitle = "No past veterinary applications found";
                  if (_statusFilter == 'Approved') {
                    emptyTitle = "No approved veterinary applications found";
                  } else if (_statusFilter == 'Rejected') {
                    emptyTitle = "No rejected veterinary applications found";
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.history_edu_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            emptyTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _darkText),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Approved or rejected clinic applications will appear here.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: _subText),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: pastDocs.length,
                  itemBuilder: (context, index) {
                    final doc = pastDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final uid = doc.id;
                    final clinicName = data['clinicName'] ?? data['displayName'] ?? 'Vet Organization';
                    final ssmNumber = data['ssmNumber'] ?? 'N/A';
                    final email = data['email'] ?? '';
                    final phone = data['phone'] ?? '';
                    final status = (data['status'] ?? 'approved').toString().toLowerCase();

                    final Color statusColor = status == 'approved' ? Colors.green : Colors.red;
                    final String statusLabel = status == 'approved' ? "APPROVED" : "REJECTED";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 1.5,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.verified_user_rounded, color: statusColor, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        clinicName,
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _darkText),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "SSM: $ssmNumber",
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _yaleBlue),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: statusColor.withAlpha(100)),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),

                            if (email.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(Icons.email_outlined, color: _subText, size: 14),
                                  const SizedBox(width: 4),
                                  SelectableText(email, style: TextStyle(fontSize: 11, color: _darkText, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],

                            if (phone.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined, color: _subText, size: 14),
                                  const SizedBox(width: 4),
                                  SelectableText(BookingService.formatPhoneWithHyphen(phone), style: TextStyle(fontSize: 11, color: _yaleBlue, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],

                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showFullDetails(uid, data),
                                  icon: const Icon(Icons.info_outline, size: 14),
                                  label: const Text("View Details", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  onPressed: () => _deleteApplication(uid, clinicName),
                                  icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                  label: const Text("Remove Vet", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    side: const BorderSide(color: Colors.red),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
