import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? hintText;
  final int? maxLines;
  final bool hasToggleVisibility;
  final String? secondLabel;
  final void Function(String)? onChanged;
  final VoidCallback? toggleVisibility;
  final bool showVisibility;
  final String? errorText;
  final IconData? prefixIcon;
  final List<TextInputFormatter>? inputFormatters;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.hasToggleVisibility = false,
    this.onChanged,
    this.toggleVisibility,
    this.showVisibility = false,
    this.errorText,
    this.hintText,
    this.secondLabel,
    this.inputFormatters,
    this.maxLines,
    this.prefixIcon
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.WHITECOLOR,
              ),
            ),
            if(secondLabel != null && secondLabel!.isNotEmpty)
            Text(
              secondLabel ?? '',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFC5AFFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null ?  Icon(prefixIcon, color: Color(0xFFB0B0B6),) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null ? const Color.fromRGBO(219, 33, 33, 0.76) : AppColors.FORMGREYCOLOR,
              ),
            ),
            hintText: hintText,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null
                    ? const Color.fromRGBO(219, 33, 33, 0.76) // Error color
                    : AppColors.WHITECOLOR, // Normal focus color
                width: 2.0,
              ),
            ),
            errorText: errorText,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class LabeledSelectField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final List<Map<String, String>> items;
  final String? secondLabel;
  final String? hintText;
  final String? errorText;
  final Function(String)? onChanged; // value


  const LabeledSelectField({
    super.key,
    required this.label,
    required this.controller,
    required this.items,
    this.secondLabel,
    this.hintText,
    this.errorText,
    this.onChanged
  });

  @override
  State<LabeledSelectField> createState() => _LabeledSelectFieldState();
}

class _LabeledSelectFieldState extends State<LabeledSelectField> {
  String _searchQuery = '';

  late final Map<String, String> _valueToLabel;

