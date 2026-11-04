import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/breed_model.dart';
import '../../services/breed_service.dart';
import '../../utils/unsaved_changes_dialog.dart';
import '../widgets/fringe_header.dart';

/// BreedManagementScreen: Admin screen for viewing full dog and cat breeds list,
/// filtering by species/size, and adding, editing, or deleting custom breeds in Firestore.
class BreedManagementScreen extends StatefulWidget {
  const BreedManagementScreen({super.key});

  @override
  State<BreedManagementScreen> createState() => _BreedManagementScreenState();
}

class _BreedManagementScreenState extends State<BreedManagementScreen> {
  // Theme Palette
  final Color _pacificBlue = const Color(0xFF386FA4);
  final Color _softBg = const Color(0xFFF4F7F6);
  final Color _darkText = const Color(0xFF2D3142);
  final Color _subText = const Color(0xFF6C757D);

  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedSpeciesFilter = 'All';
  String _selectedSizeFilter = 'All Sizes';

  final List<String> _speciesFilters = ['All', 'Dog', 'Cat'];
  final List<String> _sizeFilters = ['All Sizes', 'Small', 'Medium', 'Large'];

  @override
  void initState() {
    super.initState();
    BreedService().loadBreeds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
      body: Column(
        children: [
          FringeHeader(
            title: "Breeds Database",
            subtitle: "Dog & Cat Breed Management",
            backgroundColor: _pacificBlue,
            onBack: () => Navigator.pop(context),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Search Bar + Add Breed Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(fontSize: 13, color: _darkText),
                        decoration: InputDecoration(
                          hintText: "Search breeds by name...",
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
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
                        backgroundColor: _pacificBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                      ),
                      onPressed: () => _openBreedModal(),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        "Add Breed",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Species & Size Category Filter Chips Row
                Row(
                  children: [
                    // Species Chips
                    ..._speciesFilters.map((sp) {
                      final isSel = _selectedSpeciesFilter == sp;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(sp),
                          selected: isSel,
                          selectedColor: _pacificBlue,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : _darkText,
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(color: isSel ? _pacificBlue : Colors.grey.shade300),
                          onSelected: (_) => setState(() => _selectedSpeciesFilter = sp),
                        ),
                      );
                    }),
                    const Spacer(),

                    // Size Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSizeFilter,
                          isDense: true,
                          style: TextStyle(fontSize: 11, color: _darkText, fontWeight: FontWeight.w600),
                          items: _sizeFilters.map((size) {
                            return DropdownMenuItem(
                              value: size,
                              child: Text(size),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSizeFilter = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Breed List (Firestore Real-time Stream + Offline JSON merged)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('BREEDS').snapshots(),
              builder: (context, snapshot) {
                final firestoreDocs = snapshot.data?.docs ?? [];
                final customBreeds = firestoreDocs.map((doc) {
                  final data = doc.data();
                  data['breedId'] = doc.id;
                  return BreedModel.fromJson(data);
                }).toList();

                final Map<String, BreedModel> mergedMap = {};

                // 1. Base breeds from JSON
                for (var breed in BreedService().breeds) {
                  mergedMap[breed.breedId] = breed;
                }

                // 2. Custom breeds from Firestore
                for (var customB in customBreeds) {
                  mergedMap[customB.breedId] = customB;
                }

                List<BreedModel> list = mergedMap.values.toList();

                // Text search filter
                final query = _searchCtrl.text.trim().toLowerCase();
                if (query.isNotEmpty) {
                  list = list.where((b) => b.name.toLowerCase().contains(query)).toList();
                }

                // Species filter
                if (_selectedSpeciesFilter != 'All') {
                  list = list.where((b) => b.species.toLowerCase() == _selectedSpeciesFilter.toLowerCase()).toList();
                }

                // Size filter
                if (_selectedSizeFilter != 'All Sizes') {
                  list = list.where((b) => b.sizeCategory.toLowerCase() == _selectedSizeFilter.toLowerCase()).toList();
                }

                // Sort alphabetically
                list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets_rounded, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          "No breeds found",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _darkText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tap '+ Add Breed' to add a new dog or cat breed.",
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
                    final isCustom = firestoreDocs.any((doc) => doc.id == item.breedId);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 1.2,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.species.toLowerCase() == 'dog'
                                    ? Colors.amber.shade50
                                    : Colors.purple.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.species.toLowerCase() == 'dog'
                                    ? Icons.pets_rounded
                                    : Icons.pest_control_rodent_rounded,
                                color: item.species.toLowerCase() == 'dog'
                                    ? Colors.amber.shade800
                                    : Colors.purple.shade700,
                                size: 22,
                              ),
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
                                            fontSize: 14,
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
                                  const SizedBox(height: 4),

                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      // Species Tag
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.species,
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _subText),
                                        ),
                                      ),

                                      // Size Category Tag
                                      _buildSizeBadge(item.sizeCategory),

                                      // Avg Weight Text
                                      Text(
                                        "Avg: ${item.avgAdultWeightKg.toStringAsFixed(1)} kg",
                                        style: TextStyle(fontSize: 11, color: _darkText, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            if (isCustom) ...[
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                                tooltip: "Edit Breed",
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _openBreedModal(existing: item),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                                tooltip: "Delete Breed",
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _confirmDelete(item),
                              ),
                            ],
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

  Widget _buildSizeBadge(String sizeCategory) {
    Color bg;
    Color border;
    Color textColor;

    switch (sizeCategory.toLowerCase()) {
      case 'small':
        bg = Colors.teal.shade50;
        border = Colors.teal.shade300;
        textColor = Colors.teal.shade800;
        break;
      case 'medium':
        bg = Colors.blue.shade50;
        border = Colors.blue.shade300;
        textColor = Colors.blue.shade800;
        break;
      case 'large':
        bg = Colors.purple.shade50;
        border = Colors.purple.shade300;
        textColor = Colors.purple.shade800;
        break;
      default:
        bg = Colors.grey.shade100;
        border = Colors.grey.shade300;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        sizeCategory,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  // Delete Breed Confirmation
  void _confirmDelete(BreedModel breed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 26),
            const SizedBox(width: 8),
            const Text("Delete Breed", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Are you sure you want to delete '${breed.name}' from the Firestore database? This action cannot be undone.",
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
                    .collection('BREEDS')
                    .doc(breed.breedId)
                    .delete();

                await BreedService().loadBreeds(forceRefresh: true);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text("Deleted '${breed.name}' successfully."),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text("Error deleting breed: $e")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Modal Sheet to Add / Edit Breed
  void _openBreedModal({BreedModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String selectedSpecies = existing?.species ?? 'Dog';
    String selectedSize = existing?.sizeCategory ?? 'Small';
    final weightCtrl = TextEditingController(
        text: existing != null ? existing.avgAdultWeightKg.toString() : '5.0');

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
            bool checkUnsavedChanges() {
              if (existing == null) {
                if (nameCtrl.text.trim().isNotEmpty) return true;
                if (selectedSpecies != 'Dog') return true;
                if (selectedSize != 'Small') return true;
                if (weightCtrl.text.trim() != '5.0') return true;
                return false;
              } else {
                if (nameCtrl.text.trim() != existing.name) return true;
                if (selectedSpecies != existing.species) return true;
                if (selectedSize != existing.sizeCategory) return true;
                if (weightCtrl.text.trim() != existing.avgAdultWeightKg.toString()) return true;
                return false;
              }
            }

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return;
                if (isSaving || !checkUnsavedChanges()) {
                  Navigator.of(context).pop();
                  return;
                }
                final bool shouldDiscard = await showUnsavedChangesDialog(context);
                if (shouldDiscard && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: GestureDetector(
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
                              existing == null ? Icons.add_circle_outline_rounded : Icons.edit_note_rounded,
                              color: _pacificBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                existing == null ? "Add New Breed" : "Edit Breed",
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
                                Navigator.maybePop(context);
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        "Add a dog or cat breed to Firebase Firestore for automatic size and DER calculation.",
                        style: TextStyle(fontSize: 11, color: _subText),
                      ),
                      const SizedBox(height: 16),

                      // Breed Name Input
                      TextField(
                        controller: nameCtrl,
                        style: TextStyle(fontSize: 13, color: _darkText),
                        decoration: InputDecoration(
                          labelText: "Breed Name *",
                          labelStyle: TextStyle(fontSize: 12, color: _subText),
                          hintText: "e.g., Goldendoodle, British Longhair, Dachshund",
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Species Selection (Dog vs Cat)
                      Text(
                        "SPECIES *",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _subText, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text("Dog")),
                              selected: selectedSpecies == 'Dog',
                              selectedColor: _pacificBlue,
                              labelStyle: TextStyle(
                                color: selectedSpecies == 'Dog' ? Colors.white : _darkText,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (_) => setSheetState(() => selectedSpecies = 'Dog'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text("Cat")),
                              selected: selectedSpecies == 'Cat',
                              selectedColor: _pacificBlue,
                              labelStyle: TextStyle(
                                color: selectedSpecies == 'Cat' ? Colors.white : _darkText,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (_) => setSheetState(() => selectedSpecies = 'Cat'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Size Category & Weight Row
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedSize,
                              isExpanded: true,
                              style: TextStyle(fontSize: 13, color: _darkText, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                labelText: "Size Category *",
                                labelStyle: TextStyle(fontSize: 12, color: _subText),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Small', child: Text("Small")),
                                DropdownMenuItem(value: 'Medium', child: Text("Medium")),
                                DropdownMenuItem(value: 'Large', child: Text("Large")),
                              ],
                              onChanged: (val) {
                                if (val != null) setSheetState(() => selectedSize = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: weightCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(fontSize: 13, color: _darkText),
                              decoration: InputDecoration(
                                labelText: "Avg Weight (kg) *",
                                labelStyle: TextStyle(fontSize: 12, color: _subText),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
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
                                      Navigator.maybePop(context);
                                    },
                              child: Text("Cancel", style: TextStyle(color: _darkText, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pacificBlue,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      FocusScope.of(context).unfocus();

                                      final name = nameCtrl.text.trim();
                                      if (name.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Please enter a Breed Name.")),
                                        );
                                        return;
                                      }

                                      setSheetState(() => isSaving = true);

                                      final docId = existing?.breedId ?? "${selectedSpecies.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}";
                                      final double weight = double.tryParse(weightCtrl.text.trim()) ?? 5.0;

                                      final newBreed = BreedModel(
                                        breedId: docId,
                                        species: selectedSpecies,
                                        name: name,
                                        sizeCategory: selectedSize,
                                        avgAdultWeightKg: weight,
                                      );

                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('BREEDS')
                                            .doc(docId)
                                            .set(newBreed.toJson());

                                        await BreedService().loadBreeds(forceRefresh: true);

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Successfully saved breed '$name' to Firebase!"),
                                              backgroundColor: Colors.green.shade700,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setSheetState(() => isSaving = false);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Error saving breed: $e")),
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
                                      existing == null ? "Save to Firebase" : "Update Breed",
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
            ),
          );
        },
      ),
    );
  }
}
