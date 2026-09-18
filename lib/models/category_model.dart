class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String? image;

  CategoryModel({required this.id, required this.name, this.icon, this.image});

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      icon: map['icon']?.toString(),
      image: map['image']?.toString() ?? map['image_url']?.toString(),
    );
  }
}
