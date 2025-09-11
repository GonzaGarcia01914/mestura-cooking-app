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
    setState(
      () => _items[index] = _items[index].copyWith(done: value ?? false),
    );
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
    const double appBarHeight = 72.0;
    const double topPad =
        appBarHeight; // exactamente bajo el AppBar, sin margen extra

    Widget emptyState() {
      final cs = Theme.of(context).colorScheme;
      return LayoutBuilder(
        builder: (context, constraints) {
          final contentHeight = constraints.maxHeight.clamp(
            0.0,
            double.infinity,
          );
          return SizedBox(
            height: contentHeight,
            child: Center(
              child: FrostedContainer(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 48,
                      color: cs.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.shoppingEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return AppScaffold(
      // Mantener el fondo estable al abrir teclado
      resizeToAvoidBottomInset: false,
      // Mismo estilo que otras pantallas: contenido detrás del AppBar translúcido
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        title: Text(s.shoppingTitle),
        leading: const BackButton(),
        blurSigma: 6,
        tintOpacity: 0.04,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: Responsive.hPadding(context),
            right: Responsive.hPadding(context),
            top: topPad,
            bottom: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.maxContentWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input fijo en la parte superior
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
                              contentPadding: const EdgeInsets.symmetric(
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

                  // Contenido debajo: contenedor crece con items y solo hace scroll si es necesario
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (_items.isEmpty) return emptyState();

                        const double rowExtent = 64; // alto aproximado por fila
                        final double estimatedHeight =
                            _items.length * rowExtent + 8; // + padding
                        final double maxHeight = constraints.maxHeight;
                        final double containerHeight = estimatedHeight.clamp(
                          0.0,
                          maxHeight,
                        );
                        final bool shouldScroll = estimatedHeight > maxHeight;

                        return Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            height: containerHeight,
                            child: FrostedContainer(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: ListView.separated(
                                shrinkWrap: !shouldScroll,
                                physics:
                                    shouldScroll
                                        ? const AlwaysScrollableScrollPhysics()
                                        : const NeverScrollableScrollPhysics(),
                                itemCount: _items.length,
                                separatorBuilder:
                                    (_, __) => Divider(
                                      height: 1,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withOpacity(0.25),
                                    ),
                                itemBuilder: (ctx, i) {
                                  final it = _items[i];
                                  final style =
                                      Theme.of(context).textTheme.bodyLarge;
                                  final textStyle = (style ?? const TextStyle())
                                      .copyWith(
                                        decoration:
                                            it.done
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                        color:
                                            it.done
                                                ? (style?.color ?? Colors.black)
                                                    .withOpacity(0.6)
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
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
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
    );
  }
}
