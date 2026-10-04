import '../theme/tokens.dart';

enum Role { dutyManager, supervisor }

extension RoleX on Role {
  String get label => this == Role.dutyManager ? 'Duty Manager' : 'Supervisor';
}

enum AppPage { excellence, tasks, schedule, team, quality, issues, reports, settings, roleMatrix }

extension AppPageX on AppPage {
  String get label {
    switch (this) {
      case AppPage.excellence:
        return 'Excellence Center';
      case AppPage.tasks:
        return 'Tasks';
      case AppPage.schedule:
        return 'Schedule';
      case AppPage.team:
        return 'Team';
      case AppPage.quality:
        return 'Quality';
      case AppPage.issues:
        return 'Issues';
      case AppPage.reports:
        return 'Reports';
      case AppPage.settings:
        return 'Settings';
      case AppPage.roleMatrix:
        return 'Role Matrix';
    }
  }

  String get slug {
    switch (this) {
      case AppPage.excellence:
        return 'excellence-center';
      case AppPage.roleMatrix:
        return 'role-matrix';
      default:
        return name;
    }
  }

  static AppPage? fromSlug(String? s) {
    for (final p in AppPage.values) {
      if (p.slug == s) return p;
    }
    return null;
  }
}

class Account {
  const Account({
    required this.name,
    required this.initials,
    required this.staffId,
    required this.email,
    required this.shift,
    required this.scope,
  });
  final String name, initials, staffId, email, shift, scope;
}

class Ownership {
  const Ownership({this.assignee, this.taskStatus, this.closed = false, this.restored = false, this.reason});
  final String? assignee;
  final String? taskStatus;
  final bool closed;
  final bool restored;
  final String? reason;

  Ownership copyWith({String? assignee, String? taskStatus, bool? closed, bool? restored, String? reason}) =>
      Ownership(
        assignee: assignee ?? this.assignee,
        taskStatus: taskStatus ?? this.taskStatus,
        closed: closed ?? this.closed,
        restored: restored ?? this.restored,
        reason: reason ?? this.reason,
      );

  Map<String, dynamic> toJson() => {
        if (assignee != null) 'assignee': assignee,
        if (taskStatus != null) 'taskStatus': taskStatus,
        if (closed) 'closed': true,
        if (restored) 'restored': true,
        if (reason != null) 'reason': reason,
      };

  factory Ownership.fromJson(Map<String, dynamic> j) => Ownership(
        assignee: j['assignee'] as String?,
        taskStatus: j['taskStatus'] as String?,
        closed: j['closed'] == true,
        restored: j['restored'] == true,
        reason: j['reason'] as String?,
      );
}

class Facility {
  const Facility({
    required this.id,
    required this.type,
    required this.zone,
    required this.status,
    required this.tone,
    required this.x,
    required this.y,
    this.detail,
    this.occupancy,
    this.deviceStatus,
    this.deviceId,
    this.lastEvent,
    this.assigned,
    this.taskStatus,
    this.priority = false,
  });
  final String id, type, zone, status;
  final Tone tone;
  final double x, y;
  final String? detail, occupancy, deviceStatus, deviceId, lastEvent, assigned, taskStatus;
  final bool priority;

  bool get isBin => type == 'Waste Bin';

  Facility copyWith({
    String? status,
    Tone? tone,
    String? detail,
    String? assigned,
    String? taskStatus,
    bool? priority,
  }) =>
      Facility(
        id: id,
        type: type,
        zone: zone,
        status: status ?? this.status,
        tone: tone ?? this.tone,
        x: x,
        y: y,
        detail: detail ?? this.detail,
        occupancy: occupancy,
        deviceStatus: deviceStatus,
        deviceId: deviceId,
        lastEvent: lastEvent,
        assigned: assigned ?? this.assigned,
        taskStatus: taskStatus ?? this.taskStatus,
        priority: priority ?? this.priority,
      );
}

class TeamMember {
  const TeamMember(this.name, this.initials, this.active, this.overdue, this.zone, this.shift, this.fit);
  final String name, initials, zone, shift;
  final int active, overdue;
  final bool fit;
}

class TaskRow {
  const TaskRow(this.id, this.facility, this.location, this.type, this.priority, this.assignee, this.source,
      this.status, this.sla);
  final String id, facility, location, type, priority, assignee, source, status, sla;
}

class DetailRequest {
  const DetailRequest(this.type, this.title);
  final String type;
  final String title;
}
