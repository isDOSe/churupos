import 'package:flutter/material.dart';

import '../../../../core/format/amount_input_formatter.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/currency.dart';

class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.value,
    required this.currency,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final Currency currency;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  String _lastEmitted = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _lastEmitted = widget.value;
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(AmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus &&
        widget.value != _lastEmitted &&
        widget.value != _controller.text) {
      _controller.text = widget.value;
      _lastEmitted = widget.value;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    _lastEmitted = '';
    widget.onChanged('');
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final hasText = _controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monto',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.muted,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                enabled: widget.enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.end,
                cursorColor: AppColors.amber,
                cursorWidth: 1.5,
                inputFormatters: [AmountInputFormatter()],
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 34,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.9,
                  color: widget.enabled ? AppColors.ink : AppColors.muted,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: '0',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 34,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.line,
                  ),
                ),
                onChanged: (text) {
                  final normalized = normalizeAmount(text);
                  if (normalized != _lastEmitted) {
                    _lastEmitted = normalized;
                    widget.onChanged(normalized);
                  }
                  setState(() {});
                },
              ),
            ),
            if (hasText && widget.enabled) ...[
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: 'Borrar monto',
                child: InkWell(
                  onTap: _clear,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                widget.currency.code,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 1,
          decoration: BoxDecoration(
            color: focused ? AppColors.ultra : AppColors.line,
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: AppColors.ultra.withValues(alpha: 0.25),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}
