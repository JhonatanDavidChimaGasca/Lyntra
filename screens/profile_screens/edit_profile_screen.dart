import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_locator.dart';
import '../../core/profile/profile_controller.dart';
import '../../widgets/app_side_menu.dart';

import '../promo_codes_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final ProfileController _profile = ProfileController.instance;

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _nickNameCtrl;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _addressCtrl;
  late String _country;
  late String? _gender;

  late String _phoneIsoCode;
  late String _phoneDialCode;
  late String _phoneRawNumber;

  bool _isLoading = false;

  static const List<String> _countries = [
    "United States",
    "Colombia",
    "Mexico",
    "Spain",
    "Argentina",
    "Chile",
    "Peru",
  ];

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(text: _profile.fullName);
    _nickNameCtrl = TextEditingController(text: _profile.nickName);
    _labelCtrl = TextEditingController(text: _profile.label);
    _addressCtrl = TextEditingController(text: _profile.address);
    _country = _countries.contains(_profile.country) ? _profile.country : _countries.first;
    _gender = ProfileController.genderOptions.contains(_profile.gender) ? _profile.gender : null;

    _phoneIsoCode = _profile.phoneIsoCode;
    _phoneDialCode = _profile.phoneCode;
    _phoneRawNumber = _profile.phoneNumber;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nickNameCtrl.dispose();
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String fullName = _fullNameCtrl.text.trim();
    final String nickName = _nickNameCtrl.text.trim();
    final String label = _labelCtrl.text.trim();
    final String address = _addressCtrl.text.trim();
    final String gender = _gender ?? '';

    try {
      final currentUser = AppLocator.auth.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
          'fullName': fullName,
          'nickName': nickName,
          'label': label,
          'country': _country,
          'gender': gender,
          'address': address,
          'phoneCode': _phoneDialCode,
          'phoneNumber': _phoneRawNumber,
          'phoneIsoCode': _phoneIsoCode,
          'photoUrl': _profile.photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _profile.updatePersonalInfo(
          fullName: fullName,
          nickName: nickName,
          label: label,
          phoneCode: _phoneDialCode,
          phoneNumber: _phoneRawNumber,
          phoneIsoCode: _phoneIsoCode,
          country: _country,
          gender: gender,
          address: address,
        );
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil actualizado en Firestore")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar en Firebase: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  static const TextStyle _fieldTextStyle = TextStyle(color: Colors.black87);
  static const TextStyle _labelTextStyle = TextStyle(color: Colors.black54);
  static const TextStyle _hintTextStyle = TextStyle(color: Colors.black38);

  IconData _genderIconFor(String value) {
    switch (value) {
      case "Female":
        return Icons.female;
      case "Male":
        return Icons.male;
      case "Other":
        return Icons.transgender;
      default:
        return Icons.wc; // Icono universal de género (hombre-mujer)
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: _labelTextStyle,
      floatingLabelStyle: const TextStyle(color: Colors.deepOrange),
      hintStyle: _hintTextStyle,
      filled: true,
      fillColor: const Color(0xFFFFF9E8),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.orange),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.deepOrange, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.orange),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: AppSideMenu(
        currentLocation: MenuLocation.accountSettings,
        onPromocionesTap: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PromoCodesScreen()));
        },
      ),
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text("Edit profile", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameCtrl,
              style: _fieldTextStyle,
              decoration: _decoration("Full name"),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Requerido" : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nickNameCtrl,
              style: _fieldTextStyle,
              decoration: _decoration("Nick name"),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _labelCtrl,
              style: _fieldTextStyle,
              decoration: _decoration("Label"),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Requerido" : null,
            ),
            const SizedBox(height: 14),
            IntlPhoneField(
              initialCountryCode: _phoneIsoCode,
              initialValue: _phoneRawNumber,
              disableLengthCheck: true,
              style: _fieldTextStyle,
              dropdownTextStyle: _fieldTextStyle,
              decoration: _decoration("Phone number"),
              dropdownIconPosition: IconPosition.trailing,
              searchText: "Buscar país (nombre o código)...",
              onChanged: (PhoneNumber phone) {
                _phoneDialCode = phone.countryCode;
                _phoneRawNumber = phone.number;
              },
              onCountryChanged: (country) {
                _phoneIsoCode = country.code;
                _phoneDialCode = "+${country.dialCode}";
              },
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _country,
                    style: _fieldTextStyle,
                    decoration: _decoration("Country"),
                    items: _countries
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: _fieldTextStyle)))
                        .toList(),
                    onChanged: (v) => setState(() => _country = v ?? _country),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    style: _fieldTextStyle,
                    decoration: _decoration("Genre"),
                    hint: Text("Selecciona", style: _hintTextStyle),
                    items: ProfileController.genderOptions
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_genderIconFor(g), size: 18, color: Colors.black87),
                                  const SizedBox(width: 8),
                                  Text(g, style: _fieldTextStyle),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressCtrl,
              style: _fieldTextStyle,
              decoration: _decoration("Address"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("SUBMIT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}