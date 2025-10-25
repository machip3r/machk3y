import 'package:flutter/material.dart';

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
      body: const Center(child: Text('Vault Screen - Coming Soon')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add credential
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
