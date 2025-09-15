import 'package:flutter/material.dart';

class Tile {
  final String id;
  final String label;
  final IconData icon;
  final Widget screen;
  bool pinned;
  bool visible;
  int order;

  Tile({
    required this.id,
    required this.label,
    required this.icon,
    required this.screen,
    this.pinned = false,
    this.visible = true,
    required this.order,
  });

  // Convert to Map for saving
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'icon': icon.codePoint,
      'pinned': pinned,
      'visible': visible,
      'order': order,
    };
  }

  // Restore from Map
  factory Tile.fromMap(Map<String, dynamic> map, Widget screen) {
    return Tile(
      id: map['id'],
      label: map['label'],
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      screen: screen,
      pinned: map['pinned'],
      visible: map['visible'],
      order: map['order'],
    );
  }
}