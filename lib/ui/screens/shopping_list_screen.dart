import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/frosted_container.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/shopping_list_service.dart';
import '../../models/shopping_item.dart';
import '../responsive.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final _service = ShoppingListService();
  final List<ShoppingItem> _items = [];

  @override
  void initState() {
    super.initState();
    () async {
      final loaded = await _service.load();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(loaded);
      });
    }();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _persist() async {
    await _service.save(_items);
  }

  void _addItem() async {
    final t = _inputCtrl.text.trim();
    if (t.isEmpty) return;
    final exists = _items.any((e) => e.text.toLowerCase() == t.toLowerCase());
    if (exists) return;
    setState(() {
      _items.add(ShoppingItem(text: t));
      _inputCtrl.clear();
    });
    await _persist();
  }

  void _toggleAt(int index, bool? value) async {
    if (index < 0 || index >= _items.length) return;
    setState(() => _items[index] = _items[index].copyWith(done: value ?? false));
    await _persist();
  }

  void _removeAt(int index) async {
    if (index < 0 || index >= _items.length) return;
    setState(() => _items.removeAt(index));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final topPad = MediaQuery.of(context).padding.top + 72 + 8;
    return AppScaffold(
      // Mantener el fondo estable al abrir teclado
      resizeToAvoidBottomInset: false,
      // Consistente con otras pantallas (fondo detrás del AppBar)
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        title: Text(s.shoppingTitle),
        leading: const BackButton(),
        blurSigma: 6,
        tintOpacity: 0.04,
      ),
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            left: Responsive.hPadding(context),
            right: Responsive.hPadding(context),
            top: topPad,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FrostedContainer(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: s.shoppingAddPlaceholder,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _addItem(),
                      ),
                    ),
                    IconButton(
                      tooltip: s.shoppingAddTooltip,
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              if (_items.isNotEmpty)
                FrostedContainer(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withOpacity(0.25),
                    ),
                    itemBuilder: (ctx, i) {
                      final it = _items[i];
                      final style = Theme.of(context).textTheme.bodyLarge;
                      final textStyle = (style ?? const TextStyle()).copyWith(
                        decoration:
                            it.done ? TextDecoration.lineThrough : TextDecoration.none,
                        color: it.done
                            ? (style?.color ?? Colors.black).withOpacity(0.6)
                            : style?.color,
                      );
                      return ListTile(
                        leading: Checkbox(
                          value: it.done,
                          onChanged: (v) => _toggleAt(i, v),
                        ),
                        title: Text(it.text, style: textStyle),
                        trailing: IconButton(
                          tooltip: s.shoppingRemoveTooltip,
                          onPressed: () => _removeAt(i),
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
          ),
        ),
      ),
    ),
  );
  }
}
