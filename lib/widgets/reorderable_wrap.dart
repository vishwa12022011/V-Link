import 'package:flutter/material.dart';

class ReorderableWrap extends StatefulWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final Function(int oldIndex, int newIndex) onReorder;

  const ReorderableWrap({
    super.key, // Updated to modern super parameter syntax
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    required this.onReorder,
  });

  @override
  State<ReorderableWrap> createState() => _ReorderableWrapState();
}

class _ReorderableWrapState extends State<ReorderableWrap> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: widget.spacing,
      runSpacing: widget.runSpacing,
      children: widget.children.asMap().entries.map((entry) {
        return Draggable<int>(
          data: entry.key,
          feedback: Material(
            elevation: 4.0,
            child: entry.value,
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: entry.value,
          ),
          child: DragTarget<int>(
            builder: (BuildContext context, List<int?> candidateData, List<dynamic> rejectedData) {
              return entry.value;
            },
            // Updated to the non-deprecated version
            onWillAcceptWithDetails: (details) {
              return details.data != entry.key;
            },
            // Updated to the non-deprecated version
            onAcceptWithDetails: (details) {
              widget.onReorder(details.data, entry.key);
            },
          ),
        );
      }).toList(),
    );
  }
}