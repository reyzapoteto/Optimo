import '../theme/tokens.dart';
import 'models.dart';

const accounts = <Role, Account>{
  Role.dutyManager: Account(
    name: 'Ahmed Hassan',
    initials: 'AH',
    staffId: 'DM-002',
    email: 'ahmed@optimo.sa',
    shift: '06:00–18:00',
    scope: 'Whole club',
  ),
  Role.supervisor: Account(
    name: 'Khalid Al-Mutairi',
    initials: 'KM',
    staffId: 'SUP-014',
    email: 'khalid@optimo.sa',
    shift: '07:00–15:00',
    scope: 'Changing Rooms & Showers',
  ),
};

Role? roleForStaffId(String id) {
  switch (id.trim().toUpperCase()) {
    case 'DM-002':
      return Role.dutyManager;
    case 'SUP-014':
      return Role.supervisor;
  }
  return null;
}

List<AppPage> navFor(Role role) => [
      AppPage.excellence,
      AppPage.tasks,
      AppPage.schedule,
      AppPage.team,
      AppPage.quality,
      AppPage.issues,
      AppPage.reports,
      if (role == Role.dutyManager) AppPage.settings,
    ];

const initialOwnership = <String, Ownership>{
  'SH-04': Ownership(taskStatus: 'Unassigned'),
  'WC-02': Ownership(assignee: 'Noura Al-Salem', taskStatus: 'In Progress'),
  'BIN-02': Ownership(assignee: 'Yousef Mansour', taskStatus: 'Accepted'),
};

const supervisorTeam = <TeamMember>[
  TeamMember('Noura Al-Salem', 'NS', 2, 0, 'Changing Rooms & Showers', 'On shift', true),
  TeamMember('Yousef Mansour', 'YM', 1, 0, 'Changing Rooms & Showers', 'On shift', true),
  TeamMember('Faisal Al-Qahtani', 'FQ', 1, 1, 'Changing Rooms & Showers', 'On shift', true),
  TeamMember('Sara Al-Dosari', 'SD', 0, 0, 'Functional Training', 'On break', false),
];

const facilities = <Facility>[
  Facility(id: 'SH-01', type: 'Shower', zone: 'Shower Area', status: 'Ready', tone: Tone.ready, x: 22, y: 20,
      occupancy: 'Vacant', deviceStatus: 'Online', deviceId: 'SNS-SH01', lastEvent: 'Service completed · 10:42 AM'),
  Facility(id: 'SH-02', type: 'Shower', zone: 'Shower Area', status: 'Ready', tone: Tone.ready, x: 30, y: 20,
      occupancy: 'Occupied', deviceStatus: 'Online', deviceId: 'SNS-SH02', lastEvent: 'Occupied · 11:06 AM'),
  Facility(id: 'SH-03', type: 'Shower', zone: 'Shower Area', status: 'Ready', tone: Tone.ready, x: 38, y: 21,
      occupancy: 'Vacant', deviceStatus: 'Online', deviceId: 'SNS-SH03', lastEvent: 'Vacant · 11:07 AM'),
  Facility(id: 'SH-04', type: 'Shower', zone: 'Changing Area A', status: 'Service Required', tone: Tone.attention,
      x: 46, y: 21, detail: 'Open for 01:32', occupancy: 'Vacant', deviceStatus: 'Online', deviceId: 'SNS-SH04',
      assigned: 'Rami Hassan', taskStatus: 'Accepted', priority: true, lastEvent: 'Usage completed · 11:08 AM'),
  Facility(id: 'WC-01', type: 'Toilet', zone: 'Toilet Area', status: 'Ready', tone: Tone.ready, x: 78, y: 34,
      occupancy: 'Vacant', deviceStatus: 'Online', deviceId: 'SNS-WC01', lastEvent: 'Vacant · 11:04 AM'),
  Facility(id: 'WC-02', type: 'Toilet', zone: 'Toilet Area', status: 'Cleaning', tone: Tone.cleaning, x: 85, y: 35,
      detail: 'Open for 03:20', occupancy: 'Vacant', deviceStatus: 'Delayed', deviceId: 'SNS-WC02',
      assigned: 'Omar Khalid', taskStatus: 'In Progress', priority: true, lastEvent: 'Cleaning started · 11:02 AM'),
  Facility(id: 'WC-03', type: 'Toilet', zone: 'Toilet Area', status: 'Ready', tone: Tone.ready, x: 92, y: 37,
      occupancy: 'Unknown', deviceStatus: 'Offline', deviceId: 'SNS-WC03', lastEvent: 'Signal lost · 10:54 AM'),
  Facility(id: 'BIN-01', type: 'Waste Bin', zone: 'Vanity Area', status: 'Ready', tone: Tone.ready, x: 15, y: 27,
      deviceStatus: 'Online', deviceId: 'SNS-BIN01', lastEvent: 'Fill level 34% · 11:07 AM'),
  Facility(id: 'BIN-02', type: 'Waste Bin', zone: 'Vanity Area', status: '85% Full', tone: Tone.attention, x: 70,
      y: 44, detail: 'Approaching threshold', deviceStatus: 'Online', deviceId: 'SNS-BIN02', assigned: 'Sara Ali',
      taskStatus: 'New', priority: true, lastEvent: 'Fill level reached 85% · 10:56 AM'),
];

