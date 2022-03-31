class PostModel {
  final String? id;
  final String? userId;
  final String? title;
  final String? body;

  PostModel({
    this.id,
    this.userId,
    this.title,
    this.body,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
      id: json["id"],
      userId: json["userId"],
      title: json["title"],
      body: json["body"]);

  Map<String, dynamic> toJson() => {
        "id": id,
        "userId": userId,
        "title": title,
        "body": body,
      };
}
