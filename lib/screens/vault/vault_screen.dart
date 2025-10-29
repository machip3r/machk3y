import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vault_provider.dart';
import '../../models/credential.dart';
import 'add_credential_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Load more on scroll
    _scrollController.addListener(() {
      final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !vaultProvider.isLoadingMore &&
          vaultProvider.hasMore) {
        vaultProvider.loadMoreCredentials();
      }
    });
  }

  void _onSearchChanged() {
    // Debounce search
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
      vaultProvider.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilterDialog(BuildContext context) {
    final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
    final theme = Theme.of(context);
    final tags = vaultProvider.tags;
    CredentialType? tempSelectedType = vaultProvider.selectedType;
    String? tempSelectedTag = vaultProvider.selectedTag;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.55,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.filter_list, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Filters',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {
                              vaultProvider.clearFilters();
                              Navigator.pop(context);
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Type section
                      Text(
                        'Type',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTypeFilterChip(
                              context,
                              label: 'All',
                              icon: Icons.apps,
                              isSelected: tempSelectedType == null,
                              onTap: () {
                                setModalState(() {
                                  tempSelectedType = null;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ...CredentialType.values.map(
                              (type) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildTypeFilterChip(
                                  context,
                                  label: _getCredentialTypeLabel(type),
                                  icon: _getCredentialTypeIcon(type),
                                  isSelected: tempSelectedType == type,
                                  onTap: () {
                                    setModalState(() {
                                      tempSelectedType = type;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tags section
                      Row(
                        children: [
                          Icon(Icons.label_outline, size: 18, color: theme.colorScheme.onSurface),
                          const SizedBox(width: 6),
                          Text(
                            'Tags',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('All'),
                                selected: tempSelectedTag == null,
                                onSelected: (_) {
                                  setModalState(() {
                                    tempSelectedTag = null;
                                  });
                                },
                              ),
                              ...tags.map((tag) {
                                final selected = tempSelectedTag == tag;
                                return FilterChip(
                                  selected: selected,
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.tag, size: 14),
                                      const SizedBox(width: 6),
                                      Text(tag),
                                    ],
                                  ),
                                  onSelected: (_) {
                                    setModalState(() {
                                      tempSelectedTag = selected ? null : tag;
                                    });
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Apply button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            vaultProvider.setSelectedType(tempSelectedType);
                            vaultProvider.setSelectedTag(tempSelectedTag);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Apply Filters'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _clearFilters() {
    final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
    vaultProvider.clearFilters();
    _searchController.clear();
  }

  IconData _getCredentialTypeIcon(CredentialType type) {
    switch (type) {
      case CredentialType.email:
        return Icons.email_outlined;
      case CredentialType.website:
        return Icons.web_outlined;
      case CredentialType.card:
        return Icons.credit_card_outlined;
      case CredentialType.social:
        return Icons.share_outlined;
      case CredentialType.other:
        return Icons.more_horiz_outlined;
    }
  }

  String _getCredentialTypeLabel(CredentialType type) {
    switch (type) {
      case CredentialType.email:
        return 'Email';
      case CredentialType.website:
        return 'Website';
      case CredentialType.card:
        return 'Card';
      case CredentialType.social:
        return 'Social';
      case CredentialType.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<VaultProvider>(
            builder: (context, vaultProvider, child) {
              if (vaultProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredCredentials = vaultProvider.filteredCredentials;

              if (vaultProvider.credentials.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => vaultProvider.refreshCredentials(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your vault is empty',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first credential to get started',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              if (filteredCredentials.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => vaultProvider.refreshCredentials(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No credentials found',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filter',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _clearFilters,
                              child: const Text('Clear Filters'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => vaultProvider.refreshCredentials(),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: 80),
                  itemCount: filteredCredentials.length +
                      (vaultProvider.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Load more indicator
                    if (vaultProvider.isLoadingMore && index == filteredCredentials.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final credential = filteredCredentials[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          _getCredentialTypeIcon(credential.type),
                          color: isDark
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(credential.displayTitle),
                      subtitle: Text(credential.username),
                      trailing: credential.isStarred
                          ? const Icon(Icons.star, color: Colors.amber)
                          : null,
                      onTap: () {
                        // Navigate to credential details
                      },
                    );
                  },
                ),
              );
            },
          ),

          // Search and FAB row at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Search Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Consumer<VaultProvider>(
                        builder: (context, vaultProvider, child) {
                          return TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Search credentials...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon:
                                  vaultProvider.selectedType != null ||
                                      _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: _clearFilters,
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // FAB Button
                  FloatingActionButton(
                    heroTag: 'add_credential_fab',
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddCredentialScreen(),
                        ),
                      );

                      // Refresh credentials if a credential was added
                      if (result == true || result == null) {
                        final vaultProvider = Provider.of<VaultProvider>(
                          context,
                          listen: false,
                        );
                        await vaultProvider.refreshCredentials();
                      }
                    },
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
