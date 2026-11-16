import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/contact.dart';
import 'contact_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper.instance;
  final _searchCtrl = TextEditingController();

  List<Contact> _contacts = [];
  bool _loading = true;
  int _tabIndex = 0; // 0 = All, 1 = Favorites

  bool get _favoritesOnly => _tabIndex == 1;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final contacts = await _db.getContacts(
      query: _searchCtrl.text,
      favoritesOnly: _favoritesOnly,
    );
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _loading = false;
    });
  }

  Future<void> _openForm([Contact? contact]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ContactFormScreen(contact: contact)),
    );
    if (changed == true) {
      _loadContacts();
      _showSnack(contact == null ? 'Contact added' : 'Contact updated');
    }
  }

  Future<void> _toggleFavorite(Contact contact) async {
    await _db.toggleFavorite(contact);
    _loadContacts();
  }

  Future<void> _confirmDelete(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: const Text('Delete contact?'),
        content: Text('"${contact.name}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteContact(contact.id!);
      _loadContacts();
      _showSnack('Contact deleted');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _showDetails(Contact contact) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(name: contact.name, radius: 36),
              const SizedBox(height: 12),
              Text(
                contact.name,
                style: Theme.of(ctx).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              Text(
                'ID: ${contact.id}',
                style: Theme.of(ctx).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(contact.phone),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(contact.email),
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(contact.address),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDelete(contact);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openForm(contact);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(
          _favoritesOnly ? Icons.star_rounded : Icons.contacts_rounded,
          size: 26,
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_favoritesOnly ? 'Favorites' : 'Contacts'),
            if (!_loading)
              Text(
                '${_contacts.length} '
                '${_contacts.length == 1 ? 'contact' : 'contacts'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadContacts,
          ),
          IconButton(
            tooltip: 'Add contact',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => _openForm(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) {
                setState(() {}); // refresh clear button visibility
                _loadContacts();
              },
              decoration: InputDecoration(
                hintText: 'Search by name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                          _loadContacts();
                        },
                      ),
              ),
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) {
          setState(() => _tabIndex = i);
          _loadContacts();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'All',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline_rounded),
            selectedIcon: Icon(Icons.star_rounded),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_contacts.isEmpty) {
      final searching = _searchCtrl.text.trim().isNotEmpty;
      return _EmptyState(
        icon: searching
            ? Icons.search_off_rounded
            : _favoritesOnly
                ? Icons.star_outline_rounded
                : Icons.contacts_outlined,
        message: searching
            ? 'No contacts match "${_searchCtrl.text.trim()}"'
            : _favoritesOnly
                ? 'No favorite contacts yet.\nTap the star on a contact to add it.'
                : 'No contacts yet.\nTap "Add" to create your first one.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
      itemCount: _contacts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            leading: _Avatar(name: contact.name),
            title: Text(
              contact.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${contact.phone}\n${contact.email}'),
            isThreeLine: true,
            onTap: () => _showDetails(contact),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Favorite',
                  icon: Icon(
                    contact.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: contact.isFavorite ? Colors.amber : null,
                  ),
                  onPressed: () => _toggleFavorite(contact),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _openForm(contact);
                    if (value == 'delete') _confirmDelete(contact);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double radius;

  const _Avatar({required this.name, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      foregroundColor: colors.onPrimaryContainer,
      child: Text(
        initial,
        style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
