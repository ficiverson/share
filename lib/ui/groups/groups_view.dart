import 'package:flutter/material.dart';
import 'package:share_app/injector/dependency_injector.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/user.dart';
import 'package:share_app/ui/group-detail/group_detail_router.dart';
import 'package:share_app/ui/groups/groups_presenter.dart';
import 'package:share_app/ui/login/login_router.dart';
import 'package:share_app/utils/share_colors.dart';

/// Pantalla "Mis grupos": lista en tiempo real los grupos del usuario,
/// permite crear un grupo nuevo o unirse a uno existente con su ID.
class GroupsView extends StatefulWidget {
  const GroupsView({super.key});

  @override
  State<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<GroupsView> implements GroupsViewContract {
  late final GroupsPresenter _presenter;
  AppUser? _user;
  List<Group>? _groups;
  String? _error;
  bool _actionLoading = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    final injector = DependencyInjector.instance;
    _presenter = GroupsPresenter(
      this,
      invoker: injector.invoker,
      watchGroupsUseCase: injector.watchGroupsUseCase,
      createGroupUseCase: injector.createGroupUseCase,
      joinGroupUseCase: injector.joinGroupUseCase,
    );
    _user = injector.authRepository.getCurrentUser();
    final user = _user;
    if (user != null) {
      _presenter.watchGroups(user);
    }
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  @override
  void onGroupsChanged(List<Group> groups) {
    setState(() {
      _groups = groups;
      _error = null;
    });
  }

  @override
  void onGroupsError(String error) {
    setState(() => _error = error);
  }

  @override
  void onActionLoading(bool isLoading) {
    setState(() => _actionLoading = isLoading);
  }

  @override
  void onGroupCreated(Group group) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Grupo "${group.name}" creado')),
    );
  }

  @override
  void onGroupJoined(Group group) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Te has unido a "${group.name}"')),
    );
  }

  @override
  void onActionError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    final injector = DependencyInjector.instance;
    injector.invoker.execute(injector.signOutUseCase).listen((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginRouter.build()),
        );
      }
    });
  }

  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final currencyController = TextEditingController(text: 'EUR');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre del grupo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: currencyController,
              decoration: const InputDecoration(labelText: 'Moneda (ej. EUR)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Crear')),
        ],
      ),
    );

    final user = _user;
    if (result == true && user != null && nameController.text.trim().isNotEmpty) {
      _presenter.createGroup(
        user,
        nameController.text.trim(),
        currencyController.text.trim().isEmpty ? 'EUR' : currencyController.text.trim().toUpperCase(),
      );
    }
  }

  Future<void> _showJoinGroupDialog() async {
    final idController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unirse a un grupo'),
        content: TextField(
          controller: idController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'ID del grupo'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unirme')),
        ],
      ),
    );

    final user = _user;
    if (result == true && user != null && idController.text.trim().isNotEmpty) {
      _presenter.joinGroup(user, idController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final groups = _groups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis grupos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Unirse a un grupo',
            onPressed: _actionLoading ? null : _showJoinGroupDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _signingOut ? null : _signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Hola, ${user.displayName}', style: const TextStyle(fontSize: 14)),
              ),
            ),
          if (_actionLoading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: ShareColors.error)),
            ),
          Expanded(
            child: groups == null
                ? const Center(child: CircularProgressIndicator())
                : groups.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.group, size: 64, color: ShareColors.primary),
                              SizedBox(height: 16),
                              Text(
                                'Todavía no tienes grupos.\n'
                                'Crea uno o únete a uno con su ID.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.pie_chart, color: ShareColors.primary),
                              title: Text(group.name),
                              subtitle: Text(
                                '${group.members.length} miembro${group.members.length == 1 ? '' : 's'} · ${group.currency}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => GroupDetailRouter.open(context, group.groupId),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _actionLoading ? null : _showCreateGroupDialog,
        tooltip: 'Crear grupo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
