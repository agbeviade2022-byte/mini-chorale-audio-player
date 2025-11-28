enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
}

class DownloadedChant {
  final String chantId;
  final String localPath;
  final DateTime downloadedAt;
  final int fileSize; // En bytes
  final DownloadStatus status;
  final double progress; // 0.0 à 1.0

  DownloadedChant({
    required this.chantId,
    required this.localPath,
    required this.downloadedAt,
    required this.fileSize,
    this.status = DownloadStatus.downloaded,
    this.progress = 1.0,
  });

  // Conversion depuis Map
  factory DownloadedChant.fromMap(Map<String, dynamic> map) {
    return DownloadedChant(
      chantId: map['chant_id'] as String,
      localPath: map['local_path'] as String,
      downloadedAt: DateTime.parse(map['downloaded_at'] as String),
      fileSize: map['file_size'] as int,
      status: DownloadStatus.values[map['status'] as int? ?? 2],
      progress: map['progress'] as double? ?? 1.0,
    );
  }

  // Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'chant_id': chantId,
      'local_path': localPath,
      'downloaded_at': downloadedAt.toIso8601String(),
      'file_size': fileSize,
      'status': status.index,
      'progress': progress,
    };
  }

  // Copie avec modifications
  DownloadedChant copyWith({
    String? chantId,
    String? localPath,
    DateTime? downloadedAt,
    int? fileSize,
    DownloadStatus? status,
    double? progress,
  }) {
    return DownloadedChant(
      chantId: chantId ?? this.chantId,
      localPath: localPath ?? this.localPath,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}
