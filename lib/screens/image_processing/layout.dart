import 'package:flutter/material.dart';

class Layout extends StatelessWidget {
  final Widget mainArea;
  final Widget secondaryArea;

  const Layout({
    super.key,
    required this.mainArea,
    required this.secondaryArea,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Main area takes more space
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.grey.shade200,
            child: mainArea,
          ),
        ),
        // Secondary area for tools
        Container(
          width: 250, // fixed width for tools panel
          color: Colors.white,
          child: secondaryArea,
        ),
      ],
    );
  }
}