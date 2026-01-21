// lib/models/event.dart

class Event {
  final int id;
  final String name;
  final String description;
  final String? createdAt;
  final String? deadline;
  final bool deadlinePassed;
  final EventUser creator;
  final List<EventUser> assignedUsers;
  final List<EventTag> tags;
  final EventStatus? status;
  final bool canEdit;
  final bool canArchive;

  Event({
    required this.id,
    required this.name,
    required this.description,
    this.createdAt,
    this.deadline,
    required this.deadlinePassed,
    required this.creator,
    required this.assignedUsers,
    required this.tags,
    this.status,
    required this.canEdit,
    required this.canArchive,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'],
      deadline: json['deadline'],
      deadlinePassed: json['deadline_passed'] ?? false,
      creator: EventUser.fromJson(json['creator'] ?? {}),
      assignedUsers: (json['assigned_users'] as List<dynamic>?)
          ?.map((user) => EventUser.fromJson(user))
          .toList() ?? [],
      tags: (json['tags'] as List<dynamic>?)
          ?.map((tag) => EventTag.fromJson(tag))
          .toList() ?? [],
      status: json['status'] != null ? EventStatus.fromJson(json['status']) : null,
      canEdit: json['can_edit'] ?? false,
      canArchive: json['can_archive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt,
      'deadline': deadline,
      'deadline_passed': deadlinePassed,
      'creator': creator.toJson(),
      'assigned_users': assignedUsers.map((user) => user.toJson()).toList(),
      'tags': tags.map((tag) => tag.toJson()).toList(),
      'status': status?.toJson(),
      'can_edit': canEdit,
      'can_archive': canArchive,
    };
  }
}

class EventUser {
  final int id;
  final String name;

  EventUser({
    required this.id,
    required this.name,
  });

  factory EventUser.fromJson(Map<String, dynamic> json) {
    return EventUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class EventTag {
  final int id;
  final String name;
  final String color;

  EventTag({
    required this.id,
    required this.name,
    required this.color,
  });

  factory EventTag.fromJson(Map<String, dynamic> json) {
    return EventTag(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      color: json['color'] ?? '#666666',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }
}

class EventStatus {
  final int id;
  final String name;

  EventStatus({
    required this.id,
    required this.name,
  });

  factory EventStatus.fromJson(Map<String, dynamic> json) {
    return EventStatus(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
