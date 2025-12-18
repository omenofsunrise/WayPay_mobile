// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
//
//
// import 'package:waypay_styles/waypay_styles.dart';
// import 'package:waypay_styles/waypay_styles.dart';
// import 'package:waypay_mobile/core/widgets/form_modal/label_text_field.dart';
// import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
// import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
// import 'package:waypay_mobile/features/clients/presentation/widgets/client_picker_modal.dart';

// class QueueSelectorModal extends StatelessWidget {
//   final void Function(ClientModel selectedClient, int amount, bool highPriority)
//   onSave;

//   const QueueSelectorModal({super.key, required this.onSave});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) =>
//           ClientsBloc()..add(LoadClients(refresh: true, page: 1, pageSize: 10)),
//       child: _QueueSelectorModalContent(onSave: onSave),
//     );
//   }
// }

// class _QueueSelectorModalContent extends StatefulWidget {
//   final void Function(ClientModel selectedClient, int amount, bool highPriority)
//   onSave;

//   const _QueueSelectorModalContent({required this.onSave});

//   @override
//   State<_QueueSelectorModalContent> createState() =>
//       _QueueSelectorModalContentState();
// }

// class _QueueSelectorModalContentState
//     extends State<_QueueSelectorModalContent> {
//   final TextEditingController _amountController = TextEditingController();
//   ClientModel? _selectedClient;
//   bool _highPriority = false;

//   @override
//   void initState() {
//     super.initState();
//     _amountController.addListener(_formatAmount);
//   }

//   void _formatAmount() {
//     final oldText = _amountController.text;
//     final oldSelection = _amountController.selection;

//     final raw = oldText.replaceAll(RegExp(r'\D'), '');

//     if (raw.isEmpty) {
//       _amountController.value = TextEditingValue(
//         text: '',
//         selection: TextSelection.collapsed(offset: 0),
//       );
//       return;
//     }

//     final parsed = int.tryParse(raw);
//     if (parsed == null) return;

//     final formatted = NumberFormat(
//       "#,##0",
//       "ru_RU",
//     ).format(parsed).replaceAll(',', ' ');
//     final newText = '$formatted ₽';
//     int cursorPositionInRaw = 0;
//     int digitCount = 0;

//     for (int i = 0; i < oldSelection.baseOffset && i < oldText.length; i++) {
//       if (RegExp(r'\d').hasMatch(oldText[i])) {
//         digitCount++;
//       }
//     }
//     cursorPositionInRaw = digitCount;
//     int newCursorPosition = 0;
//     int digitsPassed = 0;
//     while (digitsPassed < cursorPositionInRaw &&
//         newCursorPosition < newText.length) {
//       if (RegExp(r'\d').hasMatch(newText[newCursorPosition])) {
//         digitsPassed++;
//       }
//       newCursorPosition++;
//     }
//     if (newCursorPosition > newText.length) newCursorPosition = newText.length;

//     _amountController.value = TextEditingValue(
//       text: newText,
//       selection: TextSelection.collapsed(offset: newCursorPosition),
//     );
//   }

//   int _getRawAmount() {
//     final digits = _amountController.text.replaceAll(RegExp(r'\D'), '');
//     return int.tryParse(digits) ?? 0;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const SizedBox.shrink(); // AppModal removed (was here)
    // 
//       title: 'Добавить в очередь',
//       backgroundColor: Color(AppColors.background),
//       content: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 12),
//           Text(
//             'Клиент1',
//             style: AppStyle.medium16.copyWith(
//               color: Colors.black87,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 10),
//           InkWell(
//             onTap: () {
//               showDialog(
//                 context: context,
//                 builder: (_) => BlocProvider.value(
//                   value: context.read<ClientsBloc>(),
//                   child: ClientPickerModal(
//                     initialSelected: _selectedClient,
//                     onSelect: (client) {
//                       setState(() => _selectedClient = client);
//                     },
//                   ),
//                 ),
//               );
//             },
//             borderRadius: BorderRadius.circular(8),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//               decoration: BoxDecoration(
//                 border: Border.all(color: const Color(AppColors.primary)),
//                 borderRadius: BorderRadius.circular(8),
//                 color: Colors.white,
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       _selectedClient?.fullName ?? 'Выбрать клиента',
//                       style: TextStyle(
//                         color: _selectedClient != null
//                             ? Colors.black87
//                             : Colors.grey,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w400,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   const Icon(Icons.arrow_drop_down, color: Colors.black),
//                 ],
//               ),
//             ),
//           ),
//           LabeledTextField(
//             label: 'Сумма',
//             controller: _amountController,
//             keyboardType: TextInputType.number,
//             onChanged: (value) {
//               setState(() {});
//             },
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Высокий приоритет',
//                 style: TextStyle(color: Colors.black, fontSize: 16),
//               ),
//               ToggleSwitch(
//                 value: _highPriority,
//                 onChanged: (value) {
//                   setState(() {
//                     _highPriority = value;
//                   });
//                 },
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: DefaultButton(
//                   text: 'Отмена',
//                   isPrimary: false,
//                   onPressed: () => context.pop(),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: DefaultButton(
//                   text: 'Добавить',
//                   color: const Color(AppColors.primary),
//                   onPressed: (_selectedClient != null && _getRawAmount() > 0)
//                       ? () {
//                           widget.onSave(
//                             _selectedClient!,
//                             _getRawAmount(),
//                             _highPriority,
//                           );
//                           Navigator.of(context).pop();
//                         }
//                       : () {},
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
