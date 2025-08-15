import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../components/pin_screen.dart';

final withdrawStateProvider = StateProvider<bool>((ref) => false);
class WithdrawScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showConfirmation = ref.watch(withdrawStateProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (showConfirmation) {
              ref.read(withdrawStateProvider.notifier).state = false;
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: showConfirmation ? ConfirmWithdrawal() : WithdrawForm(),
      ),
    );
  }
}

class WithdrawForm extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Withdraw from wallet',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: Colors.white),
        ),
        SizedBox(height: 24),

        // Amount Field + Wallet Balance
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Amount', style: TextStyle(fontSize: 14, color: Colors.white)),
            Text('Wallet: ₦1,000,000.00', style: TextStyle(fontSize: 14, color: Color(0xFFBCAEE2))),
          ],
        ),
        SizedBox(height: 8),
        TextField(
          style: TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: inputDecoration('Enter amount to withdraw'),
        ),
        SizedBox(height: 16),

        // Account Number Field
        Text('Account number', style: TextStyle(fontSize: 14, color: Colors.white)),
        SizedBox(height: 8),
        TextField(
          style: TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: inputDecoration('Enter account number'),
        ),
        SizedBox(height: 16),

        // Bank Dropdown
        Text('Bank', style: TextStyle(fontSize: 14, color: Colors.white)),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          dropdownColor: Colors.black,
          style: TextStyle(color: Colors.white),
          decoration: inputDecoration('Select bank'),
          items: ['Wema Bank', 'GTBank', 'Access Bank', 'Zenith Bank']
              .map((bank) => DropdownMenuItem<String>(
            value: bank,
            child: Text(bank),
          ))
              .toList(),
          onChanged: (value) {},
        ),
        Spacer(),

        // Continue Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4D3490),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              ref.read(withdrawStateProvider.notifier).state = true;
            },
            child: Text('Continue', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

class ConfirmWithdrawal extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Withdrawal',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 24),

        // Confirmation Details
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              confirmRow('Amount', '₦100,000'),
              confirmRow('From', 'Soundhive Vest'),
              confirmRow('Beneficiary name', 'John Doe'),
              confirmRow('Beneficiary account number', '0261544227'),
              confirmRow('Beneficiary bank', 'GTBank'),
            ],
          ),
        ),
        Spacer(),

        // Confirm Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4D3490),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PinAuthenticationScreen(
                    buttonName: 'Withdraw',
                    onPinEntered: (pin) {
                      print("Entered PIN: $pin");
                      // Handle PIN authentication logic here
                    },
                  ),
                ),
              );

            },
            child: Text('Continue', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget confirmRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: Colors.white)),
          Text(value, style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// Input Field Decoration
InputDecoration inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey),
    filled: true,
    fillColor: Colors.black,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.purple),
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

