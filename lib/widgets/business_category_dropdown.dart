import 'package:flutter/material.dart';

import '../models/business_type.dart';

const _highlight = Color(0xFF1A8F85);
const _labelPeach = Color(0xFFFFE0C2);

class BusinessCategoryDropdown extends StatefulWidget {
  const BusinessCategoryDropdown({
    super.key,
    required this.types,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final List<BusinessTypeOption> types;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  State<BusinessCategoryDropdown> createState() =>
      _BusinessCategoryDropdownState();
}

class _BusinessCategoryDropdownState extends State<BusinessCategoryDropdown> {
  final _link = LayerLink();
  final _fieldKey = GlobalKey();
  final _portal = OverlayPortalController();
  Size _fieldSize = Size.zero;

  void _toggle() {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      _fieldSize = box.size;
    }
    _portal.toggle();
    setState(() {});
  }

  void _close() {
    if (_portal.isShowing) {
      _portal.hide();
      setState(() {});
    }
  }

  BusinessTypeOption? get _selected {
    for (final type in widget.types) {
      if (type.id == widget.value) return type;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final open = _portal.isShowing;

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: Offset(0, _fieldSize.height + 6),
              child: Material(
                elevation: 8,
                color: Colors.white,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 320,
                    minWidth: _fieldSize.width,
                    maxWidth: _fieldSize.width,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: widget.types.length,
                    itemBuilder: (context, index) {
                      final type = widget.types[index];
                      final active = type.id == widget.value;
                      return InkWell(
                        onTap: () {
                          widget.onChanged(type.id);
                          _close();
                        },
                        child: ColoredBox(
                          color: active ? _highlight : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  type.displayEmoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    type.displayLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: active
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: CompositedTransformTarget(
        link: _link,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KeyedSubtree(
              key: _fieldKey,
              child: InkWell(
                onTap: widget.types.isEmpty ? null : _toggle,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  isEmpty: selected == null,
                  decoration: InputDecoration(
                    label: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      color: _labelPeach,
                      child: const Text('Business Category'),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: open ? _highlight : Colors.grey.shade500,
                        width: open ? 1.6 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _highlight,
                        width: 1.6,
                      ),
                    ),
                    errorText: widget.errorText,
                    suffixIcon: Icon(
                      open
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
                  ),
                  child: selected == null
                      ? const SizedBox(height: 22)
                      : Row(
                          children: [
                            Text(
                              selected.displayEmoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selected.displayLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
