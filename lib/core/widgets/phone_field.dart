import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';

class CountryCode {
  const CountryCode(this.flag, this.dial, this.name, this.digits);

  final String flag;
  final String dial;
  final String name;

  /// Ulke kodu haric beklenen rakam sayisi.
  final int digits;

  static const list = [
    CountryCode('🇹🇷', '+90', 'Türkiye', 10),
    CountryCode('🇩🇪', '+49', 'Almanya', 11),
    CountryCode('🇳🇱', '+31', 'Hollanda', 9),
    CountryCode('🇬🇧', '+44', 'Birleşik Krallık', 10),
    CountryCode('🇺🇸', '+1', 'ABD', 10),
    CountryCode('🇫🇷', '+33', 'Fransa', 9),
    CountryCode('🇦🇿', '+994', 'Azerbaycan', 9),
  ];
}

/// Telefon alanindan disariya verilen deger.
class PhoneValue {
  const PhoneValue({
    required this.fullNumber,
    required this.isEmpty,
    required this.isComplete,
    required this.expectedDigits,
  });

  /// "+905551112233" formatinda. Bos ise "".
  final String fullNumber;
  final bool isEmpty;

  /// Beklenen hane sayisi girilmis mi.
  final bool isComplete;
  final int expectedDigits;

  /// Bos birakilabilir; ama yazildiysa tam olmali.
  bool get isValid => isEmpty || isComplete;
}

/// Ulke kodu secimi + rakam kisitli telefon girisi.
class PhoneField extends StatefulWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<PhoneValue>? onChanged;

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  CountryCode _country = CountryCode.list.first;

  void _emit() {
    final digits = widget.controller.text.replaceAll(RegExp(r'\D'), '');

    widget.onChanged?.call(
      PhoneValue(
        fullNumber: digits.isEmpty ? '' : '${_country.dial}$digits',
        isEmpty: digits.isEmpty,
        isComplete: digits.length == _country.digits,
        expectedDigits: _country.digits,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(_country.digits),
        _PhoneSpacer(),
      ],
      decoration: InputDecoration(
        hintText: _country.dial == '+90' ? '555 111 22 33' : 'Telefon numarası',
        errorText: widget.errorText,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: PopupMenuButton<CountryCode>(
            initialValue: _country,
            tooltip: 'Ülke kodu',
            onSelected: (c) {
              setState(() {
                _country = c;
                widget.controller.clear();
              });
              _emit();
            },
            itemBuilder: (_) => CountryCode.list
                .map(
                  (c) => PopupMenuItem(
                    value: c,
                    child: Text('${c.flag}  ${c.name}  ${c.dial}'),
                  ),
                )
                .toList(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_country.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Text(
                  _country.dial,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Icon(Icons.arrow_drop_down_rounded, size: 20),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
      ),
      onChanged: (_) => _emit(),
    );
  }
}

/// 5551112233 -> 555 111 22 33
class _PhoneSpacer extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6 || i == 8) buffer.write(' ');
      buffer.write(digits[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}