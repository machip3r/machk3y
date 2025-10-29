import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vault_provider.dart';
import '../../models/credential.dart';
import 'add_credential_screen.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [
          IconButton(
            onPressed: () {
              // Search functionality
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              // Filter functionality
            },
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Consumer<VaultProvider>(
        builder: (context, vaultProvider, child) {
          if (vaultProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vaultProvider.credentials.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Your vault is empty',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first credential to get started',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: vaultProvider.refreshCredentials,
            child: ListView.builder(
              itemCount: vaultProvider.filteredCredentials.length,
              itemBuilder: (context, index) {
                final credential = vaultProvider.filteredCredentials[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      credential.type == CredentialType.email
                          ? Icons.email
                          : credential.type == CredentialType.website
                          ? Icons.web
                          : Icons.key,
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_credential_fab',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddCredentialScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}
