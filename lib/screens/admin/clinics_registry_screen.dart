import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/clinic_model.dart';
import '../../services/booking_service.dart';
import '../widgets/fringe_header.dart';

/// ClinicsRegistryScreen: Provides Penang Admin Desk with full directory controls over
/// veterinary clinics (viewing ratings, operating hours, addresses, contact info, and adding/editing/deleting Firestore clinics).
class ClinicsRegistryScreen extends StatefulWidget {
  const ClinicsRegistryScreen({super.key});

  @override
  State<ClinicsRegistryScreen> createState() => _ClinicsRegistryScreenState();
}

class _ClinicsRegistryScreenState extends State<ClinicsRegistryScreen> {
  // Theme Palette
  final Color _yaleBlue = const Color(0xFF133C55);
  final Color _softBg = const Color(0xFFF4F7F6);
  final Color _darkText = const Color(0xFF2D3142);
  final Color _subText = const Color(0xFF6C757D);

  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCity = 'All Cities';

  final List<String> _cities = [
    'All Cities',
    'George Town',
    'Bayan Lepas',
    'Tanjung Tokong',
    'Air Itam',
    'Balik Pulau',
    'Bukit Mertajam',
  ];

  final List<String> _availableServices = [
    'General Consultation',
    'Vaccination',
    'Soft Tissue Surgery',
    'Dental Care',
    'Blood Diagnostics',
    'Feline Care',
    'Deworming',
    'Grooming Services',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
      body: Column(
        children: [
          FringeHeader(
            title: "Clinics Registry",
            subtitle: "Penang Veterinary Network Management",
            backgroundColor: _yaleBlue,
            onBack: () => Navigator.pop(context),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Top Action Bar: Search Bar + Register New Clinic
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(fontSize: 13, color: _darkText),
                        decoration: InputDecoration(
                          hintText: "Search clinic by name, address, or phone...",
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _yaleBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                      ),
                      onPressed: () => _openClinicModal(),
                      icon: const Icon(Icons.add_business_rounded, size: 20),
                      label: const Text(
                        "Add Clinic",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // City Filter Chips Bar
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cities.length,
                    itemBuilder: (context, index) {
                      final city = _cities[index];
                      final isSelected = _selectedCity == city;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(city),
                          selected: isSelected,
                          selectedColor: _yaleBlue,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : _darkText,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected ? _yaleBlue : Colors.grey.shade300,
                          ),
                          onSelected: (_) => setState(() => _selectedCity = city),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Directory List (Firestore Stream + Default Penang Clinics Merged)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('CLINICS').snapshots(),
              builder: (context, snapshot) {
                final firestoreDocs = snapshot.data?.docs ?? [];
                final customClinics = firestoreDocs.map((doc) {
                  return ClinicModel.fromMap(doc.data(), doc.id);
                }).toList();

                final Map<String, ClinicModel> mergedMap = {};

                // 1. Add baseline Penang clinics
                for (var clinic in BookingService.penangClinics) {
                  mergedMap[clinic.id] = clinic;
                }

                // 2. Override / Add custom Firestore clinics
                for (var customClinic in customClinics) {
                  mergedMap[customClinic.id] = customClinic;
                }

                List<ClinicModel> list = mergedMap.values.toList();

                // Search Filter
                final query = _searchCtrl.text.trim().toLowerCase();
                if (query.isNotEmpty) {
                  list = list.where((c) {
                    final nameMatch = c.name.toLowerCase().contains(query);
                    final addrMatch = c.address.toLowerCase().contains(query);
                    final phoneMatch = c.phone.toLowerCase().contains(query);
                    return nameMatch || addrMatch || phoneMatch;
                  }).toList();
                }

                // City Filter
                if (_selectedCity != 'All Cities') {
                  list = list.where((c) => c.city.toLowerCase().contains(_selectedCity.toLowerCase())).toList();
                }

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_hospital_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          "No clinics found",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _darkText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tap '+ Add Clinic' to register a new Penang veterinary hospital.",
                          style: TextStyle(fontSize: 12, color: _subText),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isCustom = firestoreDocs.any((doc) => doc.id == item.id);

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
                            // Header Row: Icon, Clinic Name, Rating & Custom Badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _yaleBlue.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.local_hospital_rounded, color: _yaleBlue, size: 24),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: _darkText,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isCustom)
                                            Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade100,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.amber.shade700, width: 0.8),
                                              ),
                                              child: Text(
                                                "Custom",
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber.shade900,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),

                                      Row(
                                        children: [
                                          Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 15),
                                          const SizedBox(width: 2),
                                          Text(
                                            "${item.rating.toStringAsFixed(1)} ",
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _darkText),
                                          ),
                                          Text(
                                            "(${item.reviewCount} reviews) • ${item.city}",
                                            style: TextStyle(fontSize: 11, color: _subText),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                if (isCustom) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                                    tooltip: "Edit Clinic",
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _openClinicModal(existing: item),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                                    tooltip: "Delete Clinic",
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _confirmDelete(item),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),

                            // Address & Phone
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: SelectableText(
                                    item.address,
                                    style: TextStyle(fontSize: 11, color: _darkText),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 15, color: Colors.grey),
                                const SizedBox(width: 4),
                                SelectableText(
                                  item.phone.isEmpty ? "No phone provided" : item.phone,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _yaleBlue),
                                ),
                                const Spacer(),
                                Icon(Icons.access_time_rounded, size: 13, color: _subText),
                                const SizedBox(width: 3),
                                Text(
                                  item.operatingHours,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _subText),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Services Offered Chips
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: item.services.map((svc) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _softBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    svc,
                                    style: TextStyle(fontSize: 10, color: _darkText, fontWeight: FontWeight.w500),
                                  ),
                                );
                              }).toList(),
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

