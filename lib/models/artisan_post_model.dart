class ArtisanPostModel {
  final String id;
  final String artisanId;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? createdAt;

  ArtisanPostModel({
    required this.id,
    required this.artisanId,
    this.title,
    this.description,
    this.imageUrl,
    this.createdAt,
  });

  factory ArtisanPostModel.fromMap(Map<String, dynamic> map) {
    return ArtisanPostModel(
      id: map['id']?.toString() ?? '',
      artisanId: map['artisanId']?.toString() ?? map['artisan_id']?.toString() ?? '',
      title: map['title']?.toString(),
      description: map['description']?.toString(),
      imageUrl: map['imageUrl']?.toString() ?? map['image_url']?.toString(),
      createdAt: map['createdAt']?.toString() ?? map['created_at']?.toString(),
    );
  }
}
