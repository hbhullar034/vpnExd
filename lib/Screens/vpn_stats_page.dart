
import 'package:flutter/material.dart';

class VpnStatTile<T> extends StatelessWidget {
  final String label;
  final String valueFormatter;
  final IconData icon;
  final Color iconColor;

  const VpnStatTile({
    Key? key,
    required this.label,
    required this.valueFormatter,
    required this.icon,
    required this.iconColor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Expanded(
          child:Container(
          margin: const EdgeInsets.only(
                          left: 4, right: 4, top: 8, bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
             border: Border.all(
              color: const Color.fromARGB(255, 226, 224, 224),
              width: 1, // Thickness of the border
            ),
          
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  
                
                  Text(label, style: TextStyle(color: Colors.grey[700],fontSize: 14)),
                  
                ],
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Text(
               valueFormatter, // Dynamically format the value
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, size: 18, color: iconColor),
                ],
              ),
            ],
          ),
        ),
        );
  }
}
