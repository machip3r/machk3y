import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/vault_provider.dart';
import '../../models/credential.dart';
import '../../core/services/password_service.dart';

class AddCredentialScreen extends StatefulWidget {
  const AddCredentialScreen({super.key});

  @override
  State<AddCredentialScreen> createState() => _AddCredentialScreenState();
}

class _AddCredentialScreenState extends State<AddCredentialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagInputController = TextEditingController();
  // Card-specific controllers
  final _cardNumberController = TextEditingController();
  final _clabeController = TextEditingController();
  final _cvvController = TextEditingController();
  final _pinController = TextEditingController();
  final _expiryController = TextEditingController();

  CredentialType _selectedType = CredentialType.website;
  PasswordAnalysis _passwordAnalysis = PasswordAnalysis(
    strength: PasswordStrength.weak,
    score: 0,
  );
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _showTypeSelection = true;
  bool _highlightSelectionInPicker = false;

  // Email suggestion state
  bool _showEmailSuggestions = false;
  List<String> _emailSuggestions = [];
  final List<String> _commonDomains = const [
    'gmail.com',
    'yahoo.com',
    'hotmail.com',
    'outlook.com',
    'yahoo.com.mx',
    'live.com',
    'live.com.mx',
    'icloud.com',
  ];

  // Tags state
  final List<String> _defaultTags = const [
    'job',
    'mail',
    'personal',
    'storage',
    'social',
    'important',
    'media',
    'payment',
    'shop',
    'crypto',
    'school',
    'other',
  ];
  List<String> _availableTags = [];
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
    _emailController.addListener(_onEmailChanged);
    _emailController.addListener(_enforceEmailLowercase);

    // Initialize available tags from defaults and provider
    final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
    final Set<String> merged = {..._defaultTags, ...vaultProvider.tags};
    _availableTags = merged.toList()..sort();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    _tagInputController.dispose();
    _cardNumberController.dispose();
    _clabeController.dispose();
    _cvvController.dispose();
    _pinController.dispose();
    _expiryController.dispose();
    _passwordController.removeListener(_checkPasswordStrength);
    _emailController.removeListener(_onEmailChanged);
    _emailController.removeListener(_enforceEmailLowercase);
    super.dispose();
  }

  void _checkPasswordStrength() {
    setState(() {
      _passwordAnalysis = PasswordService().analyzePasswordStrength(
        _passwordController.text,
      );
    });
  }

  Color _getStrengthColor() {
    switch (_passwordAnalysis.strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  String _getStrengthText() {
    return _passwordAnalysis.strengthText;
  }

  IconData _iconForType(CredentialType type) {
    switch (type) {
      case CredentialType.website:
        return Icons.language;
      case CredentialType.email:
        return Icons.alternate_email;
      case CredentialType.card:
        return Icons.credit_card;
      case CredentialType.social:
        return Icons.people_alt;
      case CredentialType.other:
        return Icons.apps;
    }
  }

  String _labelForType(CredentialType type) {
    final s = type.toString().split('.').last;
    return s[0].toUpperCase() + s.substring(1);
  }

  // Formats card number as groups of 4 digits with hyphens, limits to 16 digits
  // and maintains the caret position as best as possible.
  static final TextInputFormatter _cardNumberFormatter = _CardNumberFormatter();
  static final TextInputFormatter _expiryDateFormatter = _ExpiryDateFormatter();
  // Removed live edge trimming for better typing UX; trimming now happens on submit

  Widget _buildTypeSelectionFullHeight() {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: CredentialType.values
                              .where((t) => t != CredentialType.other)
                              .map((type) {
                                final bool isSelected =
                                    _highlightSelectionInPicker &&
                                    _selectedType == type;
                                IconData _iconForType(CredentialType t) {
                                  switch (t) {
                                    case CredentialType.website:
                                      return Icons.language;
                                    case CredentialType.email:
                                      return Icons.alternate_email;
                                    case CredentialType.card:
                                      return Icons.credit_card;
                                    case CredentialType.social:
                                      return Icons.people_alt;
                                    case CredentialType.other:
                                      return Icons.apps;
                                  }
                                }

                                String _labelForType(CredentialType t) {
                                  final s = t.toString().split('.').last;
                                  return s[0].toUpperCase() + s.substring(1);
                                }

                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    setState(() {
                                      _selectedType = type;
                                      _showTypeSelection = false;
                                      _highlightSelectionInPicker = true;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primaryContainer
                                            : theme.colorScheme.outline,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      color: isSelected
                                          ? theme.colorScheme.primaryContainer
                                          : theme.colorScheme.surface,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _iconForType(type),
                                          size: 28,
                                          color: isSelected
                                              ? theme
                                                    .colorScheme
                                                    .onPrimaryContainer
                                              : theme.colorScheme.onSurface,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _labelForType(type),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? theme
                                                      .colorScheme
                                                      .onPrimaryContainer
                                                : theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final type = CredentialType.other;
                            final bool isSelected =
                                _highlightSelectionInPicker &&
                                _selectedType == type;
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                setState(() {
                                  _selectedType = type;
                                  _showTypeSelection = false;
                                  _highlightSelectionInPicker = true;
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primaryContainer
                                        : theme.colorScheme.outline,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  color: isSelected
                                      ? theme.colorScheme.primaryContainer
                                      : theme.colorScheme.surface,
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      _iconForType(type),
                                      size: 28,
                                      color: isSelected
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _labelForType(type),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? theme
                                                  .colorScheme
                                                  .onPrimaryContainer
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedTypeSummary() {
    final theme = Theme.of(context);
    IconData _iconForType(CredentialType type) {
      switch (type) {
        case CredentialType.website:
          return Icons.language;
        case CredentialType.email:
          return Icons.alternate_email;
        case CredentialType.card:
          return Icons.credit_card;
        case CredentialType.social:
          return Icons.people_alt;
        case CredentialType.other:
          return Icons.apps;
      }
    }

    String _labelForType(CredentialType type) {
      final s = type.toString().split('.').last;
      return s[0].toUpperCase() + s.substring(1);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _showTypeSelection = true;
          _highlightSelectionInPicker = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                _iconForType(_selectedType),
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _labelForType(_selectedType),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  foregroundColor: theme.colorScheme.secondary,
                ),
                onPressed: () {
                  setState(() {
                    _showTypeSelection = true;
                    _highlightSelectionInPicker = false;
                  });
                },
                child: const Text('Change'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onEmailChanged() {
    final text = _emailController.text;
    final atIndex = text.lastIndexOf('@');

    if (atIndex != -1) {
      final domainPart = text.substring(atIndex + 1);
      if (domainPart.isNotEmpty) {
        _emailSuggestions = _commonDomains
            .where(
              (domain) =>
                  domain.toLowerCase().startsWith(domainPart.toLowerCase()),
            )
            .toList();
        setState(() {
          _showEmailSuggestions = _emailSuggestions.isNotEmpty;
        });
      } else {
        setState(() {
          _showEmailSuggestions = true;
          _emailSuggestions = _commonDomains;
        });
      }
    } else {
      setState(() {
        _showEmailSuggestions = false;
      });
    }
  }

  void _selectEmailSuggestion(String domain) {
    final text = _emailController.text;
    final atIndex = text.lastIndexOf('@');
    if (atIndex != -1) {
      final username = text.substring(0, atIndex);
      _emailController.text = '$username@$domain';
      _emailController.selection = TextSelection.fromPosition(
        TextPosition(offset: _emailController.text.length),
      );
    }
    setState(() {
      _showEmailSuggestions = false;
    });
  }

  void _enforceEmailLowercase() {
    final text = _emailController.text;
    final lower = text.toLowerCase();
    if (text != lower) {
      final baseOffset = _emailController.selection.baseOffset;
      final extentOffset = _emailController.selection.extentOffset;
      _emailController.value = TextEditingValue(
        text: lower,
        selection: TextSelection(
          baseOffset: baseOffset,
          extentOffset: extentOffset,
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    // Normalize/trim inputs before validating and saving
    _titleController.text = _titleController.text.trim();
    _usernameController.text = _usernameController.text.trim();
    _emailController.text = _emailController.text.trim();
    _urlController.text = _urlController.text.trim();
    _notesController.text = _notesController.text.trim();
    _cardNumberController.text = _cardNumberController.text.trim();
    _clabeController.text = _clabeController.text.trim();
    _cvvController.text = _cvvController.text.trim();
    _pinController.text = _pinController.text.trim();
    _expiryController.text = _expiryController.text.trim();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final vaultProvider = Provider.of<VaultProvider>(context, listen: false);

    // Build the credential data based on type
    final Map<String, dynamic> data = {};

    switch (_selectedType) {
      case CredentialType.website:
        data['url'] = _urlController.text;
        data['username'] = _usernameController.text;
        data['password'] = _passwordController.text;
        break;
      case CredentialType.email:
        data['email'] = _emailController.text;
        data['password'] = _passwordController.text;
        break;
      case CredentialType.social:
        data['platform'] = _titleController.text;
        data['username'] = _usernameController.text;
        data['password'] = _passwordController.text;
        break;
      case CredentialType.card:
        data['bank'] = _titleController.text;
        data['cardholder'] = _usernameController.text;
        data['card_number'] = _cardNumberController.text;
        data['expiry'] = _expiryController.text;
        data['cvv'] = _cvvController.text;
        data['pin'] = _pinController.text;
        data['clabe'] = _clabeController.text;
        data['password'] = _passwordController.text;
        break;
      case CredentialType.other:
        data['title'] = _titleController.text;
        data['username'] = _usernameController.text;
        data['password'] = _passwordController.text;
        break;
    }

    if (_notesController.text.isNotEmpty) {
      data['notes'] = _notesController.text;
    }

    final credential = Credential(
      userId: '', // Will be set by the vault provider
      type: _selectedType,
      title: _titleController.text.isEmpty
          ? _getDefaultTitle()
          : _titleController.text,
      data: data,
      tags: _selectedTags,
    );

    final created = await vaultProvider.createCredential(credential);

    if (!mounted) return;

    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credential added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Return true to indicate success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vaultProvider.error ?? 'Failed to add credential'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _getDefaultTitle() {
    switch (_selectedType) {
      case CredentialType.website:
        return _urlController.text;
      case CredentialType.email:
        return _emailController.text;
      case CredentialType.social:
        return 'Social Media Account';
      case CredentialType.card:
        return 'Credit Card';
      case CredentialType.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Credential')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) => SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: _showTypeSelection
            ? Container(
                key: const ValueKey('pickerView'),
                child: _buildTypeSelectionFullHeight(),
              )
            : SingleChildScrollView(
                key: const ValueKey('formView'),
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Selected type summary with Change action
                      _buildSelectedTypeSummary(),

                      const SizedBox(height: 16),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                          hintText:
                              'Credential title, bank name, platform name, etc.',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp('[a-zA-Z0-9 ]'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Fields based on type
                      ..._buildFieldsForType(),

                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        // Optional: no validator required
                      ),

                      if (_passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              size: 16,
                              color: _getStrengthColor(),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getStrengthText(),
                              style: TextStyle(
                                color: _getStrengthColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Notes Field
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tags (moved after notes)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tags',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _availableTags.map((tag) {
                              final selected = _selectedTags.contains(tag);
                              return FilterChip(
                                label: Text(tag),
                                selected: selected,
                                onSelected: (value) {
                                  setState(() {
                                    if (value) {
                                      if (!_selectedTags.contains(tag)) {
                                        _selectedTags.add(tag);
                                      }
                                    } else {
                                      _selectedTags.remove(tag);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _tagInputController,
                                  decoration: const InputDecoration(
                                    labelText: 'Add tag',
                                    border: OutlineInputBorder(),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp('[a-z0-9]'),
                                    ),
                                  ],
                                  onSubmitted: (value) {
                                    final tag = value.trim().toLowerCase();
                                    if (tag.isEmpty) return;
                                    setState(() {
                                      if (!_availableTags.contains(tag)) {
                                        _availableTags.add(tag);
                                        _availableTags.sort();
                                      }
                                      if (!_selectedTags.contains(tag)) {
                                        _selectedTags.add(tag);
                                      }
                                      _tagInputController.clear();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 56,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    minimumSize: const Size(56, 56),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    final tag = _tagInputController.text
                                        .trim()
                                        .toLowerCase();
                                    if (tag.isEmpty) return;
                                    setState(() {
                                      if (!_availableTags.contains(tag)) {
                                        _availableTags.add(tag);
                                        _availableTags.sort();
                                      }
                                      if (!_selectedTags.contains(tag)) {
                                        _selectedTags.add(tag);
                                      }
                                      _tagInputController.clear();
                                    });
                                  },
                                  child: const Center(
                                    child: Icon(Icons.add, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add Credential',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Zalando',
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // Bottom margin
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  List<Widget> _buildFieldsForType() {
    switch (_selectedType) {
      case CredentialType.website:
        return [
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Website URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-Z0-9:/._#?&=%-]'),
              ),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a URL';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a username';
              }
              return null;
            },
          ),
        ];

      case CredentialType.email:
        return [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-z0-9@.]')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          if (_showEmailSuggestions) ...[
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: _emailSuggestions.take(5).map((domain) {
                  final text = _emailController.text;
                  final atIndex = text.lastIndexOf('@');
                  final username = atIndex != -1
                      ? text.substring(0, atIndex)
                      : '';
                  final fullEmail = '$username@$domain';

                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.email,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    title: Text(
                      fullEmail,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Zalando',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    onTap: () => _selectEmailSuggestion(domain),
                  );
                }).toList(),
              ),
            ),
          ],
        ];

      case CredentialType.social:
        return [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a username';
              }
              return null;
            },
          ),
        ];

      case CredentialType.card:
        return [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Cardholder Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z -]')),
            ],
            // Optional
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.credit_card),
              hintText: '•••• •••• •••• ••••',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _cardNumberFormatter,
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return null; // Optional
              }
              final digits = value.replaceAll(RegExp('[^0-9]'), '');
              if (digits.length != 16) {
                return 'Card number must be 16 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _clabeController,
            decoration: const InputDecoration(
              labelText: 'CLABE',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance),
              hintText: '18 digits',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(18),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: const InputDecoration(
                    labelText: 'Expiration (MM/YYYY)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event),
                    hintText: 'MM/YYYY',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _expiryDateFormatter,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null; // Optional
                    }
                    if (!RegExp(
                      r'^(0[1-9]|1[0-2])\/(\d{2}|\d{4})$',
                    ).hasMatch(value)) {
                      return 'Use MM/YY or MM/YYYY';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null; // Optional
                    }
                    if (value.length < 3) {
                      return 'CVV too short';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pinController,
            decoration: const InputDecoration(
              labelText: 'PIN',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key),
            ),
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
        ];

      case CredentialType.other:
        return [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username / Identifier',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
        ];
    }
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only keep digits and cap at 16
    final raw = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    final trimmed = raw.length > 16 ? raw.substring(0, 16) : raw;

    // Build formatted with hyphens after every 4 digits, except at the end
    final buffer = StringBuffer();
    for (int i = 0; i < trimmed.length; i++) {
      buffer.write(trimmed[i]);
      if ((i + 1) % 4 == 0 && i + 1 != trimmed.length) {
        buffer.write('-');
      }
    }
    final formatted = buffer.toString();

    // Caret position mapping: count digits before original cursor
    final selectionDigits = _countDigits(
      newValue.text.substring(0, newValue.selection.baseOffset),
    );
    int caret = 0;
    int digitsSeen = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp('[0-9]').hasMatch(formatted[i])) {
        digitsSeen++;
      }
      if (digitsSeen >= selectionDigits) {
        caret = i + 1;
        break;
      }
      // If cursor was at end of text
      if (i == formatted.length - 1) {
        caret = formatted.length;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: caret.clamp(0, formatted.length),
      ),
    );
  }

  int _countDigits(String s) {
    int c = 0;
    for (final ch in s.runes) {
      if (ch >= 48 && ch <= 57) c++;
    }
    return c;
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Keep digits only, cap total digits to 6 (MM + YYYY)
    final raw = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    final trimmed = raw.length > 6 ? raw.substring(0, 6) : raw;

    final buffer = StringBuffer();
    for (int i = 0; i < trimmed.length; i++) {
      buffer.write(trimmed[i]);
      if (i == 1 && trimmed.length > 2) {
        buffer.write('/');
      }
    }

    // If user just typed month (2 digits) add trailing slash: "04/"
    String formatted;
    if (trimmed.length == 2 && oldValue.text.length < newValue.text.length) {
      formatted = '${trimmed}/';
    } else if (trimmed.length <= 2) {
      formatted = trimmed;
    } else {
      formatted = '${trimmed.substring(0, 2)}/${trimmed.substring(2)}';
    }

    // Caret: place at end, or respect digits typed position if possible
    final caret = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: caret),
    );
  }
}

// Edge trimming formatter removed; trimming occurs on submit in _handleSubmit
