import 'package:flutter/material.dart';

class TaskItemHolder extends StatelessWidget {
  final String taskText;
  final VoidCallback? onCameraTap;
  final bool isCompleted;
  final Color? dotColor;
  final Color? textColor;
  final Color? iconColor;

  const TaskItemHolder({
    super.key,
    required this.taskText,
    this.onCameraTap,
    this.isCompleted = false,
    this.dotColor,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor ??
                        (isCompleted ? Colors.green : Colors.grey[400]),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Text(
              taskText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCompleted ? FontWeight.w500 : FontWeight.w400,
                color: textColor ??
                    (isCompleted ? Colors.grey[600] : Colors.black87),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: Colors.grey[400],
                decorationThickness: 2,
              ),
            ),
          ),
          GestureDetector(
            onTap: onCameraTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor ?? Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: iconColor ?? Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 20,
                color: iconColor ?? Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