Facility? facilityById(String id) {
  for (final f in facilities) {
    if (f.id == id) return f;
  }
  return null;
}

Facility resolveFacility(Facility f, Map<String, Ownership> ownership) {
  var out = f;
  final own = ownership[f.id];
  if (own != null) {
    out = Facility(
      id: f.id,
      type: f.type,
      zone: f.zone,
      status: f.status,
      tone: f.tone,
      x: f.x,
      y: f.y,
      detail: f.detail,
      occupancy: f.occupancy,
      deviceStatus: f.deviceStatus,
      deviceId: f.deviceId,
      lastEvent: f.lastEvent,
      assigned: own.assignee,
      taskStatus: own.taskStatus ?? f.taskStatus,
      priority: f.priority,
    );
    if (own.closed) {
      out = out.copyWith(status: 'Out of Service', tone: Tone.critical, detail: own.reason, priority: true);
    } else if (own.restored) {
      out = out.copyWith(status: 'Service Required', tone: Tone.attention, detail: 'Restored · awaiting inspection');
    }
  }
  if (out.deviceStatus == 'Offline' && out.status == 'Ready') {
    out = out.copyWith(status: 'Unverified · Device offline', tone: Tone.muted, detail: 'Stale reading');
  }
  return out;
}

const taskRows = <TaskRow>[
  TaskRow('TSK-1048', 'SH-04', 'Changing Area A', 'Clean shower', 'Urgent', 'Rami Hassan', 'Sensor', 'Accepted', '06:30'),
  TaskRow('TSK-1047', 'WC-02', 'Toilet Area', 'Routine cleaning', 'High', 'Omar Khalid', 'Threshold', 'In Progress', '12 min'),
  TaskRow('TSK-1046', 'BIN-02', 'Vanity Area', 'Empty waste bin', 'Medium', 'Sara Ali', 'Sensor', 'New', '18 min'),
  TaskRow('TSK-1045', 'SH-07', 'Changing Room B', 'Post-use service', 'Medium', 'Sara Omar', 'Sensor', 'Accepted', '46 min'),
  TaskRow('TSK-1044', 'PL-03', 'Pool', 'Replenish towels', 'Low', 'N. Faisal', 'Manual', 'Completed', 'Met'),
  TaskRow('TSK-1043', 'TC-08', 'Personal Training', 'Inspect cubicle', 'Low', 'N. Faisal', 'Schedule', 'Completed', 'Met'),
  TaskRow('TSK-1042', 'WB-06', 'Lounge', 'Empty waste bin', 'Medium', 'Sara Omar', 'Sensor', 'Blocked', 'Breached'),
  TaskRow('TSK-1041', 'SH-01', 'Shower Area', 'Post-use service', 'Medium', 'Ahmed Hassan', 'Manual', 'Canceled', '—'),
];

const pageDescriptions = <AppPage, String>{
  AppPage.tasks: 'Assign, monitor and resolve operational service work.',
  AppPage.schedule: 'Plan recurring and routine hospitality operations.',
  AppPage.team: 'Balance on-shift capacity and assigned operational work.',
  AppPage.quality: 'Maintain club standards through inspections and rework.',
  AppPage.issues: 'Track facility faults and operational blockers to resolution.',
  AppPage.reports: 'Review service performance and recurring operational patterns.',
  AppPage.settings: 'Configure locations, devices, service rules and access.',
  AppPage.roleMatrix: 'What each role can see and do. Source of truth for every screen.',
};

String taskIdFor(String facilityId) {
  if (facilityId == 'WC-02') return 'TSK-1047';
  if (facilityId == 'BIN-02') return 'TSK-1046';
  return 'TSK-1048';
}
