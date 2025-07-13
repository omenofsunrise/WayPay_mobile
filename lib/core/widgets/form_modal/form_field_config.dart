import 'package:flutter/material.dart';

class FormFieldConfig {
  final TextEditingController controller;
  final String? label;
  final String? placeholder;
  final TextInputType keyboardType;
  final bool obscureText;

  FormFieldConfig({
    required this.controller,
    this.label,
    this.placeholder,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });
}
