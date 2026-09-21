import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../providers/nutritional_provider.dart';
import '../../models/pet_model.dart';
import '../../services/pet_service.dart';
import '../login_screen.dart';
import '../nutrition/nutrition_engine_screen.dart';

/// UserHomeScreen: Redesigned dashboard for Pet Owners.
/// Features a "Modern Layered" pet passport experience and functional navigation.
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  // Official Morandi Natural Palette
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _lightBronze = const Color(0xFFCB997E);
  final Color _desertSand = const Color(0xFFDDBEA9);
  final Color _drySage = const Color(0xFFA5A58D);
  final Color _ashGrey = const Color(0xFFB7B7A4);
  final Color _darkCharcoal = const Color(0xFF2D3142);
  final Color _errorCoral = const Color(0xFFB56576);

  final PetService _petService = PetService();
  final ImagePicker _picker = ImagePicker();

  int _selectedIndex = 0;
  late PageController _pageController;
  double _currentPage = 0;
  Map<String, dynamic> _breedData = {};

  @override
  void initState() {
    super.initState();
    _loadBreedData();
    _pageController = PageController(viewportFraction: 0.8)
      ..addListener(() {
        if (_pageController.hasClients) {
          setState(() {
            _currentPage = _pageController.page ?? 0;
          });
        }
      });
  }

  Future<void> _loadBreedData() async {
    try {
      final String response = await rootBundle.loadString('assets/data/breeds.json');
      setState(() => _breedData = json.decode(response));
    } catch (e) {
      debugPrint("Error loading breeds: $e");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning,";
    if (hour < 18) return "Good afternoon,";
    return "Good evening,";
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Provider.of<UserProvider>(context, listen: false).clearUser();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // --- NUTRITION ROUTING LOGIC ---

  void _handleNutritionTap(List<PetProfile> pets) {
    if (pets.isNotEmpty) {
      _showPetSelectionSheet(pets);
    } else {
      _showComingSoon("Quick Input Form");
    }
  }

  void _showPetSelectionSheet(List<PetProfile> pets) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _powderPetal,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Select Pet for Nutrition", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkCharcoal)),
            const SizedBox(height: 20),
            ...pets.map((pet) => _buildSelectionItem(pet)),
            _buildSelectionItem(null), // "Other" option
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionItem(PetProfile? pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(pet == null ? Icons.pets : Icons.circle, color: _dustyOlive),
        title: Text(pet?.name ?? "Other (External Pet)", style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal)),
        onTap: () {
          Navigator.pop(context);
          if (pet != null) {
            Provider.of<NutritionalProvider>(context, listen: false).setSelectedPet(pet);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionEngineScreen()));
          } else {
            _showComingSoon("Quick Input Form");
          }
        },
      ),
    );
  }

  // --- INTERACTIVE DIALOGS ---

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("$feature Coming Soon!", style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold)),
        content: Text("We are working hard to bring the $feature module to PawKODA. Stay tuned!", style: TextStyle(color: _darkCharcoal)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Okay", style: TextStyle(color: _dustyOlive, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddPetDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController weightCtrl = TextEditingController(text: "1.0");
    final TextEditingController otherAllergenCtrl = TextEditingController();
    
    Species? selectedSpecies;
    String? selectedBreed;
    DateTime? selectedBirthDate;
    XFile? petImage;
    List<String> selectedAllergens = [];
    bool hasNoAllergies = false;
    bool isSaving = false; // Added state for double-click prevention

    final List<String> commonAllergens = ["Chicken", "Beef", "Fish", "Egg", "Grain", "Dairy"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setMState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: _desertSand, // Changed to Desert Sand as requested
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 25),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: InkWell(
                      onTap: () async {
                        // Custom Source Selection Sheet
                        _showImageSourceSheet(setMState, (image) => petImage = image);
                      },
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _ashGrey, width: 2),
                          image: petImage != null 
                            ? DecorationImage(image: FileImage(File(petImage!.path)), fit: BoxFit.cover)
                            : null,
                        ),
                        child: petImage == null ? Icon(Icons.add_a_photo, color: _ashGrey, size: 40) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Add New Pet", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _darkCharcoal)),
                  const SizedBox(height: 8),
                  Text("Create a digital health passport.", style: TextStyle(color: _darkCharcoal.withAlpha(200), fontSize: 14)),
                  const SizedBox(height: 32),
                  
                  _buildFormLabel("PET NAME"),
                  _buildTextField(nameCtrl, "e.g. Buddy"),
                  
                  const SizedBox(height: 20),
                  _buildFormLabel("SPECIES"),
                  Row(
                    children: [
                      _buildSpeciesChip("Dog", Species.dog, selectedSpecies, (s) {
                        setMState(() {
                          selectedSpecies = s;
                          selectedBreed = null;
                        });
                      }),
                      const SizedBox(width: 12),
                      _buildSpeciesChip("Cat", Species.cat, selectedSpecies, (s) {
                        setMState(() {
                          selectedSpecies = s;
                          selectedBreed = null;
                        });
                      }),
                    ],
                  ),

                  if (selectedSpecies != null) ...[
                    const SizedBox(height: 20),
                    _buildFormLabel("BREED"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(180),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBreed, isExpanded: true, 
                          hint: Text("Select Breed", style: TextStyle(color: _darkCharcoal.withAlpha(120))),
                          items: (_breedData[selectedSpecies!.name] as List<dynamic>?)?.map((b) => DropdownMenuItem<String>(
                            value: b.toString(),
                            child: Text(b.toString()),
                          )).toList() ?? [],
                          onChanged: (val) => setMState(() => selectedBreed = val),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  _buildFormLabel("WEIGHT (KG)"),
                  Row(
                    children: [
                      _buildStepperButton(Icons.remove, () {
                        double val = double.tryParse(weightCtrl.text) ?? 0.0;
                        if (val > 1.0) setMState(() => weightCtrl.text = (val - 1.0).toStringAsFixed(1));
                      }),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: weightCtrl,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            fillColor: Colors.white.withAlpha(180),
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildStepperButton(Icons.add, () {
                        double val = double.tryParse(weightCtrl.text) ?? 0.0;
                        setMState(() => weightCtrl.text = (val + 1.0).toStringAsFixed(1));
                      }),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildFormLabel("BIRTHDATE"),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setMState(() => selectedBirthDate = picked);
                      },
                      icon: Icon(Icons.calendar_month, color: _dustyOlive),
                      label: Text(
                        selectedBirthDate == null ? "Choose Date" : DateFormat('dd MMM yyyy').format(selectedBirthDate!), 
                        style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _darkCharcoal, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildFormLabel("ALLERGIES"),
                  // Two-Column Allergen Layout
                  Wrap(
                    children: commonAllergens.map((allergen) => SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4, // Approx half width
                      child: CheckboxListTile(
                        title: Text(allergen, style: TextStyle(color: _darkCharcoal, fontSize: 16, fontWeight: FontWeight.w600)),
                        value: selectedAllergens.contains(allergen) && !hasNoAllergies,
                        onChanged: hasNoAllergies ? null : (val) {
                          setMState(() {
                            if (val!) {
                              selectedAllergens.add(allergen);
                            } else {
                              selectedAllergens.remove(allergen);
                            }
                          });
                        },
                        activeColor: _dustyOlive,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )).toList(),
                  ),
                  CheckboxListTile(
                    title: Row(
                      children: [
                        const Text("Others: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Expanded(
                          child: TextField(
                            controller: otherAllergenCtrl,
                            enabled: !hasNoAllergies,
                            decoration: InputDecoration(
                              hintText: "Specify...", 
                              hintStyle: TextStyle(color: _darkCharcoal.withAlpha(120)),
                              isDense: true, 
                              border: InputBorder.none
                            ),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    value: selectedAllergens.contains("Other") && !hasNoAllergies,
                    onChanged: hasNoAllergies ? null : (val) {
                      setMState(() {
                        if (val!) {
                          selectedAllergens.add("Other");
                        } else {
                          selectedAllergens.remove("Other");
                        }
                      });
                    },
                    activeColor: _dustyOlive,
                    checkColor: Colors.white,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  // "No Allergies" Radio Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: const Text("No Allergies", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                      leading: Radio<bool>(
                        value: true,
                        groupValue: hasNoAllergies,
                        activeColor: _dustyOlive,
                        onChanged: (val) {
                          setMState(() {
                            hasNoAllergies = val!;
                            if (hasNoAllergies) selectedAllergens.clear();
                          });
                        },
                      ),
                      onTap: () {
                        setMState(() {
                          hasNoAllergies = !hasNoAllergies;
                          if (hasNoAllergies) selectedAllergens.clear();
                        });
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        // Validation: All sections required
                        if (nameCtrl.text.isEmpty || selectedSpecies == null || selectedBreed == null || 
                            selectedBirthDate == null || (!hasNoAllergies && selectedAllergens.isEmpty && otherAllergenCtrl.text.isEmpty)) {
                          _showPawDialog("Missing Information", "Please fill in all sections to create a passport.", isError: true);
                          return;
                        }

                        setMState(() => isSaving = true);

                        final uid = Provider.of<UserProvider>(context, listen: false).uid;
                        if (uid == null) {
                          setMState(() => isSaving = false);
                          return;
                        }
                        
                        List<String> allergens = List.from(selectedAllergens);
                        if (allergens.contains("Other")) {
                          allergens.remove("Other");
                          if (otherAllergenCtrl.text.isNotEmpty) {
                            allergens.add(otherAllergenCtrl.text.trim());
                          }
                        }

                        final newPet = PetProfile(
                          id: "", 
                          name: nameCtrl.text.trim(),
                          species: selectedSpecies!,
                          weightKg: double.tryParse(weightCtrl.text) ?? 0.0,
                          birthDate: selectedBirthDate!,
                          condition: PetCondition.neutered,
                          allergens: allergens,
                          breed: selectedBreed!,
                          imageUrl: petImage?.path,
                        );

                        try {
                          await _petService.addPet(uid, newPet);
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          debugPrint("Error creating pet: $e");
                          if (context.mounted) {
                            setMState(() => isSaving = false);
                            _showPawDialog(
                              "Connection Issue", 
                              "Unable to reach the database. Please check your internet connection and try again.", 
                              isError: true
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dustyOlive,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isSaving 
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text("Create Passport", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageSourceSheet(StateSetter setMState, Function(XFile?) onImagePicked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choose Photo Source", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const SizedBox(height: 30),
            _buildSourceTile(
              icon: Icons.camera_alt_rounded,
              label: "Take a Photo",
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                onImagePicked(image);
                setMState(() {});
                if (mounted) Navigator.pop(context);
              }
            ),
            _buildSourceTile(
              icon: Icons.photo_library_rounded,
              label: "Choose from Gallery",
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                onImagePicked(image);
                setMState(() {});
                if (mounted) Navigator.pop(context);
              }
            ),
            _buildSourceTile(
              icon: Icons.folder_rounded,
              label: "Browse Files",
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery); // Fallback to gallery for browse
                onImagePicked(image);
                setMState(() {});
                if (mounted) Navigator.pop(context);
              }
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: _powderPetal.withAlpha(100), borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: _dustyOlive),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal)),
        onTap: onTap,
      ),
    );
  }

  void _showPawDialog(String title, String message, {required bool isError, VoidCallback? onConfirm}) {
    final Color successColor = const Color(0xFFD4C2AD);
    final Color errorColor = const Color(0xFFB56576); 
    final Color darkText = const Color(0xFF2D3142);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? errorColor : successColor, size: 50),
            const SizedBox(height: 15),
            Text(title, style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, textAlign: TextAlign.center, style: TextStyle(color: darkText)),
        actions: [
          Center(
            child: SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: isError ? errorColor : successColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                onPressed: () { Navigator.pop(context); if (onConfirm != null) onConfirm(); },
                child: Text("Okay", style: TextStyle(color: isError ? Colors.white : darkText, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePet(BuildContext context, String petId, String petName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Remove Passport?", style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to remove the passport for $petName? This cannot be undone.", style: TextStyle(color: _darkCharcoal)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: _ashGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorCoral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final uid = Provider.of<UserProvider>(context, listen: false).uid;
              Navigator.pop(context); // Close dialog immediately for responsiveness
              if (uid != null) {
                await _petService.deletePet(uid, petId);
              }
            },
            child: const Text("Remove", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _darkCharcoal)));
  Widget _buildTextField(TextEditingController ctrl, String hint) => TextField(controller: ctrl, style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: _darkCharcoal.withAlpha(120)), fillColor: Colors.white.withAlpha(180), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
  
  Widget _buildSpeciesChip(String label, Species species, Species? selected, Function(Species) onSelect) {
    bool isSelected = selected == species;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 15)),
      selected: isSelected,
      selectedColor: _dustyOlive,
      backgroundColor: Colors.white.withAlpha(150),
      showCheckmark: false,
      avatar: isSelected ? const Icon(Icons.check_circle, color: Colors.white, size: 22) : null,
      onSelected: (v) => onSelect(species),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
    );
  }
  
  Widget _buildStepperButton(IconData icon, VoidCallback onTap) => Container(width: 50, height: 50, decoration: BoxDecoration(color: _dustyOlive, borderRadius: BorderRadius.circular(12)), child: IconButton(icon: Icon(icon, color: Colors.white, size: 20), onPressed: onTap));

  // --- MAIN BUILD ---

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<UserProvider>().uid ?? "";
    return StreamBuilder<List<PetProfile>>(
      stream: _petService.streamUserPets(uid),
      builder: (context, snapshot) {
        final pets = snapshot.data ?? [];
        final views = [
          _buildDashboard(context, pets),
          _buildPlaceholderView("Health Records", Icons.favorite, _drySage),
          _buildPlaceholderView("Bookings", Icons.calendar_month, _desertSand),
          _buildProfileView(context)
        ];
        return Scaffold(backgroundColor: _drySage, body: views[_selectedIndex], bottomNavigationBar: _buildBottomNav());
      }
    );
  }

  Widget _buildDashboard(BuildContext context, List<PetProfile> pets) {
    final userName = context.watch<UserProvider>().displayName ?? 'Friend';
    final healthyCount = pets.where((p) => p.isHealthy).length;
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_getGreeting(), style: const TextStyle(color: Colors.white, fontSize: 17)), Text(userName, style: const TextStyle(fontSize: 29, fontWeight: FontWeight.bold, color: Colors.white))]),
                  Row(children: [
                    IconButton(onPressed: () => _handleLogout(context), icon: const Icon(Icons.logout_rounded, color: Colors.white)),
                    Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white), child: CircleAvatar(radius: 22, backgroundColor: _powderPetal, child: Text(userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : '?', style: TextStyle(color: _dustyOlive, fontWeight: FontWeight.bold)))),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withAlpha(204), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white, width: 1.5)),
                child: Row(children: [
                  Icon(Icons.health_and_safety, color: _dustyOlive, size: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("${pets.length} registered:", style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("$healthyCount healthy; ${pets.length - healthyCount} needs attention", style: TextStyle(color: _darkCharcoal.withAlpha(180), fontSize: 14, fontWeight: FontWeight.w500)),
                  ])),
                ]),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("My Pet Passports", style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.white)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6), decoration: BoxDecoration(color: _darkCharcoal, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10)]), child: InkWell(onTap: _showAddPetDialog, child: Text("+ Add Pet", style: TextStyle(color: _lightBronze, fontWeight: FontWeight.bold, fontSize: 17)))),
              ]),
            ),
            const SizedBox(height: 10),
            if (pets.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text("No pets registered yet.\nTap + Add Pet to start!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 16))))
            else
              SizedBox(height: 390, child: PageView.builder(controller: _pageController, itemCount: pets.length, itemBuilder: (context, index) {
                double scale = (1 - ((_currentPage - index).abs() * 0.1)).clamp(0.8, 1.0);
                final pet = pets[index];
                int y = (pet.ageInMonths / 12).floor(); int m = pet.ageInMonths % 12;
                return _buildPetCard(
                  scale: scale, 
                  id: pet.id,
                  name: pet.name, 
                  species: pet.species.name.toUpperCase(), 
                  breed: pet.breed, 
                  age: "${y}y, ${m}m", 
                  weight: "${pet.weightKg} kg", 
                  isHealthy: pet.isHealthy, 
                  imageUrl: pet.imageUrl,
                  context: context,
                );
              })),
            const SizedBox(height: 40),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: const Text("Quick Actions", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white))),
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _buildActionItem(Icons.restaurant, "Nutrition", _lightBronze, () => _handleNutritionTap(pets)),
              _buildActionItem(Icons.medical_services, "Meds", _powderPetal, () => setState(() => _selectedIndex = 1)),
              _buildActionItem(Icons.calendar_today, "Book Vet", _desertSand, () => setState(() => _selectedIndex = 2)),
              _buildActionItem(Icons.assignment, "Records", _powderPetal, () => setState(() => _selectedIndex = 1)),
            ])),
            const SizedBox(height: 40),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: const Text("Upcoming Reminders", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white))),
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: InkWell(onTap: () => _showComingSoon("Reminders"), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _lightBronze.withAlpha(30), shape: BoxShape.circle), child: Icon(Icons.vaccines, color: _lightBronze, size: 26)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Vaccine Checkup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _darkCharcoal)), Text(pets.isNotEmpty ? "${pets.first.name} • 5 Nov 2024" : "Add a pet to set reminders", style: TextStyle(color: _ashGrey, fontSize: 16))])),
              Icon(Icons.chevron_right, color: _ashGrey),
            ])))),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderView(String t, IconData i, Color c) => Container(color: c, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 80, color: Colors.white.withAlpha(150)), const SizedBox(height: 20), Text(t, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 10), const Text("Coming Soon", style: TextStyle(color: Colors.white70)), const SizedBox(height: 30), ElevatedButton(onPressed: () => setState(() => _selectedIndex = 0), style: ElevatedButton.styleFrom(backgroundColor: _darkCharcoal), child: const Text("Back to Dashboard", style: TextStyle(color: Colors.white)))])));

  Widget _buildProfileView(BuildContext context) {
    final up = context.watch<UserProvider>();
    return Container(color: _drySage, child: SafeArea(child: Padding(padding: const EdgeInsets.all(24.0), child: Column(children: [
      const SizedBox(height: 40),
      CircleAvatar(radius: 60, backgroundColor: _powderPetal, child: Text(up.displayName?.isNotEmpty == true ? up.displayName!.substring(0, 1).toUpperCase() : "?", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _dustyOlive))),
      const SizedBox(height: 20),
      Text(up.displayName ?? "User", style: const TextStyle(fontSize: 31, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(up.email ?? "", style: const TextStyle(color: Colors.white70, fontSize: 17)),
      const SizedBox(height: 40),
      _profileTile(Icons.person, "Edit Profile"), _profileTile(Icons.pets, "Manage My Pets"), _profileTile(Icons.notifications, "Notifications"),
      const Spacer(),
      SizedBox(width: double.infinity, height: 55, child: ElevatedButton.icon(onPressed: () => _handleLogout(context), icon: const Icon(Icons.logout, color: Colors.white), label: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: _errorCoral))),
    ]))));
  }

  Widget _profileTile(IconData i, String t) => Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(16)), child: ListTile(leading: Icon(i, color: Colors.white), title: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 17)), trailing: const Icon(Icons.chevron_right, color: Colors.white70)));

  Widget _buildPetCard({
    required double scale, 
    required String id, // Added ID for deletion
    required String name, 
    required String species, 
    required String breed, 
    required String age, 
    required String weight, 
    required bool isHealthy, 
    required String? imageUrl,
    required BuildContext context, // Added context for dialogs
  }) {
    ImageProvider? imgProvider;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        imgProvider = NetworkImage(imageUrl);
      } else {
        imgProvider = FileImage(File(imageUrl));
      }
    }

    return Transform.scale(
      scale: scale, 
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), 
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(32), 
          border: Border.all(color: _ashGrey.withAlpha(50), width: 1.5), 
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10))]
        ), 
        child: Column(
          children: [
            Expanded(
              flex: 3, 
              child: Stack(
                children: [
                  Container(
                    width: double.infinity, 
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), 
                      color: const Color(0xFFF0F0F0),
                      image: imgProvider != null ? DecorationImage(image: imgProvider, fit: BoxFit.cover) : null,
                    ),
                    child: imgProvider == null 
                      ? Center(
                          child: Icon(
                            species.toLowerCase() == 'dog' ? Icons.pets : Icons.pets, 
                            size: 80, 
                            color: _ashGrey.withAlpha(150)
                          ),
                        ) 
                      : null,
                  ), 
                  // Delete Button
                  Positioned(
                    top: 15,
                    left: 15,
                    child: InkWell(
                      onTap: () => _confirmDeletePet(context, id, name),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(200),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delete_outline_rounded, color: _errorCoral, size: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20, 
                    right: 20, 
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(220), 
                        borderRadius: BorderRadius.circular(20), 
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 5)],
                      ), 
                      child: Row(
                        mainAxisSize: MainAxisSize.min, 
                        children: [
                          CircleAvatar(radius: 4, backgroundColor: isHealthy ? Colors.green : Colors.red), 
                          const SizedBox(width: 6), 
                          Text(
                            isHealthy ? "Healthy" : "Needs Attention", 
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isHealthy ? Colors.green : Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2, 
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _darkCharcoal)), 
                        Text(species, style: TextStyle(color: _ashGrey, fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ), 
                    Text(breed, style: TextStyle(color: _ashGrey, fontSize: 15)), 
                    const SizedBox(height: 4), 
                    Row(
                      children: [
                        Expanded(child: _buildInfoChip("Age", age)), 
                        const SizedBox(width: 12), 
                        Expanded(child: _buildInfoChip("Weight", weight)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String l, String v) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _ashGrey.withAlpha(140), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: TextStyle(fontSize: 13, color: _dustyOlive, fontWeight: FontWeight.bold)), Text(v, style: TextStyle(fontSize: 17, color: _darkCharcoal, fontWeight: FontWeight.bold))]));
  Widget _buildActionItem(IconData i, String l, Color c, VoidCallback o) => InkWell(onTap: o, borderRadius: BorderRadius.circular(22), child: Column(children: [Container(height: 70, width: 70, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))]), child: Icon(i, color: _dustyOlive, size: 30)), const SizedBox(height: 8), Text(l, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white))]));
  Widget _buildBottomNav() => Container(height: 85, decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 15)]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_navIcon(Icons.home_filled, "Home", 0), _navIcon(Icons.favorite_border, "Health", 1), _navIcon(Icons.calendar_month_outlined, "Bookings", 2), _navIcon(Icons.person_outline, "Profile", 3)]));
  Widget _navIcon(IconData i, String l, int idx) => InkWell(onTap: () => setState(() => _selectedIndex = idx), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: _selectedIndex == idx ? _dustyOlive : _ashGrey, size: 26), const SizedBox(height: 4), Text(l, style: TextStyle(fontSize: 10, color: _selectedIndex == idx ? _dustyOlive : _ashGrey, fontWeight: _selectedIndex == idx ? FontWeight.bold : FontWeight.normal))]));
}
