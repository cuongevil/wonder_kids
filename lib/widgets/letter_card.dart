import 'package:flutter/material.dart';
import '../models/vn_letter.dart';


class LetterCard extends StatelessWidget {
  final VnLetter letter;
  final VoidCallback onTap;


  const LetterCard({super.key, required this.letter, required this.onTap});


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(blurRadius: 8, spreadRadius: 1, offset: Offset(0, 2), color: Colors.black12),
          ],
        ),
        child: Center(
          child: Text(
            letter.char,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}