import 'package:flutter/material.dart';

enum TicketStatus { open, inProgress, resolved, closed, cancelled }

extension TicketStatusExtension on TicketStatus {
  String get displayName {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
      case TicketStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case TicketStatus.open:
        return const Color(0xFF3B82F6); // Blue
      case TicketStatus.inProgress:
        return const Color(0xFFF59E0B); // Orange
      case TicketStatus.resolved:
        return const Color(0xFF10B981); // Green
      case TicketStatus.closed:
        return const Color(0xFF6B7280); // Gray
      case TicketStatus.cancelled:
        return const Color(0xFFEF4444); // Red
    }
  }

  static TicketStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return TicketStatus.open;
      case 'in progress':
      case 'inprogress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      case 'cancelled':
        return TicketStatus.cancelled;
      default:
        return TicketStatus.open;
    }
  }
}

enum TicketPriority { low, medium, high, critical }

extension TicketPriorityExtension on TicketPriority {
  String get displayName {
    switch (this) {
      case TicketPriority.low:
        return 'Low';
      case TicketPriority.medium:
        return 'Medium';
      case TicketPriority.high:
        return 'High';
      case TicketPriority.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case TicketPriority.low:
        return const Color(0xFF10B981); // Green
      case TicketPriority.medium:
        return const Color(0xFF3B82F6); // Blue
      case TicketPriority.high:
        return const Color(0xFFF59E0B); // Orange
      case TicketPriority.critical:
        return const Color(0xFFEF4444); // Red
    }
  }

  static TicketPriority fromString(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return TicketPriority.low;
      case 'medium':
        return TicketPriority.medium;
      case 'high':
        return TicketPriority.high;
      case 'critical':
        return TicketPriority.critical;
      default:
        return TicketPriority.medium;
    }
  }
}

enum TicketCategory {
  technical,
  maintenance,
  installation,
  configuration,
  support,
  general,
}

extension TicketCategoryExtension on TicketCategory {
  String get displayName {
    switch (this) {
      case TicketCategory.technical:
        return 'Technical';
      case TicketCategory.maintenance:
        return 'Maintenance';
      case TicketCategory.installation:
        return 'Installation';
      case TicketCategory.configuration:
        return 'Configuration';
      case TicketCategory.support:
        return 'Support';
      case TicketCategory.general:
        return 'General';
    }
  }

  IconData get icon {
    switch (this) {
      case TicketCategory.technical:
        return Icons.build_circle;
      case TicketCategory.maintenance:
        return Icons.settings;
      case TicketCategory.installation:
        return Icons.construction;
      case TicketCategory.configuration:
        return Icons.tune;
      case TicketCategory.support:
        return Icons.support_agent;
      case TicketCategory.general:
        return Icons.help;
    }
  }

  static TicketCategory fromString(String category) {
    switch (category.toLowerCase()) {
      case 'technical':
        return TicketCategory.technical;
      case 'maintenance':
        return TicketCategory.maintenance;
      case 'installation':
        return TicketCategory.installation;
      case 'configuration':
        return TicketCategory.configuration;
      case 'support':
        return TicketCategory.support;
      case 'general':
        return TicketCategory.general;
      default:
        return TicketCategory.general;
    }
  }
}

class Ticket {
  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final TicketCategory category;
  final String assignedTo;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final DateTime? resolvedAt;
  final String? deviceId;
  final String? deviceName;
  final List<String> tags;
  final List<TicketComment> comments;
  final List<TicketAttachment> attachments;

  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.assignedTo,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.resolvedAt,
    this.deviceId,
    this.deviceName,
    this.tags = const [],
    this.comments = const [],
    this.attachments = const [],
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: TicketStatusExtension.fromString(json['status'] ?? 'open'),
      priority: TicketPriorityExtension.fromString(
        json['priority'] ?? 'medium',
      ),
      category: TicketCategoryExtension.fromString(
        json['category'] ?? 'general',
      ),
      assignedTo: json['assignedTo'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : null,
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      tags: List<String>.from(json['tags'] ?? []),
      comments: (json['comments'] as List? ?? [])
          .map((comment) => TicketComment.fromJson(comment))
          .toList(),
      attachments: (json['attachments'] as List? ?? [])
          .map((attachment) => TicketAttachment.fromJson(attachment))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.displayName,
      'priority': priority.displayName,
      'category': category.displayName,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'deviceId': deviceId,
      'deviceName': deviceName,
      'tags': tags,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'attachments': attachments
          .map((attachment) => attachment.toJson())
          .toList(),
    };
  }

  Ticket copyWith({
    String? id,
    String? title,
    String? description,
    TicketStatus? status,
    TicketPriority? priority,
    TicketCategory? category,
    String? assignedTo,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    DateTime? resolvedAt,
    String? deviceId,
    String? deviceName,
    List<String>? tags,
    List<TicketComment>? comments,
    List<TicketAttachment>? attachments,
  }) {
    return Ticket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      tags: tags ?? this.tags,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
    );
  }

  String get formattedCreatedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get formattedDueDate {
    if (dueDate == null) return 'No due date';
    return '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}';
  }

  Duration? get timeToResolve {
    if (resolvedAt == null) return null;
    return resolvedAt!.difference(createdAt);
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == TicketStatus.resolved || status == TicketStatus.closed) {
      return false;
    }
    return DateTime.now().isAfter(dueDate!);
  }

  String get overdueDays {
    if (!isOverdue) return '';
    final days = DateTime.now().difference(dueDate!).inDays;
    return '$days day${days > 1 ? 's' : ''} overdue';
  }
}

class TicketComment {
  final String id;
  final String ticketId;
  final String author;
  final String content;
  final DateTime createdAt;
  final bool isInternal;

  const TicketComment({
    required this.id,
    required this.ticketId,
    required this.author,
    required this.content,
    required this.createdAt,
    this.isInternal = false,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    return TicketComment(
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      author: json['author'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isInternal: json['isInternal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'author': author,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isInternal': isInternal,
    };
  }
}

class TicketAttachment {
  final String id;
  final String ticketId;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final String uploadedBy;
  final DateTime uploadedAt;

  const TicketAttachment({
    required this.id,
    required this.ticketId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory TicketAttachment.fromJson(Map<String, dynamic> json) {
    return TicketAttachment(
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      fileName: json['fileName'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      uploadedBy: json['uploadedBy'] ?? '',
      uploadedAt: DateTime.parse(
        json['uploadedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
