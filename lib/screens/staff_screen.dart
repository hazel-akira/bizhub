import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/staff_access.dart';
import '../models/auth_user.dart';
import '../providers/auth_provider.dart';
import '../providers/business_api_provider.dart';
import '../widgets/access_denied_page.dart';

String _staffApiError(Object e) {
  final raw = e.toString().replaceFirst('ApiException: ', '');
  if (raw.toLowerCase().contains('could not be found') ||
      raw.contains('404')) {
    return 'Staff roles are not on the live server yet. '
        'Ask an admin to deploy the API, then try again.';
  }
  return raw;
}

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  bool _loading = true;
  String? _error;
  List<AuthUser> _staff = [];
  List<StaffRoleInfo> _roles = StaffAccess.catalog;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final api = ref.read(businessApiProvider);
    if (api == null) {
      setState(() {
        _loading = false;
        _error = 'Sign in as an owner to manage staff.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final roles = await api.getStaffRoles();
      final staff = await api.getStaff();
      if (!mounted) return;
      setState(() {
        _roles = roles.isEmpty ? StaffAccess.catalog : roles;
        _staff = staff;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _staffApiError(e);
      });
    }
  }

  Future<void> _openEditor({AuthUser? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _StaffEditorSheet(
        existing: existing,
        roles: _roles,
      ),
    );
    if (saved == true) {
      await _reload();
    }
  }

  Future<void> _deactivate(AuthUser staff) async {
    final api = ref.read(businessApiProvider);
    if (api == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate staff?'),
        content: Text('${staff.name} will no longer be able to sign in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await api.deactivateStaff(staff.id);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_staffApiError(e))),
      );
    }
  }

  String _labelFor(String id) {
    for (final role in _roles) {
      if (role.id == id) return role.label;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canOpenStaff) {
      return const AccessDeniedPage(title: 'Staff & roles');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff & roles'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add staff'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'A person can have more than one role. Cashier cannot also be admin — admin already has full access.',
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            for (final member in _staff)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(member.name),
                  subtitle: Text(
                    [
                      member.email,
                      member.resolvedRoles.map(_labelFor).join(' · '),
                      if (!member.isActive) 'Deactivated',
                    ].join('\n'),
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _openEditor(existing: member);
                      if (value == 'deactivate') _deactivate(member);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit roles')),
                      if (member.isActive)
                        const PopupMenuItem(
                          value: 'deactivate',
                          child: Text('Deactivate'),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _StaffEditorSheet extends ConsumerStatefulWidget {
  const _StaffEditorSheet({
    required this.roles,
    this.existing,
  });

  final AuthUser? existing;
  final List<StaffRoleInfo> roles;

  @override
  ConsumerState<_StaffEditorSheet> createState() => _StaffEditorSheetState();
}

class _StaffEditorSheetState extends ConsumerState<_StaffEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late Set<String> _selected;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _email = TextEditingController(text: existing?.email ?? '');
    _password = TextEditingController();
    _selected = {...(existing?.resolvedRoles ?? const <String>[])};
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _toggle(String id, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(id);
        if (id == StaffAccess.owner) {
          _selected.remove(StaffAccess.cashier);
        }
        if (id == StaffAccess.cashier) {
          _selected.remove(StaffAccess.owner);
        }
      } else {
        _selected.remove(id);
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selected.isEmpty) {
      setState(() => _error = 'Select at least one role.');
      return;
    }
    if (StaffAccess.cashierConflictsWithOwner(_selected)) {
      setState(() => _error = 'A cashier cannot also be an admin.');
      return;
    }

    final api = ref.read(businessApiProvider);
    if (api == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final existing = widget.existing;
      if (existing == null) {
        await api.createStaff(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          roles: _selected.toList(),
        );
      } else {
        await api.updateStaff(
          staffId: existing.id,
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text.trim().isEmpty ? null : _password.text,
          roles: _selected.toList(),
          isActive: true,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _staffApiError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final currentUser = ref.watch(authProvider).user;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'Add staff' : 'Edit staff',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: widget.existing == null
                      ? 'Password'
                      : 'New password (optional)',
                ),
                validator: (v) {
                  if (widget.existing != null && (v == null || v.isEmpty)) {
                    return null;
                  }
                  if (v == null || v.length < 8) {
                    return 'At least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Roles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              for (final role in widget.roles)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selected.contains(role.id),
                  onChanged: (v) => _toggle(role.id, v ?? false),
                  title: Text(role.label),
                  subtitle: Text(role.summary),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save'),
              ),
              if (widget.existing?.id == currentUser?.id)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('This is your account.'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
