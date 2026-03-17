import 'dart:io';

class BookInfo {
  final String title;
  final String author;
  final File? coverImage;
  final List<String> chapters;
  final String? sourceFilePath;
  final DateTime createdAt;
  String? outputPath;
  ConversionStatus status;

  BookInfo({
    required this.title,
    required this.author,
    this.coverImage,
    required this.chapters,
    this.sourceFilePath,
    DateTime? createdAt,
    this.outputPath,
    this.status = ConversionStatus.pending,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'coverImagePath': coverImage?.path,
      'chapters': chapters,
      'sourceFilePath': sourceFilePath,
      'createdAt': createdAt.toIso8601String(),
      'outputPath': outputPath,
      'status': status.index,
    };
  }

  factory BookInfo.fromJson(Map<String, dynamic> json) {
    return BookInfo(
      title: json['title'] as String,
      author: json['author'] as String,
      coverImage: json['coverImagePath'] != null ? File(json['coverImagePath'] as String) : null,
      chapters: List<String>.from(json['chapters'] as List),
      sourceFilePath: json['sourceFilePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      outputPath: json['outputPath'] as String?,
      status: ConversionStatus.values[json['status'] as int],
    );
  }

  BookInfo copyWith({
    String? title,
    String? author,
    File? coverImage,
    List<String>? chapters,
    String? sourceFilePath,
    DateTime? createdAt,
    String? outputPath,
    ConversionStatus? status,
  }) {
    return BookInfo(
      title: title ?? this.title,
      author: author ?? this.author,
      coverImage: coverImage ?? this.coverImage,
      chapters: chapters ?? this.chapters,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      createdAt: createdAt ?? this.createdAt,
      outputPath: outputPath ?? this.outputPath,
      status: status ?? this.status,
    );
  }
}

enum ConversionStatus {
  pending,
  converting,
  completed,
  failed,
}

enum ChapterDetectionMode {
  auto,
  chinese,
  numbered,
  english,
  customSeparator,
}
