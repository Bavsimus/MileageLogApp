import '../models/database_helper.dart';

class GuzergahModel {
  final int id;
  final String name;

  GuzergahModel({required this.id, required this.name});

  factory GuzergahModel.fromMap(Map<String, dynamic> map) {
    return GuzergahModel(
      id: map[DatabaseHelper.columnId], // DÜZELTİLDİ
      name: map[DatabaseHelper.columnGuzergahName],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnId: id, // DÜZELTİLDİ
      DatabaseHelper.columnGuzergahName: name,
    };
  }
}