import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../demo/demo_mode.dart';
import '../utils/haptics.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  late String _photoUrl;
  bool _uploadingPhoto = false;
  bool _saving = false;
  bool _savingEmail = false;
  String _phoneCountry = 'PT';
  String? _phoneE164;
  bool _phoneSeeded = false;
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    _nameCtrl.text = user?.name ?? '';
    _emailCtrl.text = user?.email ?? '';
    _photoUrl = user?.photoUrl ?? '';

    _seedPhone(user?.phone);
    if (!_phoneSeeded) {
      _authProvider = auth;
      auth.addListener(_handleAuthChanged);
    }
  }

  void _handleAuthChanged() {
    if (_phoneSeeded) return;
    final phone = _authProvider?.user?.phone;
    if (phone != null && phone.trim().isNotEmpty) {
      setState(() => _seedPhone(phone));
    }
  }

  void _seedPhone(String? phone) {
    final p = (phone ?? '').trim();
    if (p.isEmpty) return;
    final parsed = _parsePhone(p);
    _phoneCountry = parsed.countryCode;
    _phoneCtrl.text = parsed.national;
    _phoneE164 = p;
    _phoneSeeded = true;
  }

  ({String countryCode, String national}) _parsePhone(String full) {
    if (!full.startsWith('+')) {
      return (countryCode: 'PT', national: full);
    }
    final digits = full.substring(1).replaceAll(RegExp(r'\s+'), '');
    for (final len in [4, 3, 2, 1]) {
      if (digits.length <= len) continue;
      final dial = digits.substring(0, len);
      Country? match;
      for (final c in countries) {
        if (c.dialCode == dial) {
          match = c;
          break;
        }
      }
      if (match != null) {
        return (countryCode: match.code, national: digits.substring(len));
      }
    }
    return (countryCode: 'PT', national: full);
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_handleAuthChanged);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final l10n = context.l10n;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.accountSettingsTakePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.accountSettingsChooseFromLibrary),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final uid = context.read<AuthProvider>().user?.id;
    if (uid == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      final ref = FirebaseStorage.instanceFor(
              bucket: 'gs://kofapp-ac2f6.firebasestorage.app')
          .ref()
          .child('profile_photos')
          .child(uid)
          .child('profile.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      if (!mounted) return;
      await context.read<AuthProvider>().updateProfile(photoUrl: url);
      if (!mounted) return;
      setState(() => _photoUrl = url);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountSettingsPhotoUploadFailed)),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _saveProfile() async {
    Haptics.light();
    final auth = context.read<AuthProvider>();
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await auth.updateProfile(name: _nameCtrl.text.trim());
      final phoneToSave =
          _phoneCtrl.text.trim().isEmpty ? '' : (_phoneE164 ?? '');
      await auth.updatePhone(phoneToSave);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountSettingsSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountSettingsSaveFailed)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeEmail() async {
    final auth = context.read<AuthProvider>();
    final l10n = context.l10n;
    final newEmail = _emailCtrl.text.trim();
    if (newEmail == auth.user?.email) return;

    String? currentPassword;
    if (auth.isPasswordUser) {
      currentPassword = await _askForPassword(l10n);
      if (currentPassword == null) return;
    }

    setState(() => _savingEmail = true);
    try {
      await auth.updateEmail(newEmail, currentPassword: currentPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountSettingsEmailChanged)),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.code == AuthErrorCode.requiresRecentLogin
          ? l10n.accountSettingsEmailReauthBody
          : l10n.accountSettingsSaveFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountSettingsSaveFailed)),
      );
    } finally {
      if (mounted) setState(() => _savingEmail = false);
    }
  }

  Future<String?> _askForPassword(AppLocalizations l10n) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountSettingsEmailReauthTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.accountSettingsEmailReauthBody,
                style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.accountSettingsCurrentPassword,
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(l10n.accountSettingsSave),
          ),
        ],
      ),
    );
    return (result?.isEmpty ?? true) ? null : result;
  }

  Future<void> _sendPasswordReset() async {
    final l10n = context.l10n;
    final email = context.read<AuthProvider>().user?.email ?? '';
    if (email.isEmpty) return;
    try {
      await AuthService().sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountSettingsChangePasswordSent)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountSettingsSaveFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isPasswordUser = auth.isPasswordUser;

    final initial = (user?.name.isNotEmpty ?? false)
        ? user!.name[0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          // ── Avatar ───────────────────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: (_uploadingPhoto || kDemoMode) ? null : () {
                Haptics.selection();
                _pickPhoto();
              },
              child: _buildAvatar(theme, initial),
            ),
          ),
          const SizedBox(height: 32),

          // ── Profile section ──────────────────────────────────────────
          _SectionHeader(label: l10n.accountSettingsSectionProfile),
          const SizedBox(height: 16),
          _field(
            controller: _nameCtrl,
            label: l10n.accountSettingsName,
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            readOnly: kDemoMode,
          ),
          const SizedBox(height: 14),
          IgnorePointer(
            ignoring: kDemoMode,
            child: _phoneField(theme, l10n.accountSettingsPhone),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_saving || kDemoMode) ? null : _saveProfile,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.accountSettingsSave),
            ),
          ),

          const SizedBox(height: 32),

          // ── Account section ──────────────────────────────────────────
          _SectionHeader(label: l10n.accountSettingsSectionAccount),
          const SizedBox(height: 16),

          if (isPasswordUser) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _field(
                    controller: _emailCtrl,
                    label: l10n.accountSettingsEmail,
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: kDemoMode,
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonal(
                  onPressed: (_savingEmail || kDemoMode) ? null : _changeEmail,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(72, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _savingEmail
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.accountSettingsSave,
                          style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _PasswordTile(
              subtitle: l10n.accountSettingsChangePasswordSubtitle,
              label: l10n.accountSettingsChangePassword,
              onTap: kDemoMode ? null : _sendPasswordReset,
            ),
          ] else ...[
            _field(
              controller: _emailCtrl,
              label: l10n.accountSettingsEmail,
              icon: Icons.mail_outline,
              readOnly: true,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.accountSettingsEmailGoogle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, String initial) {
    const radius = 44.0;
    const size = radius * 2;
    final bg = theme.colorScheme.primary.withValues(alpha: 0.15);
    final fg = theme.colorScheme.primary;

    final fallback = Text(
      initial,
      style: TextStyle(
          fontSize: radius * 0.75, fontWeight: FontWeight.w700, color: fg),
    );

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: _photoUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                _photoUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(child: fallback),
              ),
            )
          : fallback,
    );

    return Stack(
      children: [
        avatar,
        if (_uploadingPhoto)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              border:
                  Border.all(color: theme.colorScheme.surface, width: 2),
            ),
            child: const Icon(Icons.camera_alt, size: 13, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _phoneField(ThemeData theme, String label) {
    return IntlPhoneField(
      key: ValueKey('phone-$_phoneCountry-$_phoneSeeded'),
      controller: _phoneCtrl,
      initialCountryCode: _phoneCountry,
      disableLengthCheck: true,
      showCountryFlag: true,
      dropdownIconPosition: IconPosition.trailing,
      flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 8),
      onChanged: (PhoneNumber phone) {
        setState(() {
          _phoneCountry = phone.countryISOCode;
          _phoneE164 = phone.completeNumber;
        });
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
      ),
    );
  }
}

class _PasswordTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  const _PasswordTile({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                Haptics.selection();
                onTap!();
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.lock_outline,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
