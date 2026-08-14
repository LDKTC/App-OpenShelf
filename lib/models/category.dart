import 'package:flutter/material.dart';

class BookCategory {
  final int? id;
  final String name;
  final int color;

  const BookCategory({this.id, required this.name, this.color = 0xFF6750A4});

  Color get colorValue => Color(color);

  BookCategory copyWith({int? id, String? name, int? color}) {
    return BookCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
    };
  }

  factory BookCategory.fromMap(Map<String, Object?> map) {
    return BookCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as int? ?? 0xFF6750A4,
    );
  }
}
