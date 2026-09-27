import 'package:flutter/material.dart';
import 'package:home_care/themes/app_colors.dart';

class TextInputField extends StatefulWidget {
  const TextInputField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final IconData icon;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  State<TextInputField> createState() => _TextInputFieldState();
}

class _TextInputFieldState extends State<TextInputField> {
  late bool _obscureText;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            focused ? AppShadows.glow(AppColors.primary, strength: 0.55) : null,
      ),
      child: TextField(
        focusNode: _focus,
        keyboardType: widget.keyboardType,
        obscureText: _obscureText,
        controller: widget.controller,
        onChanged: widget.onChanged,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        autofillHints: widget.autofillHints,
        textCapitalization: widget.textCapitalization,
        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: widget.labelText,
          fillColor: focused ? context.surface : null,
          prefixIcon: Icon(
            widget.icon,
            size: 21,
            color: focused ? AppColors.primary : context.textMuted,
          ),
          suffixIcon: widget.obscureText
              ? IconButton(
                  tooltip: _obscureText ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: context.textMuted,
                    size: 21,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
              : null,
        ),
      ),
    );
  }
}
