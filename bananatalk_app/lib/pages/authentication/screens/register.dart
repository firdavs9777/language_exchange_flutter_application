import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:bananatalk_app/pages/authentication/screens/register_second.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class Register extends StatefulWidget {
  final String userName;
  final String userEmail; // This is now pre-verified
  final String userPassword;

  const Register({
    super.key,
    this.userName = '',
    required this.userEmail,
    this.userPassword = '',
  });

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _obscureText = true;
  bool _obscureTextTwo = true;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _passwordConfirmController;
  late TextEditingController _birthDateController;

  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final Map<String, IconData> _genderIcons = {
    'Male': Icons.male_rounded,
    'Female': Icons.female_rounded,
    'Other': Icons.transgender_rounded,
  };

  String _localizedGender(String gender) {
    final l10n = AppLocalizations.of(context)!;
    switch (gender) {
      case 'Male':
        return l10n.male;
      case 'Female':
        return l10n.female;
      case 'Other':
        return l10n.otherGender;
      default:
        return gender;
    }
  }

  // Error states
  String? _nameError;
  String? _passwordError;
  String? _genderError;
  String? _birthDateError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _passwordController = TextEditingController(text: widget.userPassword);
    _emailController = TextEditingController(text: widget.userEmail);
    _passwordConfirmController =
        TextEditingController(text: widget.userPassword);
    _birthDateController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool isValid = true;
    setState(() {
      _nameError = null;
      _passwordError = null;
      _genderError = null;
      _birthDateError = null;
    });

    final l10n = AppLocalizations.of(context)!;

    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = l10n.pleaseEnterYourName);
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = l10n.pleaseEnterAPassword);
      isValid = false;
    } else {
      final passwordValidation =
          AuthService.validatePassword(_passwordController.text);
      if (!passwordValidation['valid']) {
        setState(() => _passwordError = passwordValidation['message']);
        isValid = false;
      } else if (_passwordController.text != _passwordConfirmController.text) {
        setState(() => _passwordError = l10n.passwordsDoNotMatch);
        isValid = false;
      }
    }

    if (_selectedGender == null) {
      setState(() => _genderError = l10n.pleaseSelectGender);
      isValid = false;
    }

    if (_birthDateController.text.isEmpty) {
      setState(() => _birthDateError = l10n.pleaseSelectBirthDate);
      isValid = false;
    } else {
      try {
        final parts = _birthDateController.text.split('.');
        final birthDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final age = DateTime.now().difference(birthDate).inDays ~/ 365;
        if (age < 18) {
          setState(() => _birthDateError = l10n.mustBe18);
          isValid = false;
        }
      } catch (e) {
        setState(() => _birthDateError = l10n.invalidDate);
        isValid = false;
      }
    }

    return isValid;
  }

  void submit() {
    if (!_validate()) return;

    final genderMap = {'Male': 'male', 'Female': 'female', 'Other': 'other'};

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => RegisterTwo(
          name: _nameController.text.trim(),
          email: widget.userEmail,
          password: _passwordController.text,
          gender: genderMap[_selectedGender] ?? 'other',
          birthDate: _birthDateController.text,
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    DateTime initialDate =
        DateTime.now().subtract(const Duration(days: 365 * 20));

    if (_birthDateController.text.isNotEmpty) {
      try {
        initialDate =
            DateFormat('yyyy.MM.dd').parse(_birthDateController.text);
      } catch (e) {
        // use default
      }
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _birthDateController.text =
            DateFormat('yyyy.MM.dd').format(pickedDate);
        _birthDateError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.scaffoldBackground,
        body: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios,
                          color: context.textPrimary, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(
                      AppLocalizations.of(context)!.stepOneOfTwo,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacing.hGapLG,
                  ],
                ),
              ),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Spacing.hGapSM,
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Header
                      Text(
                        AppLocalizations.of(context)!.createYourAccount,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(context)!.basicInfoToGetStarted,
                        style: TextStyle(
                          fontSize: 15,
                          color: context.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Email (read-only, verified)
                      _buildLabel(AppLocalizations.of(context)!.emailVerifiedLabel),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.containerColor,
                          borderRadius: AppRadius.borderLG,
                          border: Border.all(color: context.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.email_outlined,
                                color: context.textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.userEmail,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: context.textSecondary,
                                ),
                              ),
                            ),
                            Icon(Icons.verified,
                                color: AppColors.success, size: 20),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Name
                      _buildLabel(AppLocalizations.of(context)!.nameLabel),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameController,
                        hint: AppLocalizations.of(context)!.yourDisplayName,
                        icon: Icons.person_outline,
                        error: _nameError,
                        onChanged: (_) =>
                            setState(() => _nameError = null),
                      ),

                      const SizedBox(height: 20),

                      // Password
                      _buildLabel(AppLocalizations.of(context)!.password),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _passwordController,
                        hint: AppLocalizations.of(context)!.atLeast8Characters,
                        icon: Icons.lock_outline,
                        obscure: _obscureText,
                        error: _passwordError,
                        onChanged: (_) =>
                            setState(() => _passwordError = null),
                        suffix: GestureDetector(
                          onTap: () =>
                              setState(() => _obscureText = !_obscureText),
                          child: Icon(
                            _obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: context.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _passwordConfirmController,
                        hint: AppLocalizations.of(context)!.confirmPasswordHint,
                        icon: Icons.lock_outline,
                        obscure: _obscureTextTwo,
                        suffix: GestureDetector(
                          onTap: () => setState(
                              () => _obscureTextTwo = !_obscureTextTwo),
                          child: Icon(
                            _obscureTextTwo
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: context.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Gender
                      _buildLabel(AppLocalizations.of(context)!.gender),
                      if (_genderError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_genderError!,
                              style: TextStyle(
                                  color: AppColors.error, fontSize: 12)),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: _genders
                            .map((g) => _buildGenderChip(g))
                            .toList(),
                      ),

                      const SizedBox(height: 24),

                      // Birth date
                      _buildLabel(AppLocalizations.of(context)!.birthDate),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickBirthDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.cardBackground,
                            borderRadius: AppRadius.borderLG,
                            border: Border.all(
                              color: _birthDateError != null
                                  ? AppColors.error
                                  : context.dividerColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cake_outlined,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _birthDateController.text.isNotEmpty
                                      ? _formatDisplayDate(
                                          _birthDateController.text)
                                      : AppLocalizations.of(context)!.selectYourBirthDate,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        _birthDateController.text.isNotEmpty
                                            ? context.textPrimary
                                            : context.textHint,
                                  ),
                                ),
                              ),
                              Icon(Icons.calendar_today_outlined,
                                  size: 18, color: context.iconColor),
                            ],
                          ),
                        ),
                      ),
                      if (_birthDateError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 6),
                          child: Text(_birthDateError!,
                              style: TextStyle(
                                  color: AppColors.error, fontSize: 12)),
                        ),

                      const SizedBox(height: 32),

                      // Next button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.borderLG,
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.nextButton,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!
                                .alreadyHaveAnAccount,
                            style: TextStyle(color: context.textSecondary),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (ctx) => Login()),
                              );
                            },
                            child: Text(
                              AppLocalizations.of(context)!.login2,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: context.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    String? error,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: AppRadius.borderLG,
            border: Border.all(
              color: error != null ? AppColors.error : context.dividerColor,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: context.textHint, fontSize: 15),
              prefixIcon: Icon(icon, color: context.textSecondary, size: 20),
              suffixIcon: suffix != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: suffix)
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(error,
                style: TextStyle(color: AppColors.error, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildGenderChip(String gender) {
    final isSelected = _selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedGender = gender;
            _genderError = null;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : context.containerColor,
            borderRadius: AppRadius.borderMD,
            border: Border.all(
              color: isSelected ? AppColors.primary : context.dividerColor,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _genderIcons[gender] ?? Icons.person,
                color: isSelected ? Colors.white : context.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                _localizedGender(gender),
                style: TextStyle(
                  color: isSelected ? Colors.white : context.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDisplayDate(String date) {
    try {
      final parsed = DateFormat('yyyy.MM.dd').parse(date);
      return DateFormat('MMMM d, yyyy').format(parsed);
    } catch (e) {
      return date;
    }
  }
}