  // Delete Confirmation
  void _confirmDelete(ClinicModel clinic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 26),
            const SizedBox(width: 8),
            const Text("Delete Clinic", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Are you sure you want to delete '${clinic.name}' from the Firestore database? This action cannot be undone.",
          style: TextStyle(fontSize: 13, color: _darkText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('CLINICS')
                    .doc(clinic.id)
                    .delete();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text("Deleted '${clinic.name}' successfully."),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text("Error deleting clinic: $e")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Add / Edit Modal Sheet
  void _openClinicModal({ClinicModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String selectedCity = existing?.city ?? 'George Town';
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final hoursCtrl = TextEditingController(text: existing?.operatingHours ?? '9am – 6pm');
    final ratingCtrl = TextEditingController(text: existing?.rating.toString() ?? '4.8');
    final reviewsCtrl = TextEditingController(text: existing?.reviewCount.toString() ?? '100');

    final List<String> selectedServices = List<String>.from(existing?.services ?? [
      'General Consultation',
      'Vaccination',
      'Deworming',
    ]);

    bool isSaving = false;

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
                          width: 38,
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
                          Icon(
                            existing == null ? Icons.add_business_rounded : Icons.edit_location_alt_rounded,
                            color: _yaleBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              existing == null ? "Register New Clinic" : "Edit Clinic Profile",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _darkText,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Input Penang veterinary hospital profile to save to Firebase Firestore.",
                        style: TextStyle(fontSize: 11, color: _subText),
                      ),
                      const SizedBox(height: 16),

                      // Clinic Name
                      TextField(
                        controller: nameCtrl,
                        style: TextStyle(fontSize: 13, color: _darkText),
                        decoration: InputDecoration(
                          labelText: "Clinic / Hospital Name *",
                          labelStyle: TextStyle(fontSize: 12, color: _subText),
                          hintText: "e.g., Mutiara Animal Hospital",
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // City Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedCity,
                        isExpanded: true,
                        style: TextStyle(fontSize: 13, color: _darkText, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: "City / Location (Penang) *",
                          labelStyle: TextStyle(fontSize: 12, color: _subText),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: _cities
                            .where((c) => c != 'All Cities')
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setSheetState(() => selectedCity = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Physical Address
                      TextField(
                        controller: addressCtrl,
                        style: TextStyle(fontSize: 13, color: _darkText),
                        decoration: InputDecoration(
                          labelText: "Physical Address *",
                          labelStyle: TextStyle(fontSize: 12, color: _subText),
                          hintText: "e.g., 12, Jalan Free School, 11600 George Town",
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Phone & Hours Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(fontSize: 13, color: _darkText),
                              decoration: InputDecoration(
                                labelText: "Phone Number *",
                                labelStyle: TextStyle(fontSize: 12, color: _subText),
                                hintText: "+60 4-281 1228",
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: hoursCtrl,
                              style: TextStyle(fontSize: 13, color: _darkText),
                              decoration: InputDecoration(
                                labelText: "Operating Hours *",
                                labelStyle: TextStyle(fontSize: 12, color: _subText),
                                hintText: "9am – 6pm",
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Rating & Reviews Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ratingCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(fontSize: 13, color: _darkText),
                              decoration: InputDecoration(
                                labelText: "Google Rating (e.g. 4.8)",
                                labelStyle: TextStyle(fontSize: 12, color: _subText),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: reviewsCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 13, color: _darkText),
                              decoration: InputDecoration(
                                labelText: "Review Count (e.g. 106)",
                                labelStyle: TextStyle(fontSize: 12, color: _subText),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Services Offered Checkboxes
                      Text(
                        "SERVICES OFFERED",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _subText, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _availableServices.map((svc) {
                          final isSelected = selectedServices.contains(svc);
                          return FilterChip(
                            label: Text(svc, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : _darkText)),
                            selected: isSelected,
                            selectedColor: _yaleBlue,
                            backgroundColor: _softBg,
                            onSelected: (val) {
                              setSheetState(() {
                                if (val) {
                                  selectedServices.add(svc);
                                } else {
                                  selectedServices.remove(svc);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      FocusScope.of(context).unfocus();
                                      Navigator.pop(context);
                                    },
                              child: Text("Cancel", style: TextStyle(color: _darkText, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _yaleBlue,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      FocusScope.of(context).unfocus();

                                      final name = nameCtrl.text.trim();
                                      final address = addressCtrl.text.trim();
                                      final phone = phoneCtrl.text.trim();

                                      if (name.isEmpty || address.isEmpty || phone.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Please enter Clinic Name, Address, and Phone.")),
                                        );
                                        return;
                                      }

                                      setSheetState(() => isSaving = true);

                                      final docId = existing?.id ?? "clinic_${DateTime.now().millisecondsSinceEpoch}";
                                      final double rating = double.tryParse(ratingCtrl.text.trim()) ?? 4.8;
                                      final int reviews = int.tryParse(reviewsCtrl.text.trim()) ?? 100;

                                      final newClinic = ClinicModel(
                                        id: docId,
                                        name: name,
                                        specialty: 'General Veterinary & Surgery',
                                        rating: rating,
                                        reviewCount: reviews,
                                        distanceKm: 1.0,
                                        operatingHours: hoursCtrl.text.trim(),
                                        city: selectedCity,
                                        address: address,
                                        phone: phone,
                                        latitude: 5.4164,
                                        longitude: 100.3327,
                                        services: selectedServices,
                                      );

                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('CLINICS')
                                            .doc(docId)
                                            .set(newClinic.toMap());

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Successfully saved '$name' to Firebase!"),
                                              backgroundColor: Colors.green.shade700,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setSheetState(() => isSaving = false);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Error saving clinic: $e")),
                                          );
                                        }
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      existing == null ? "Save to Firebase" : "Update Clinic",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
}
