import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:money_trace/core/settings/app_settings_controller.dart';
import 'package:money_trace/core/theme/app_colors.dart';
import 'package:money_trace/core/theme/app_theme_palette.dart';
import 'package:money_trace/features/auth/application/auth_controller.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/utils/grouped_amount_input_formatter.dart';

class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({
    super.key,
    required this.authController,
    required this.financeController,
    required this.settingsController,
  });

  final AuthController authController;
  final FinanceController financeController;
  final AppSettingsController settingsController;

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen> {
  late final TextEditingController _signInEmailController;
  late final TextEditingController _signInPasswordController;
  late final TextEditingController _signUpNameController;
  late final TextEditingController _signUpEmailController;
  late final TextEditingController _signUpPasswordController;
  late final TextEditingController _accountNameController;
  late final TextEditingController _openingBalanceController;

  bool _obscureSignInPassword = true;
  bool _obscureSignUpPassword = true;

  @override
  void initState() {
    super.initState();
    _signInEmailController = TextEditingController();
    _signInPasswordController = TextEditingController();
    _signUpNameController = TextEditingController();
    _signUpEmailController = TextEditingController();
    _signUpPasswordController = TextEditingController();
    _accountNameController = TextEditingController(
      text: widget.authController.starterAccountName,
    );
    _openingBalanceController = TextEditingController(
      text: widget.authController.starterBalance == 0
          ? '0.00'
          : widget.authController.starterBalance.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _accountNameController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.authController,
      builder: (context, child) {
        final stage = widget.authController.stage;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          body: Stack(
            children: [
              const _AuthBackdrop(),
              SafeArea(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(stage),
                    child: switch (stage) {
                      AuthStage.signIn => _buildSignIn(context),
                      AuthStage.signUp => _buildSignUp(context),
                      AuthStage.onboardingCurrency => _buildCurrencyStep(
                        context,
                      ),
                      AuthStage.onboardingAccount => _buildAccountStep(context),
                      AuthStage.onboardingComplete => _buildCompletionStep(
                        context,
                      ),
                      AuthStage.authenticated => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: _HelpButton(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Accounts are now stored locally on this device for repeat sign-in.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignIn(BuildContext context) {
    final controller = widget.authController;

    return _AuthEntryLayout(
      icon: Icons.verified_user_outlined,
      title: 'Welcome back to MoneyTrace',
      subtitle: 'Sign in to access your accounts, insights, and local data.',
      supportingChips: const [
        'Private by design',
        'Offline ready',
        'AI insights',
      ],
      errorMessage: controller.errorMessage,
      isSubmitting: controller.isSubmitting,
      fields: [
        _AuthField(
          controller: _signInEmailController,
          label: 'Email Address',
          hintText: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
          icon: Icons.mail_outline_rounded,
        ),
        _AuthField(
          controller: _signInPasswordController,
          label: 'Password',
          hintText: 'Enter your password',
          obscureText: _obscureSignInPassword,
          icon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscureSignInPassword = !_obscureSignInPassword;
              });
            },
            icon: Icon(
              _obscureSignInPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
      ],
      primaryLabel: 'Sign In',
      onPrimaryTap: () async {
        final success = await controller.signIn(
          email: _signInEmailController.text,
          password: _signInPasswordController.text,
        );
        final currentUserId = controller.currentUserId;
        if (!success || currentUserId == null) {
          return;
        }

        final loaded = await widget.financeController.loadForUser(currentUserId);
        await widget.settingsController.loadForUser(currentUserId);
        if (!loaded) {
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.financeController.errorMessage ??
                    'Unable to load your finance data.',
              ),
            ),
          );
        }
      },
      footer: _AuthFooter(
        prompt: "Don't have an account?",
        actionLabel: 'Create one',
        onTap: controller.showSignUp,
      ),
    );
  }

  Widget _buildSignUp(BuildContext context) {
    final controller = widget.authController;

    return _AuthEntryLayout(
      icon: Icons.shield_outlined,
      title: 'Join MoneyTrace',
      subtitle:
          'Create a local-first account and set up your workspace in a minute.',
      supportingChips: const [
        'Encrypted locally',
        'Quick onboarding',
        'Cross-platform',
      ],
      errorMessage: controller.errorMessage,
      isSubmitting: controller.isSubmitting,
      fields: [
        _AuthField(
          controller: _signUpNameController,
          label: 'Full Name',
          hintText: 'Your name',
          icon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
        ),
        _AuthField(
          controller: _signUpEmailController,
          label: 'Email Address',
          hintText: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
          icon: Icons.mail_outline_rounded,
        ),
        _AuthField(
          controller: _signUpPasswordController,
          label: 'Password',
          hintText: 'Create a password',
          obscureText: _obscureSignUpPassword,
          icon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscureSignUpPassword = !_obscureSignUpPassword;
              });
            },
            icon: Icon(
              _obscureSignUpPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
      ],
      primaryLabel: 'Create Account',
      onPrimaryTap: () async {
        final success = await controller.startRegistration(
          fullName: _signUpNameController.text,
          email: _signUpEmailController.text,
          password: _signUpPasswordController.text,
        );

        if (!success || !mounted) {
          return;
        }

        _accountNameController.text =
            '${controller.displayName.split(' ').first} Wallet';
        _openingBalanceController.text = '0.00';
      },
      footer: _AuthFooter(
        prompt: 'Already have an account?',
        actionLabel: 'Sign In',
        onTap: controller.showSignIn,
      ),
    );
  }

  Widget _buildCurrencyStep(BuildContext context) {
    final controller = widget.authController;
    const currencies = [
      _CurrencyOption(
        label: 'Kazakhstani Tenge',
        code: 'KZT',
        symbol: 'T',
        note: 'Best match for current demo data',
      ),
      _CurrencyOption(
        label: 'US Dollar',
        code: 'USD',
        symbol: r'$',
        note: 'A popular default for global budgeting',
      ),
      _CurrencyOption(
        label: 'Euro',
        code: 'EUR',
        symbol: 'EUR',
        note: 'Common for EU-based planning',
      ),
      _CurrencyOption(
        label: 'British Pound',
        code: 'GBP',
        symbol: 'GBP',
        note: 'Useful for UK-based finances',
      ),
    ];

    return _OnboardingLayout(
      stepIndex: 0,
      title: 'Welcome, ${controller.displayName.split(' ').first}!',
      subtitle: 'Choose the currency you want to start with.',
      body: Column(
        children: [
          for (var index = 0; index < currencies.length; index++) ...[
            _CurrencySelectionTile(
              option: currencies[index],
              selected:
                  controller.preferredCurrencyCode == currencies[index].code,
              onTap: () => controller.selectCurrency(currencies[index].code),
            ),
            if (index != currencies.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
      buttonLabel: 'Continue',
      isBusy: controller.isSubmitting,
      onPressed: () async {
        controller.goToAccountSetup();
      },
      onBackPressed: controller.goBack,
    );
  }

  Widget _buildAccountStep(BuildContext context) {
    final controller = widget.authController;

    return _OnboardingLayout(
      stepIndex: 1,
      title: 'Create your first account',
      subtitle: 'This can be your main card, wallet, or cash balance.',
      body: Column(
        children: [
          _AuthField(
            controller: _accountNameController,
            label: 'Account Name',
            hintText: 'Main Wallet',
            icon: Icons.account_balance_wallet_outlined,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          _AuthField(
            controller: _openingBalanceController,
            label: 'Initial Balance',
            hintText: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            icon: Icons.payments_outlined,
            prefixText: '${controller.preferredCurrencyCode} ',
            inputFormatters: const [GroupedAmountInputFormatter()],
          ),
          const SizedBox(height: 14),
          _SupportNotice(
            text:
                'We will use these values to personalize the app right after onboarding.',
          ),
        ],
      ),
      errorMessage: controller.errorMessage,
      buttonLabel: 'Continue',
      isBusy: controller.isSubmitting,
      onPressed: () async {
        final balance = GroupedAmountInputFormatter.parse(
          _openingBalanceController.text,
        );

        if (balance == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid balance.')),
          );
          return;
        }

        await controller.saveStarterAccount(
          accountName: _accountNameController.text,
          openingBalance: balance,
        );
      },
      onBackPressed: controller.goBack,
    );
  }

  Widget _buildCompletionStep(BuildContext context) {
    final controller = widget.authController;

    return _OnboardingLayout(
      stepIndex: 2,
      title: "You're all set!",
      subtitle: 'Your MoneyTrace workspace is ready to open.',
      alignBodyCenter: true,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: context.appPalette.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.check_rounded,
              size: 44,
              color: context.appPalette.primary,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            controller.displayName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _CompletionSummaryChip(
            label: controller.preferredCurrencyCode,
            icon: Icons.attach_money_rounded,
          ),
          const SizedBox(height: 10),
          _CompletionSummaryChip(
            label:
                '${controller.starterAccountName} · ${controller.starterBalance.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
      buttonLabel: "Let's Go",
      isBusy: controller.isSubmitting,
      onPressed: () async {
        final authCompleted = await controller.completeOnboarding();
        final currentUserId = controller.currentUserId;
        if (!authCompleted || currentUserId == null) {
          return;
        }

        final financeBootstrapped = await widget.financeController.bootstrapForUser(
          userId: currentUserId,
          accountName: controller.starterAccountName,
          openingBalance: controller.starterBalance,
          currencyCode: controller.preferredCurrencyCode,
        );
        await widget.settingsController.loadForUser(currentUserId);
        if (!financeBootstrapped) {
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.financeController.errorMessage ??
                    'Unable to create your finance workspace.',
              ),
            ),
          );
        }
      },
      onBackPressed: controller.goBack,
    );
  }
}

class _AuthEntryLayout extends StatelessWidget {
  const _AuthEntryLayout({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.supportingChips,
    required this.fields,
    required this.primaryLabel,
    required this.onPrimaryTap,
    required this.footer,
    this.errorMessage,
    this.isSubmitting = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> supportingChips;
  final List<Widget> fields;
  final String primaryLabel;
  final Future<void> Function() onPrimaryTap;
  final Widget footer;
  final String? errorMessage;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 46),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: context.appPalette.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      color: context.appPalette.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    title,
                    style: textTheme.headlineLarge?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF65758E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final chip in supportingChips)
                        _SupportChip(label: chip),
                    ],
                  ),
                  const SizedBox(height: 28),
                  for (var index = 0; index < fields.length; index++) ...[
                    fields[index],
                    if (index != fields.length - 1) const SizedBox(height: 16),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _ErrorBanner(message: errorMessage!),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : onPrimaryTap,
                      child: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(primaryLabel),
                                const SizedBox(width: 10),
                                const Icon(Icons.arrow_forward_rounded),
                              ],
                            ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 28),
                  Center(child: footer),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingLayout extends StatelessWidget {
  const _OnboardingLayout({
    required this.stepIndex,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
    required this.onBackPressed,
    this.errorMessage,
    this.isBusy = false,
    this.alignBodyCenter = false,
  });

  final int stepIndex;
  final String title;
  final String subtitle;
  final Widget body;
  final String buttonLabel;
  final Future<void> Function() onPressed;
  final VoidCallback onBackPressed;
  final String? errorMessage;
  final bool isBusy;
  final bool alignBodyCenter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.vertical -
                    152,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onBackPressed,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.82),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _ProgressBar(stepIndex: stepIndex)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF65758E),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (alignBodyCenter) ...[
                    const SizedBox(height: 92),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: body,
                      ),
                    ),
                  ] else
                    body,
                  if (errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _ErrorBanner(message: errorMessage!),
                  ],
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            border: Border(
              top: BorderSide(color: AppColors.outline.withValues(alpha: 0.6)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isBusy ? null : onPressed,
                child: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(buttonLabel),
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixText,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? prefixText;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF5A6A84),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            prefixIcon: Icon(icon, color: const Color(0xFF6E7E97)),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Row(
      children: [
        for (var index = 0; index < 3; index++) ...[
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: index <= stepIndex
                    ? palette.primary
                    : const Color(0xFFE2E8F1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (index != 2) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _CurrencySelectionTile extends StatelessWidget {
  const _CurrencySelectionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _CurrencyOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? palette.primary.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? palette.primary : const Color(0xFFDCE3EB),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B132033),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  option.symbol,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${option.code} · ${option.note}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_outline_rounded
                    : Icons.circle_outlined,
                color: selected ? palette.primary : const Color(0xFF9AA8BC),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthFooter extends StatelessWidget {
  const _AuthFooter({
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: Theme.of(context).textTheme.bodyMedium),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }
}

class _SupportChip extends StatelessWidget {
  const _SupportChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE0E7F0)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF68788F),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SupportNotice extends StatelessWidget {
  const _SupportNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE5EF)),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF66758E)),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.expense.withValues(alpha: 0.18)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.expense,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CompletionSummaryChip extends StatelessWidget {
  const _CompletionSummaryChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE5EF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: context.appPalette.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  const _HelpButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFF23262B),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.question_mark_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FBFD), Color(0xFFF3F7FB)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -86,
            bottom: 94,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primaryLight.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            top: 110,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    palette.primary.withValues(alpha: 0),
                    palette.primary.withValues(alpha: 0.14),
                    palette.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyOption {
  const _CurrencyOption({
    required this.label,
    required this.code,
    required this.symbol,
    required this.note,
  });

  final String label;
  final String code;
  final String symbol;
  final String note;
}
