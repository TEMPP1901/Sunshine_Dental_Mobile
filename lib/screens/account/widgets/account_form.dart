import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'account_text_field.dart';

class AccountForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final String username;
  final bool hasPassword;
  final bool isLoading;
  final VoidCallback onSave;

  const AccountForm({
    super.key,
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.username,
    required this.hasPassword,
    required this.isLoading,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'account.myAccount.title'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              AccountTextField(
                controller: fullNameController,
                label: 'account.myAccount.fullName'.tr(),
                icon: Icons.badge_outlined,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'account.myAccount.validation.fullName'.tr()
                    : null,
              ),
              const SizedBox(height: 16),

              // Email
              AccountTextField(
                controller: emailController,
                label: 'account.myAccount.email'.tr(),
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'account.myAccount.validation.email'.tr();
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                    return 'account.myAccount.validation.emailFormat'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              AccountTextField(
                controller: phoneController,
                label: 'account.myAccount.phone'.tr(),
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Username (Read-only)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${'account.myAccount.username'.tr()}: $username',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: isLoading ? null : onSave,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('account.myAccount.saveChanges'.tr()),
                    ),
                  ),
                  if (hasPassword) ...[
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/change-password'),
                      icon: const Icon(Icons.lock_reset_rounded),
                      label: Text('account.changePassword.title'.tr()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: colorScheme.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
