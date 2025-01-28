
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/theme_controller.dart';

class VpnStatTile<T> extends StatelessWidget {
  final String label;
  final String valueFormatter;
  final IconData icon;
  final Color iconColor;

   VpnStatTile({
    super.key,
    required this.label,
    required this.valueFormatter,
    required this.icon,
    required this.iconColor
  });
final themeController = Get.find<ThemeController>();
  @override
  Widget build(BuildContext context) {
    return  Expanded(
          child:Container(
          margin: const EdgeInsets.only(
                          left: 4, right: 4, top: 8, bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.byteWidgetBackground,
            borderRadius: BorderRadius.circular(8),
            
          
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  
                
                  Text(label, style: TextStyle(color: Theme.of(context).colorScheme.byteLabelColor,fontSize: 14)),
                  
                ],
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Text(
               valueFormatter, // Dynamically format the value
                style:  TextStyle(
                  color: Theme.of(context).colorScheme.byteColor,
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