  @override
  void initState() {
    super.initState();
    _valueToLabel = {
      for (var item in widget.items) item['value']!: item['label']!,
    };
    final label = _valueToLabel[widget.controller.text];
    if (label != null) {
      widget.controller.text = label;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.WHITECOLOR,
              ),
            ),
            if (widget.secondLabel != null && widget.secondLabel!.isNotEmpty)
              Text(
                widget.secondLabel ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFC5AFFF),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Readonly TextField
        GestureDetector(
          onTap: () => _openBottomSheet(context),
          child: AbsorbPointer(
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Select an option',
                suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.errorText != null
                        ? const Color.fromRGBO(219, 33, 33, 0.76)
                        : AppColors.FORMGREYCOLOR,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.errorText != null
                        ? const Color.fromRGBO(219, 33, 33, 0.76)
                        : AppColors.WHITECOLOR,
                    width: 2.0,
                  ),
                ),
                errorText: widget.errorText,
              ),
              style: const TextStyle(color: Colors.white),
              readOnly: true,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _openBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: const Color(0xFF1E1B2E),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final filteredItems = widget.items
            .where((item) =>
            item['label']!.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search bar
                  TextField(
                    onChanged: (value) {
                      setModalState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scrollable list
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return ListTile(
                          title: Text(
                            item['label'] ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                            onTap: () {
                              final value = item['value']!;
                              final label = item['label']!;
                              setState(() {
                                widget.controller.text = label; // Show label in the UI
                              });
                              if (widget.onChanged != null) {
                                widget.onChanged!(value);
                              }
                              Navigator.pop(context);
                            }
                        );
                      },

                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class LabeledMultiSelectField extends StatelessWidget {
  final String label;
  final List<Map<String, String>> items;
  final List<String> selectedValues;
  final String? secondLabel;
  final String? hintText;
  final String? errorText;
  final Function(List<String>)? onChanged;

  const LabeledMultiSelectField({
    super.key,
    required this.label,
    required this.items,
    required this.selectedValues,
    this.secondLabel,
    this.hintText,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final _valueToLabel = {for (var item in items) item['value']!: item['label']!};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.WHITECOLOR,
              ),
            ),
            if (secondLabel != null && secondLabel!.isNotEmpty)
              Text(
                secondLabel!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFC5AFFF),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Tappable custom field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null
                  ? const Color.fromRGBO(219, 33, 33, 0.76)
                  : AppColors.FORMGREYCOLOR,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tags
              Expanded(
                child: selectedValues.isEmpty
                    ? GestureDetector(
                  onTap: () => _openBottomSheet(context),
                  child: Text(
                    hintText ?? 'Select options',
                    style: const TextStyle(color: Colors.white38),
                  ),
                )
                    : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: selectedValues.map((value) {
                    final label = _valueToLabel[value] ?? value;
                    return Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2B3F),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              final newValues = List<String>.from(selectedValues);
                              newValues.remove(value);
                              onChanged?.call(newValues);
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Dropdown icon
              GestureDetector(
                onTap: () => _openBottomSheet(context),
                child: const Padding(
                  padding: EdgeInsets.only(left: 6.0),
                  child: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(color: Color.fromRGBO(219, 33, 33, 0.76)),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _openBottomSheet(BuildContext context) {
    String searchQuery = '';
    List<String> tempSelected = List.from(selectedValues);

    showModalBottomSheet(
      backgroundColor: const Color(0xFF1E1B2E),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredItems = items.where((item) =>
                item['label']!.toLowerCase().contains(searchQuery.toLowerCase())).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Search bar
                  TextField(
                  onChanged: (value) {
            setModalState(() => searchQuery = value);
            },
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
              const SizedBox(height: 16),

              // List with checkboxes
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final value = item['value']!;
                    final label = item['label']!;
                    final isSelected = tempSelected.contains(value);

                    return CheckboxListTile(
                      title: Text(label, style: const TextStyle(color: Colors.white)),
                      value: isSelected,
                      onChanged: (checked) {
                        setModalState(() {
                          if (checked == true) {
                            if (!tempSelected.contains(value)) {
                              tempSelected.add(value);
                            }
                          } else {
                            tempSelected.remove(value);
                          }
                        });
                      },
                      activeColor: Colors.deepPurpleAccent,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.BACKGROUNDCOLOR,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  onChanged?.call(tempSelected);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
                const SizedBox(height: 16),
                ]
              ),
            );
          },
        );
      },
    );
  }
}


class CurrencyInputField extends StatefulWidget {
  final String label;
  final String? hintText;
  final String suffixText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const CurrencyInputField({
    super.key,
    required this.label,
    this.hintText,
    this.suffixText = '',
    this.controller,
    this.onChanged,
    this.validator,
  });

  @override
  State<CurrencyInputField> createState() => _CurrencyInputFieldState();
}

class _CurrencyInputFieldState extends State<CurrencyInputField> {
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
    // Initialize with "0.00" if empty, to match the "₦0.00" prefix appearance
    if (_internalController.text.isEmpty) {
      _internalController.text = '0.00';
    }
    _internalController.addListener(_formatCurrencyInput);
  }

  @override
  void dispose() {
    _internalController.removeListener(_formatCurrencyInput);
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _formatCurrencyInput() {
    String text = _internalController.text;

    // Remove all non-digit characters except the first dot
    String cleanText = text.replaceAll(RegExp(r'[^\d.]'), '');
    List<String> parts = cleanText.split('.');

    // Handle decimal part
    if (parts.length > 1) {
      String integerPart = parts[0];
      String decimalPart = parts[1];

      // Ensure only one decimal point
      if (parts.length > 2) {
        decimalPart = parts[1] + parts.sublist(2).join();
      }

      // Limit decimal part to two digits
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }

      String newText = '$integerPart.$decimalPart';

      _internalController.value = _internalController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    } else {
      // No decimal, just keep the digits
      _internalController.value = _internalController.value.copyWith(
        text: cleanText,
        selection: TextSelection.collapsed(offset: cleanText.length),
      );
    }

    // Remove this block — it prevents deletion
    // if (_internalController.text.isEmpty || _internalController.text == '0') {
    //   _internalController.text = '0.00';
    // }

    // Call the user-provided onChanged callback
    if (widget.onChanged != null) {
      widget.onChanged!(_internalController.text);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _internalController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')), // Allow digits and at most two decimal places
          ],
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: Color(0xFF7C7C88)), // Adjust hint color for dark background
            prefixText: '₦', // Naira symbol prefix
            prefixStyle:  GoogleFonts.roboto(
              textStyle: const TextStyle(
                color: Color(0xFF7C7C88),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              )
            ),
            suffixText: widget.suffixText,
            suffixStyle: const TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
            filled: true,
            fillColor: Colors.black, // Black background for the input field
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0), // Rounded corners
              borderSide: const BorderSide(color: Colors.white38), // Subtle border
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.white38),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.white38), // Orange border when focused
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(
            color: Colors.white, // White text color for input
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
