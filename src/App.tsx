import { useEffect, useMemo, useRef, useState } from "react"
import exterior from "./assets/optimo-exterior.png"
import digitalTwin from "./assets/optimo-digital-twin-isolated.png"

type Page = "Excellence Center" | "Tasks" | "Schedule" | "Team" | "Quality" | "Issues" | "Reports" | "Settings"
type Tone = "ready" | "attention" | "critical" | "cleaning" | "muted"
type Language = "en" | "ar"
type OperationalContext = { club: string; level: string; zone: string }

const arabicCopy: Record<string, string> = {
  "Excellence Center": "مركز التميز التشغيلي",
  Tasks: "المهام",
  Schedule: "الجدول التشغيلي",
  Team: "الفريق",
  Quality: "الجودة",
  Issues: "المشكلات",
  Reports: "التقارير",
  Settings: "الإعدادات",
  "Hospitality Excellence Center": "مركز التميز للضيافة",
  "Live facility operations across the club.":
    "عمليات المرافق المباشرة في جميع أنحاء النادي.",
  "LIVE OPERATIONS": "عمليات مباشرة",
  "UPDATED NOW": "تم التحديث الآن",
  "Main Club": "النادي الرئيسي",
  "All Clubs": "جميع الأندية",
  "All Zones": "جميع المناطق",
  CLUB: "النادي",
  VIEW: "العرض",
  "Duty Manager": "مدير المناوبة",
  "MAIN CLUB": "النادي الرئيسي",
  "42 devices online": "42 جهازاً متصلاً",
  "Riyadh · All systems normal": "الرياض · جميع الأنظمة تعمل",
  "Operational Readiness": "الجاهزية التشغيلية",
  "Response Performance": "أداء الاستجابة",
  "Active Workload": "المهام النشطة",
  "Live Club Operations": "العمليات المباشرة للنادي",
  "Needs Attention": "يتطلب الانتباه",
  "Live Activity": "النشاط المباشر",
  "Open task board": "فتح لوحة المهام",
  "CLUB STANDARD": "معيار النادي",
  "SERVICE STANDARD": "معيار الخدمة",
  "RIGHT NOW": "الآن",
  READY: "جاهز",
  "WITHIN TARGET": "ضمن الهدف",
  "42 monitored": "42 تحت المراقبة",
  monitored: "تحت المراقبة",
  "need attention": "تتطلب الاهتمام",
  "Across 4 operational zones": "في 4 مناطق تشغيلية",
  New: "جديدة",
  "In Progress": "قيد التنفيذ",
  Blocked: "متوقفة",
  Live: "مباشر",
  "Select a facility to investigate service state.":
    "اختر مرفقاً لعرض حالة الخدمة.",
  "SPATIAL STATUS": "الحالة المكانية",
  LEVEL: "الطابق",
  FACILITY: "المرفق",
  All: "الكل",
  Showers: "الاستحمام",
  Toilets: "دورات المياه",
  "Waste Bins": "سلال النفايات",
  "Showing facilities requiring attention": "عرض المرافق التي تتطلب الاهتمام",
  "Clear filter": "مسح التصفية",
  Ready: "جاهز",
  Attention: "تنبيه",
  Critical: "حرج",
  Cleaning: "قيد التنظيف",
  "Out of Service": "خارج الخدمة",
  "SELECTED FACILITY": "المرفق المحدد",
  "Service Required": "الخدمة مطلوبة",
  Vacant: "شاغر",
  Device: "الجهاز",
  Online: "متصل",
  "Open for": "مفتوح منذ",
  SLA: "مستوى الخدمة",
  Assigned: "المسؤول",
  "28 min remaining": "متبقي 28 دقيقة",
  "SLA Approaching": "الوقت المستهدف أوشك على التجاوز",
  "SLA Breached": "تجاوز الوقت المستهدف",
  "Open Task": "فتح المهمة",
  "View Service History": "عرض سجل الخدمة",
  "DECISION QUEUE": "قائمة القرارات",
  "Prioritized by urgency and service impact.":
    "مرتبة حسب الاستعجال وتأثير الخدمة.",
  "View all exceptions": "عرض جميع الحالات",
  "Average response": "متوسط الاستجابة",
  "12% faster than target": "أسرع من الهدف بنسبة 12%",
  "View all activity": "عرض كل النشاط",
  "Open tasks": "المهام المفتوحة",
  "Within response SLA": "ضمن هدف الاستجابة",
  "Avg. completion": "متوسط الإنجاز",
  Search: "بحث",
  Filters: "التصفية",
  "Create Manual Task": "إنشاء مهمة يدوية",
  "Task ID": "رقم المهمة",
  Location: "الموقع",
  Type: "النوع",
  Priority: "الأولوية",
  Assignee: "المسؤول",
  Source: "المصدر",
  Status: "الحالة",
  Previous: "السابق",
  Next: "التالي",
  Today: "اليوم",
  "Schedule Work": "جدولة عمل",
  "Manage Shift": "إدارة المناوبة",
  Employee: "الموظف",
  "Assigned zone": "المنطقة المسندة",
  "Current work": "العمل الحالي",
  Completed: "مكتملة",
  "Quality standards": "معايير الجودة",
  "Start Inspection": "بدء فحص",
  "Report Issue": "رفع بلاغ",
  "Last 30 days": "آخر 30 يوماً",
  "Export report": "تصدير التقرير",
  CONFIGURATION: "التهيئة",
  Active: "نشط",
  "Welcome back": "مرحباً بعودتك",
  "Sign in to access club operations.": "سجّل الدخول للوصول إلى عمليات النادي.",
  Email: "البريد الإلكتروني",
  Password: "كلمة المرور",
  Show: "إظهار",
  Hide: "إخفاء",
  "Remember me": "تذكرني",
  "Forgot Password?": "نسيت كلمة المرور؟",
  "Sign In": "تسجيل الدخول",
  "Signing In": "جارٍ تسجيل الدخول",
  "Recover access": "استعادة الوصول",
  "Enter your work email and we’ll send a secure recovery link.":
    "أدخل بريد العمل وسنرسل لك رابط استعادة آمن.",
  "Send recovery link": "إرسال رابط الاستعادة",
  "Back to sign in": "العودة لتسجيل الدخول",
  "Check your inbox": "تحقق من بريدك",
  "A recovery link has been sent to your work email.":
    "تم إرسال رابط الاستعادة إلى بريد العمل.",
  Notifications: "الإشعارات",
  "Mark all as read": "تحديد الكل كمقروء",
  "View all notifications": "عرض جميع الإشعارات",
  Profile: "الملف الشخصي",
  Language: "اللغة",
  "Sign Out": "تسجيل الخروج",
  "My Profile": "ملفي الشخصي",
  Preferences: "التفضيلات",
  "Edit Profile": "تعديل الملف",
  "Save Changes": "حفظ التغييرات",
  Cancel: "إلغاء",
  Saved: "تم الحفظ",
  "Changes saved successfully.": "تم حفظ التغييرات بنجاح.",
  "Preferred Language": "اللغة المفضلة",
  "Notification Preferences": "تفضيلات الإشعارات",
  "Operational alerts": "التنبيهات التشغيلية",
  "Shift updates": "تحديثات المناوبات",
  "Current Shift": "المناوبة الحالية",
  "Upcoming Shifts": "المناوبات القادمة",
  Shifts: "المناوبات",
  "Create Shift": "إنشاء مناوبة",
  "Save Shift": "حفظ المناوبة",
  "Shift updated": "تم تحديث المناوبة",
  "Change Assignment": "تغيير التكليف",
  "Assign employee": "تعيين موظف",
  "All tasks": "جميع المهام",
  Accepted: "مقبولة",
  Canceled: "ملغاة",
  "Complete Task": "إكمال المهمة",
  "Accept Task": "قبول المهمة",
  "Start Task": "بدء المهمة",
  "Resolve Block": "معالجة العائق",
  Reassign: "إعادة التعيين",
  "View History": "عرض السجل",
  Investigating: "قيد المعالجة",
  Resolved: "تم الحل",
  "Create Task": "إنشاء مهمة",
  "Mark as Read": "تحديد كمقروء",
  Unread: "غير مقروء",
  "All notifications": "جميع الإشعارات",
  "Facilities & Devices": "المرافق والأجهزة",
  "Roles & Permissions": "الأدوار والصلاحيات",
  "Operational Thresholds": "الحدود التشغيلية",
  "Notifications & Alerts": "الإشعارات والتنبيهات",
  "Standard Operating Procedures": "إجراءات التشغيل القياسية",
  "Language & Localization": "اللغة والتوطين",
  "Device ID": "معرّف الجهاز",
  Connectivity: "الاتصال",
  Delayed: "متأخر",
  Offline: "غير متصل",
  "Last update": "آخر تحديث",
  "Device Offline": "الجهاز غير متصل",
  "Monitoring may be affected.": "قد تتأثر مراقبة المرفق.",
  "No search results": "لا توجد نتائج",
  "Clear search": "مسح البحث",
  "All Clear": "كل شيء يعمل بشكل طبيعي",
  "No tasks require attention.": "لا توجد مهام تتطلب الانتباه.",
  "Connection Error": "تعذر الاتصال",
  Retry: "إعادة المحاولة",
  "Permission Restricted": "الصلاحية غير متاحة",
  Day: "يوم",
  Week: "أسبوع",
  "Edit Schedule": "تعديل الجدول",
  "Create Corrective Task": "إنشاء مهمة تصحيحية",
  "Resolve Issue": "حل المشكلة",
  "Export ready": "التقرير جاهز للتصدير",
  "HOSPITALITY EXCELLENCE CENTER": "مركز التميز التشغيلي للضيافة",
  "Secure operational access": "دخول تشغيلي آمن",
  "Protected for authorized OPTIMO personnel.": "مخصص لموظفي أوبتيمو المخولين.",
  "ACCOUNT RECOVERY": "استعادة الحساب",
  "RECOVERY SENT": "تم إرسال رابط الاستعادة",
  "OPTIMO internal operations · Authorized access only":
    "نظام أوبتيمو التشغيلي · للمخولين فقط",
  "RIYADH · MAIN CLUB": "الرياض · النادي الرئيسي",
  "Physical excellence, translated into operational intelligence.":
    "تميّز المكان، مدعوم بذكاء تشغيلي.",
  Name: "الاسم",
  ACCOUNT: "الحساب",
  "Main Club · Riyadh": "النادي الرئيسي · الرياض",
  "All systems normal": "جميع الأنظمة تعمل بشكل طبيعي",
  "Readiness filter": "تصفية الجاهزية",
  "FACILITIES VISIBLE": "مرافق ظاهرة",
  "Changing Rooms": "غرف تبديل الملابس",
  "Changing Room A": "غرفة تبديل الملابس أ",
  "Changing Room B": "غرفة تبديل الملابس ب",
  Pool: "المسبح",
  "Functional Training": "التدريب الوظيفي",
  "Personal Training": "التدريب الشخصي",
  Lounge: "الاستراحة",
  Shower: "دُش",
  Toilet: "دورة مياه",
  "Waste Bin": "سلة نفايات",
  "Cleaning Required": "التنظيف مطلوب",
  "82% Full": "ممتلئة بنسبة 82%",
  "Approaching threshold": "تقترب من الحد التشغيلي",
  "SERVICE HISTORY": "سجل الخدمة",
  "ASSOCIATED DEVICE": "الجهاز المرتبط",
  "Device type": "نوع الجهاز",
  "Connected facility": "المرفق المرتبط",
  "Last event": "آخر حدث",
  "Last service": "آخر خدمة",
  "Back to Facility": "العودة إلى المرفق",
  "Recent service": "الخدمات الأخيرة",
  "Service completed": "اكتملت الخدمة",
  "Routine cleaning": "تنظيف دوري",
  "Inspection passed": "تم اجتياز الفحص",
  "Show recent activity": "عرض أحدث الأنشطة",
  "Service requested": "تم طلب الخدمة",
  "Reached 82% fill": "بلغت نسبة الامتلاء 82%",
  "Cleaning accepted": "تم قبول مهمة التنظيف",
  "Assign, monitor and resolve operational service work.":
    "إدارة مهام الخدمة ومتابعتها حتى الإنجاز.",
  "Plan recurring and routine hospitality operations.":
    "تخطيط الأعمال التشغيلية الدورية للضيافة.",
  "Balance on-shift capacity and assigned operational work.":
    "إدارة طاقة فريق المناوبة وتوزيع المهام.",
  "Maintain club standards through inspections and rework.":
    "الحفاظ على معايير النادي عبر الفحوصات والإجراءات التصحيحية.",
  "Track facility faults and operational blockers to resolution.":
    "متابعة أعطال المرافق والعوائق التشغيلية حتى معالجتها.",
  "Review service performance and recurring operational patterns.":
    "مراجعة أداء الخدمة والأنماط التشغيلية المتكررة.",
  "Configure locations, devices, service rules and access.":
    "إدارة المواقع والأجهزة وقواعد الخدمة والصلاحيات.",
  "Open Tasks": "المهام المفتوحة",
  "All Priorities": "جميع الأولويات",
  "All Statuses": "جميع الحالات",
  "Clear Filters": "مسح عوامل التصفية",
  Urgent: "عاجلة",
  High: "عالية",
  Medium: "متوسطة",
  Low: "منخفضة",
  "Routine Cleaning": "تنظيف دوري",
  Replenishment: "إعادة تزويد",
  "Deep Cleaning": "تنظيف شامل",
  "Operational schedule": "الجدول التشغيلي",
  "Schedule coverage": "تغطية الجدول",
  Scheduled: "مجدولة",
  Remaining: "متبقية",
  "Current Team": "الفريق الحالي",
  Available: "متاح",
  "On Task": "ينفذ مهمة",
  "On task": "ينفذ مهمة",
  "On shift": "في المناوبة",
  "Active tasks": "المهام النشطة",
  Overdue: "متأخرة",
  "Morning Operations": "العمليات الصباحية",
  "Evening Hospitality": "ضيافة الفترة المسائية",
  "Night Deep Clean": "التنظيف الشامل الليلي",
  "SHIFT MANAGEMENT": "إدارة المناوبات",
  "Shift Name *": "اسم المناوبة *",
  "Start Time *": "وقت البدء *",
  "End Time *": "وقت الانتهاء *",
  "Zone Assignment *": "المنطقة المكلف بها *",
  "Operational Notes": "ملاحظات تشغيلية",
  "Availability conflict": "تعارض في التوفر",
  "Inspection pass rate": "نسبة اجتياز الفحوصات",
  "Rework required": "يتطلب إجراءً تصحيحياً",
  Passed: "مجتاز",
  Rework: "إجراء تصحيحي",
  Pending: "قيد الانتظار",
  Leakage: "تسرّب",
  "Damaged fitting": "تجهيز تالف",
  "Missing supplies": "نقص في المستلزمات",
  "Facility fault": "عطل في المرفق",
  "Facilities Team": "فريق المرافق",
  "SLA performance": "الالتزام بالوقت المستهدف",
  "Tasks completed": "المهام المكتملة",
  "Facility downtime": "مدة توقف المرافق",
  "Service standard": "معيار الخدمة",
  "Last 7 days": "آخر 7 أيام",
  "This quarter": "هذا الربع",
  "All Facilities": "جميع المرافق",
  "Locations & Zones": "المواقع والمناطق",
  Users: "المستخدمون",
  "SLA Rules": "قواعد الوقت المستهدف",
  "Add Locations": "إضافة موقع",
  "Waste Bin Service Threshold": "حد خدمة سلال النفايات",
  "Toilet Usage Threshold": "حد استخدام دورات المياه",
  "Create Related Issue": "إنشاء مشكلة مرتبطة",
  "Settings Detail": "تفاصيل الإعداد",
  "Device Detail": "تفاصيل الجهاز",
  "OPTIMO Live Digital Twin": "التوأم الرقمي المباشر لأوبتيمو",
  "LIVE SPATIAL OPERATIONS": "العمليات المكانية المباشرة",
  "Service Status": "حالة الخدمة",
  Occupancy: "الإشغال",
  "Bin Levels": "مستويات السلال",
  Devices: "الأجهزة",
  "VIEW MODE": "نمط العرض",
  "Locate facility": "تحديد موقع مرفق",
  "No facility found": "لم يتم العثور على المرفق",
  "Ground Floor": "الدور الأرضي",
  "Changing Area A": "منطقة تبديل الملابس أ",
  "Washroom / Changing Area": "دورات المياه / تبديل الملابس",
  "Live operations for the Washroom / Changing Area.": "العمليات المباشرة لمنطقة دورات المياه وتبديل الملابس.",
  "WASHROOM STANDARD": "معيار منطقة دورات المياه",
  "WASHROOM SERVICE": "خدمة منطقة دورات المياه",
  "WASHROOM · RIGHT NOW": "منطقة دورات المياه · الآن",
  "Shower Area": "منطقة الاستحمام",
  "Toilet Area": "منطقة دورات المياه",
  "Vanity Area": "منطقة المغاسل",
  "Locker Area": "منطقة الخزائن",
  "Elevated cutaway": "منظور معماري مرتفع",
  "Latest Event": "آخر حدث",
  "Assigned To": "مسندة إلى",
  "Linked Task": "المهمة المرتبطة",
  "Task Status": "حالة المهمة",
  Response: "الاستجابة",
  Completion: "الإنجاز",
  "View Device": "عرض الجهاز",
  "Locate in Digital Twin": "تحديد الموقع في التوأم الرقمي",
  "Fill level": "مستوى الامتلاء",
  "85% Full": "ممتلئة بنسبة 85%",
  "Service threshold approaching": "تقترب من حد الخدمة",
  "Cleaning task created": "تم إنشاء مهمة تنظيف",
  "Task Detail": "تفاصيل المهمة",
  "Schedule Detail": "تفاصيل الجدول",
  "Team Member": "عضو الفريق",
  "Inspection Detail": "تفاصيل الفحص",
  "Issue Detail": "تفاصيل البلاغ",
  Close: "إغلاق",
}

type Facility = {
  id: string
  type: "Shower" | "Toilet" | "Waste Bin"
  zone: string
  status: string
  tone: Tone
  level: string
  x: number
  y: number
  detail?: string
  occupancy?: "Vacant" | "Occupied" | "Unknown"
  deviceStatus?: "Online" | "Delayed" | "Offline"
  deviceId?: string
  assigned?: string
  taskStatus?: string
  priority?: boolean
  lastEvent?: string
}

const navItems: Page[] = [
  "Excellence Center",
  "Tasks",
  "Schedule",
  "Team",
  "Quality",
  "Issues",
  "Reports",
  "Settings",
]

const facilities: Facility[] = [
  {
    id: "SH-01",
    type: "Shower",
    zone: "Shower Area",
    status: "Ready",
    tone: "ready",
    level: "Ground Floor",
    x: 22,
    y: 20,
    occupancy: "Vacant",
    deviceStatus: "Online",
    deviceId: "SNS-SH01",
    lastEvent: "Service completed · 10:42 AM",
  },
  {
    id: "SH-02",
    type: "Shower",
    zone: "Shower Area",
    status: "Ready",
    tone: "ready",
    level: "Ground Floor",
    x: 30,
    y: 20,
    occupancy: "Occupied",
    deviceStatus: "Online",
    deviceId: "SNS-SH02",
    lastEvent: "Occupied · 11:06 AM",
  },
  {
    id: "SH-03",
    type: "Shower",
    zone: "Shower Area",
    status: "Ready",
    tone: "ready",
    level: "Ground Floor",
    x: 38,
    y: 21,
    occupancy: "Vacant",
    deviceStatus: "Online",
    deviceId: "SNS-SH03",
    lastEvent: "Vacant · 11:07 AM",
  },
  {
    id: "SH-04",
    type: "Shower",
    zone: "Changing Area A",
    status: "Service Required",
    tone: "attention",
    level: "Ground Floor",
    x: 46,
    y: 21,
    detail: "Open for 01:32",
    occupancy: "Vacant",
    deviceStatus: "Online",
    deviceId: "SNS-SH04",
    assigned: "Rami Hassan",
    taskStatus: "Accepted",
    priority: true,
    lastEvent: "Usage completed · 11:08 AM",
  },
  {
    id: "WC-01",
    type: "Toilet",
    zone: "Toilet Area",
    status: "Ready",
    tone: "ready",
    level: "Ground Floor",
    x: 78,
    y: 34,
    occupancy: "Vacant",
    deviceStatus: "Online",
    deviceId: "SNS-WC01",
    lastEvent: "Vacant · 11:04 AM",
  },
  {
    id: "WC-02",
    type: "Toilet",
    zone: "Toilet Area",
    status: "Cleaning",
    tone: "cleaning",
    level: "Ground Floor",
    x: 85,
    y: 35,
    detail: "Open for 03:20",
    occupancy: "Vacant",
    deviceStatus: "Delayed",
    deviceId: "SNS-WC02",
    assigned: "Omar Khalid",
    taskStatus: "In Progress",
    priority: true,
    lastEvent: "Cleaning started · 11:02 AM",
  },
  {
    id: "WC-03",
    type: "Toilet",
    zone: "Toilet Area",
    status: "Ready",
    tone: "ready",
    level: "Ground Floor",
    x: 92,
    y: 37,
    occupancy: "Unknown",
    deviceStatus: "Offline",
    deviceId: "SNS-WC03",
    lastEvent: "Signal lost · 10:54 AM",
  },
  {
    id: "BIN-01",
    type: "Waste Bin",
    zone: "Vanity Area",
    status: "Ready",
    tone: "ready",
    level: "Ground Floor",
    x: 15,
    y: 27,
    deviceStatus: "Online",
    deviceId: "SNS-BIN01",
    lastEvent: "Fill level 34% · 11:07 AM",
  },
  {
    id: "BIN-02",
    type: "Waste Bin",
    zone: "Vanity Area",
    status: "85% Full",
    tone: "attention",
    level: "Ground Floor",
    x: 70,
    y: 44,
    detail: "Approaching threshold",
    deviceStatus: "Online",
    deviceId: "SNS-BIN02",
    assigned: "Sara Ali",
    taskStatus: "New",
    priority: true,
    lastEvent: "Fill level reached 85% · 10:56 AM",
  },
]

const Icon = ({ name, size = 18 }: { name: string; size?: number }) => {
  const paths: Record<string, React.ReactNode> = {
    "Excellence Center": (
      <>
        <path d="M4 12h4l2-5 4 10 2-5h4" />
        <path d="M4 4h16v16H4z" />
      </>
    ),
    Tasks: (
      <>
        <path d="M9 6h11M9 12h11M9 18h11" />
        <path d="m4 6 1 1 2-2m-3 7 1 1 2-2m-3 7 1 1 2-2" />
      </>
    ),
    Schedule: (
      <>
        <rect x="3" y="5" width="18" height="16" rx="2" />
        <path d="M16 3v4M8 3v4M3 10h18" />
      </>
    ),
    Team: (
      <>
        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
        <circle cx="9" cy="7" r="4" />
        <path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" />
      </>
    ),
    Quality: (
      <>
        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10" />
        <path d="m9 12 2 2 4-4" />
      </>
    ),
    Issues: (
      <>
        <path d="M10.3 2.9 1.8 17a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 2.9a2 2 0 0 0-3.4 0Z" />
        <path d="M12 9v4m0 4h.01" />
      </>
    ),
    Reports: (
      <>
        <path d="M4 19V9m6 10V5m6 14v-7m4 7H2" />
      </>
    ),
    Settings: (
      <>
        <circle cx="12" cy="12" r="3" />
        <path d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-2.83 2.83-.06-.06a1.7 1.7 0 0 0-1.88-.34 1.7 1.7 0 0 0-1.03 1.56V21h-4v-.09A1.7 1.7 0 0 0 9 19.35a1.7 1.7 0 0 0-1.88.34l-.06.06-2.83-2.83.06-.06A1.7 1.7 0 0 0 4.63 15 1.7 1.7 0 0 0 3.07 14H3v-4h.09A1.7 1.7 0 0 0 4.65 9a1.7 1.7 0 0 0-.34-1.88l-.06-.06 2.83-2.83.06.06A1.7 1.7 0 0 0 9 4.63h.02A1.7 1.7 0 0 0 10 3.07V3h4v.09A1.7 1.7 0 0 0 15 4.65a1.7 1.7 0 0 0 1.88-.34l.06-.06 2.83 2.83-.06.06A1.7 1.7 0 0 0 19.37 9v.02A1.7 1.7 0 0 0 20.93 10H21v4h-.09A1.7 1.7 0 0 0 19.4 15Z" />
      </>
    ),
    bell: (
      <>
        <path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4" />
      </>
    ),
    chevron: <path d="m9 18 6-6-6-6" />,
    down: <path d="m6 9 6 6 6-6" />,
    search: (
      <>
        <circle cx="11" cy="11" r="7" />
        <path d="m20 20-4-4" />
      </>
    ),
    more: (
      <>
        <circle cx="5" cy="12" r="1" />
        <circle cx="12" cy="12" r="1" />
        <circle cx="19" cy="12" r="1" />
      </>
    ),
    close: <path d="M18 6 6 18M6 6l12 12" />,
    arrow: <path d="M5 12h14m-5-5 5 5-5 5" />,
    plus: <path d="M12 5v14M5 12h14" />,
    filter: <path d="M4 5h16M7 12h10m-7 7h4" />,
  }
  return (
    <svg
      className="icon"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.7"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      {paths[name] ?? paths.more}
    </svg>
  )
}

function Button({
  children,
  kind = "secondary",
  icon,
  onClick,
  disabled = false,
}: {
  children: React.ReactNode
  kind?: "primary" | "secondary" | "ghost"
  icon?: string
  onClick?: () => void
  disabled?: boolean
}) {
  return (
    <button className={`button ${kind}`} onClick={onClick} disabled={disabled}>
      {icon && <Icon name={icon} size={16} />}
      {children}
    </button>
  )
}

function Dropdown({
  label,
  value,
  options,
  onChange,
  disabled = false,
}: {
  label?: string
  value: string
  options: string[]
  onChange?: (value: string) => void
  disabled?: boolean
}) {
  const [open, setOpen] = useState(false)
  const [localValue, setLocalValue] = useState(value)
  useEffect(() => setLocalValue(value), [value])
  const selectedValue = onChange ? value : localValue
  return (
    <div className="dropdown-wrap">
      <button
        className="dropdown"
        onClick={() => setOpen(!open)}
        aria-expanded={open}
        disabled={disabled}
      >
        <span>
          {label && <small>{label}</small>}
          {selectedValue}
        </span>
        <Icon name="down" size={14} />
      </button>
      {open && (
        <div className="dropdown-menu">
          {options.map((option) => (
            <button
              key={option}
              className={option === selectedValue ? "selected" : ""}
              onClick={() => {
                setLocalValue(option)
                onChange?.(option)
                setOpen(false)
              }}
            >
              {option}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

function Status({
  children,
  tone = "muted",
}: {
  children: React.ReactNode
  tone?: Tone
}) {
  return (
    <span className={`status ${tone}`}>
      <i />
      {children}
    </span>
  )
}

function Wordmark() {
  return (
    <div className="wordmark" aria-label="OPTIMO">
      OPTIMO
    </div>
  )
}

function useArabicTranslation(language: Language, resetKey: string) {
  const root = useRef<HTMLDivElement>(null)
  const originals = useRef(new WeakMap<Text, string>())
  useEffect(() => {
    if (!root.current) return
    const translate = () => {
      if (!root.current) return
      const walker = document.createTreeWalker(
        root.current!,
        NodeFilter.SHOW_TEXT,
      )
      let node = walker.nextNode()
      while (node) {
        const textNode = node as Text
        const value = textNode.textContent ?? ""
        const saved = originals.current.get(textNode)
        if (language === "ar") {
          const isCurrentTranslation =
            saved && value.trim() === arabicCopy[saved.trim()]
          if (!saved || !isCurrentTranslation)
            originals.current.set(textNode, value)
          const source = originals.current.get(textNode) ?? value
          const trimmed = source.trim()
          const translated = arabicCopy[trimmed]
            ? source.replace(trimmed, arabicCopy[trimmed])
            : source
          if (textNode.textContent !== translated)
            textNode.textContent = translated
        } else if (saved) {
          if (textNode.textContent !== saved) textNode.textContent = saved
        }
        node = walker.nextNode()
      }
      root
        .current!.querySelectorAll<HTMLInputElement>("input[placeholder]")
        .forEach((input) => {
          const source = input.dataset.originalPlaceholder ?? input.placeholder
          input.dataset.originalPlaceholder = source
          if (language === "ar" && source.includes("Search"))
            input.placeholder = "ابحث عن مرفق أو مهمة أو موظف"
          else if (language === "en") input.placeholder = source
        })
    }
    translate()
    const observer = new MutationObserver(translate)
    observer.observe(root.current, {
      childList: true,
      subtree: true,
      characterData: true,
    })
    return () => observer.disconnect()
  }, [language, resetKey])
  return root
}

function LanguageSwitch({
  language,
  onChange,
}: {
  language: Language
  onChange: (language: Language) => void
}) {
  return (
    <div className="language-switch" aria-label="Language">
      <button
        className={language === "en" ? "active" : ""}
        onClick={() => onChange("en")}
      >
        EN
      </button>
      <i />
      <button
        className={language === "ar" ? "active" : ""}
        onClick={() => onChange("ar")}
      >
        العربية
      </button>
    </div>
  )
}

function Login({
  language,
  setLanguage,
  onSuccess,
}: {
  language: Language
  setLanguage: (language: Language) => void
  onSuccess: () => void
}) {
  const [mode, setMode] = useState<"signin" | "recovery" | "sent">("signin")
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [remember, setRemember] = useState(true)
  const [loading, setLoading] = useState(false)
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({})
  const root = useArabicTranslation(language, mode)
  const submit = () => {
    const nextErrors: { email?: string; password?: string } = {}
    if (!email)
      nextErrors.email =
        language === "ar" ? "البريد الإلكتروني مطلوب" : "Email is required"
    else if (!/^\S+@\S+\.\S+$/.test(email))
      nextErrors.email =
        language === "ar" ? "أدخل بريداً إلكترونياً صحيحاً" : "Enter a valid email"
    if (mode === "signin" && !password)
      nextErrors.password =
        language === "ar" ? "كلمة المرور مطلوبة" : "Password is required"
    setErrors(nextErrors)
    if (Object.keys(nextErrors).length) return
    if (mode === "recovery") {
      setMode("sent")
      return
    }
    setLoading(true)
    window.setTimeout(() => {
      setLoading(false)
      onSuccess()
    }, 800)
  }
  return (
    <div
      className="login"
      dir={language === "ar" ? "rtl" : "ltr"}
      lang={language}
      ref={root}
    >
      <section className="login-form-side">
        <div className="login-top">
          <Wordmark />
          <LanguageSwitch language={language} onChange={setLanguage} />
        </div>
        <div className="auth-flow">
          {mode === "signin" && (
            <>
              <span className="eyebrow">HOSPITALITY EXCELLENCE CENTER</span>
              <h1>Welcome back</h1>
              <p>Sign in to access club operations.</p>
              <div className="auth-fields">
                <label className={errors.email ? "field error" : "field"}>
                  <span>Email</span>
                  <input
                    value={email}
                    onChange={(event) => setEmail(event.target.value)}
                    placeholder="name@optimo.sa"
                    inputMode="email"
                  />
                  <small>{errors.email}</small>
                </label>
                <label className={errors.password ? "field error" : "field"}>
                  <span>Password</span>
                  <div>
                    <input
                      type={showPassword ? "text" : "password"}
                      value={password}
                      onChange={(event) => setPassword(event.target.value)}
                      placeholder="••••••••••"
                    />
                    <button onClick={() => setShowPassword(!showPassword)}>
                      {showPassword ? "Hide" : "Show"}
                    </button>
                  </div>
                  <small>{errors.password}</small>
                </label>
              </div>
              <div className="auth-options">
                <label className="check">
                  <input
                    type="checkbox"
                    checked={remember}
                    onChange={() => setRemember(!remember)}
                  />
                  <i />
                  Remember me
                </label>
                <button
                  onClick={() => {
                    setErrors({})
                    setMode("recovery")
                  }}
                >
                  Forgot Password?
                </button>
              </div>
              <Button kind="primary" onClick={submit}>
                {loading ? (
                  <>
                    <span className="button-loader" /> Signing In
                  </>
                ) : (
                  <>
                    Sign In <Icon name="arrow" size={16} />
                  </>
                )}
              </Button>
              <div className="security-note">
                <i />
                <span>
                  <strong>Secure operational access</strong>Protected for
                  authorized OPTIMO personnel.
                </span>
              </div>
            </>
          )}
          {mode === "recovery" && (
            <>
              <button className="back-link" onClick={() => setMode("signin")}>
                ← Back to sign in
              </button>
              <span className="eyebrow">ACCOUNT RECOVERY</span>
              <h1>Recover access</h1>
              <p>
                Enter your work email and we’ll send a secure recovery link.
              </p>
              <label className={errors.email ? "field error" : "field"}>
                <span>Email</span>
                <input
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  placeholder="name@optimo.sa"
                />
                <small>{errors.email}</small>
              </label>
              <Button kind="primary" onClick={submit}>
                Send recovery link <Icon name="arrow" size={16} />
              </Button>
            </>
          )}
          {mode === "sent" && (
            <div className="recovery-sent">
              <span className="success-mark">✓</span>
              <span className="eyebrow">RECOVERY SENT</span>
              <h1>Check your inbox</h1>
              <p>A recovery link has been sent to your work email.</p>
              <strong>{email}</strong>
              <Button kind="secondary" onClick={() => setMode("signin")}>
                Back to sign in
              </Button>
            </div>
          )}
        </div>
        <footer>OPTIMO internal operations · Authorized access only</footer>
      </section>
      <section
        className="login-architecture"
        style={{ backgroundImage: `url(${exterior})` }}
      >
        <div className="architecture-caption">
          <span>RIYADH · MAIN CLUB</span>
          <p>Physical excellence, translated into operational intelligence.</p>
        </div>
      </section>
    </div>
  )
}

function Sidebar({
  active,
  setActive,
}: {
  active: Page
  setActive: (page: Page) => void
}) {
  return (
    <aside className="sidebar">
      <button
        className="brand"
        onClick={() => setActive("Excellence Center")}
        aria-label="Go to Excellence Center"
      >
        <Wordmark />
      </button>
      <nav>
        {navItems.map((item) => (
          <button
            key={item}
            className={`nav-item ${active === item ? "active" : ""}`}
            onClick={() => setActive(item)}
          >
            <Icon name={item} />
            <span>{item}</span>
          </button>
        ))}
      </nav>
      <div className="club-status">
        <span className="eyebrow">MAIN CLUB</span>
        <strong>
          <i />
          42 devices online
        </strong>
        <span>Riyadh · All systems normal</span>
      </div>
    </aside>
  )
}

function Header({
  page,
  language,
  setLanguage,
  navigate,
  logout,
  context,
  openFacility,
  openTask,
}: {
  page: Page
  language: Language
  setLanguage: (language: Language) => void
  navigate: (page: Page) => void
  logout: () => void
  context: OperationalContext
  openFacility: (facilityId: string) => void
  openTask: (taskId: string) => void
}) {
  const [notifications, setNotifications] = useState(false)
  const [userMenu, setUserMenu] = useState(false)
  const [profile, setProfile] = useState(false)
  const [readNotifications, setReadNotifications] = useState<string[]>([])
  const [showAllNotifications, setShowAllNotifications] = useState(false)
  const notificationItems = [
    ["SH-04", "Service Required", "Changing Area A · 2 min ago", "attention"],
    ["WC-02", "Cleaning task created", "Toilet Area · 4 min ago", "cleaning"],
    ["TSK-1046", "Task Reassigned", "Assigned to Sara Ali", "cleaning"],
    [
      "BIN-02",
      "Service threshold approaching",
      "Vanity Area · 8 min ago",
      "attention",
    ],
    ["SH-03", "Inspection completed", "Shower Area · 12 min ago", "ready"],
  ]
  return (
    <header className="topbar">
      <div className="page-heading">
        <div className="live-label">
          <i /> LIVE OPERATIONS <span>· UPDATED NOW</span>
        </div>
        <h1>
          {page === "Excellence Center"
            ? "Hospitality Excellence Center"
            : page}
        </h1>
        <p>
          {page === "Excellence Center"
            ? "Live operations for the Washroom / Changing Area."
            : pageDescriptions[page]}
        </p>
      </div>
      <div className="header-tools">
        <div className={`context-summary ${page === "Excellence Center" ? "" : "compact"}`}>
          <span><small>CLUB</small>{context.club}</span>
          {page === "Excellence Center" && (
            <>
              <i><Icon name="chevron" size={11} /></i>
              <span><small>FLOOR</small>Ground Floor</span>
              <i><Icon name="chevron" size={11} /></i>
              <span><small>LIVE TWIN</small>Washroom / Changing Area</span>
            </>
          )}
        </div>
        <LanguageSwitch language={language} onChange={setLanguage} />
        <button
          className="icon-button"
          aria-label="Notifications"
          onClick={() => {
            setNotifications(!notifications)
            setUserMenu(false)
          }}
        >
          <Icon name="bell" />
          {readNotifications.length < notificationItems.length && (
            <b>{notificationItems.length - readNotifications.length}</b>
          )}
        </button>
        {notifications && (
          <div className="global-popover notifications">
            <div className="popover-head">
              <strong>Notifications</strong>
              <button
                onClick={() =>
                  setReadNotifications(notificationItems.map((item) => item[0]))
                }
              >
                Mark all as read
              </button>
            </div>
            {notificationItems
              .slice(0, showAllNotifications ? notificationItems.length : 3)
              .map(([id, title, detail, tone]) => (
                <button
                  className={`notification-item ${
                    readNotifications.includes(id) ? "read" : "unread"
                  }`}
                  key={id}
                  onClick={() => {
                    setReadNotifications((items) => [
                      ...new Set([...items, id]),
                    ])
                    if (id.startsWith("TSK")) openTask(id)
                    else if (id.startsWith("INSP")) navigate("Quality")
                    else openFacility(id)
                    setNotifications(false)
                  }}
                >
                  <i className={tone} />
                  <span>
                    <b>{title}</b>
                    <small>
                      <bdi>{id}</bdi> · {detail}
                    </small>
                  </span>
                  <Icon name="chevron" size={14} />
                </button>
              ))}
            <button
              className="popover-footer"
              onClick={() => setShowAllNotifications(!showAllNotifications)}
            >
              {showAllNotifications ? "Show recent" : "View all notifications"}{" "}
              <Icon name="arrow" size={14} />
            </button>
          </div>
        )}
        <button
          className="user"
          onClick={() => {
            setUserMenu(!userMenu)
            setNotifications(false)
          }}
        >
          <span>AH</span>
          <div>
            <strong>Ahmed Hassan</strong>
            <small>Duty Manager</small>
          </div>
          <Icon name="down" size={13} />
        </button>
        {userMenu && (
          <div className="global-popover user-menu">
            <div className="account-summary">
              <span>AH</span>
              <div>
                <strong>Ahmed Hassan</strong>
                <small>ahmed@optimo.sa</small>
              </div>
            </div>
            <button
              onClick={() => {
                setProfile(true)
                setUserMenu(false)
              }}
            >
              My Profile
            </button>
            <button
              onClick={() => {
                setProfile(true)
                setUserMenu(false)
              }}
            >
              Preferences
            </button>
            <button
              onClick={() => setLanguage(language === "en" ? "ar" : "en")}
            >
              Language <span>{language === "en" ? "العربية" : "EN"}</span>
            </button>
            <i />
            <button className="logout" onClick={logout}>
              Sign Out
            </button>
          </div>
        )}
      </div>
      {profile && (
        <ProfilePanel
          language={language}
          setLanguage={setLanguage}
          onClose={() => setProfile(false)}
        />
      )}
    </header>
  )
}

function ProfilePanel({
  language,
  setLanguage,
  onClose,
}: {
  language: Language
  setLanguage: (language: Language) => void
  onClose: () => void
}) {
  const [editing, setEditing] = useState(false)
  const [saved, setSaved] = useState(false)
  const [name, setName] = useState("Ahmed Hassan")
  const [alerts, setAlerts] = useState(true)
  const [shiftUpdates, setShiftUpdates] = useState(true)
  const save = () => {
    setEditing(false)
    setSaved(true)
    window.setTimeout(() => setSaved(false), 2400)
  }
  return (
    <div className="drawer-backdrop" onClick={onClose}>
      <aside
        className="detail-drawer profile-panel"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="drawer-head">
          <div>
            <span className="eyebrow">ACCOUNT</span>
            <h2>My Profile</h2>
          </div>
          <button className="icon-button compact" onClick={onClose}>
            <Icon name="close" />
          </button>
        </div>
        <div className="profile-identity">
          <span>AH</span>
          <div>
            <strong>Ahmed Hassan</strong>
            <small>Duty Manager · Main Club</small>
          </div>
        </div>
        <div className="profile-fields">
          <label className="field">
            <span>Name</span>
            <input
              disabled={!editing}
              value={name}
              onChange={(event) => setName(event.target.value)}
            />
          </label>
          <label className="field">
            <span>Email</span>
            <input disabled value="ahmed@optimo.sa" />
          </label>
          <label className="field">
            <span>Preferred Language</span>
            <Dropdown
              value={language === "en" ? "English" : "العربية"}
              options={["English", "العربية"]}
              onChange={(value) =>
                setLanguage(value === "English" ? "en" : "ar")
              }
            />
          </label>
        </div>
        <section className="preference-block">
          <span className="eyebrow">NOTIFICATION PREFERENCES</span>
          <label>
            <span>
              <strong>Operational alerts</strong>
              <small>Service, SLA and critical facility updates</small>
            </span>
            <button
              className={`switch ${alerts ? "on" : ""}`}
              onClick={() => setAlerts(!alerts)}
            >
              <i />
            </button>
          </label>
          <label>
            <span>
              <strong>Shift updates</strong>
              <small>Assignments and schedule changes</small>
            </span>
          <button className={`switch ${shiftUpdates ? "on" : ""}`} onClick={() => setShiftUpdates(!shiftUpdates)}>
              <i />
            </button>
          </label>
        </section>
        {saved && (
          <div className="inline-success">
            <span>✓</span>Changes saved successfully.
          </div>
        )}
        <div className="drawer-actions">
          {editing ? (
            <>
              <Button kind="ghost" onClick={() => setEditing(false)}>
                Cancel
              </Button>
              <Button kind="primary" onClick={save}>
                Save Changes
              </Button>
            </>
          ) : (
            <Button kind="primary" onClick={() => setEditing(true)}>
              Edit Profile
            </Button>
          )}
        </div>
      </aside>
    </div>
  )
}

function DetailDrawer({
  type,
  title,
  onClose,
  onLocate,
}: {
  type: string
  title: string
  onClose: () => void
  onLocate?: (facilityId: string) => void
}) {
  const sourceTask = taskRows.find((row) => row[0] === title)
  const locatableFacility = facilities.find(
    (facility) => facility.id === sourceTask?.[1],
  )
  const defaultState =
    type === "Task Detail"
      ? (sourceTask?.[7] ?? "New")
      : type === "Issue Detail"
        ? "Investigating"
        : "Active"
  const [state, setState] = useState(defaultState)
  const [feedback, setFeedback] = useState("")
  const [assignee, setAssignee] = useState(sourceTask?.[5] ?? "Ahmed Hassan")
  const act = (next: string, message: string) => {
    setState(next)
    setFeedback(message)
    window.setTimeout(() => setFeedback(""), 2200)
  }
  const taskAction =
    state === "New"
      ? ["Accept Task", "Accepted"]
      : state === "Accepted"
        ? ["Start Task", "In Progress"]
        : state === "Blocked"
          ? ["Resolve Block", "In Progress"]
          : state === "Completed"
            ? ["View History", "Completed"]
            : ["Complete Task", "Completed"]
  const primaryLabel =
    type === "Task Detail"
      ? taskAction[0]
      : type === "Issue Detail"
        ? "Resolve Issue"
        : type === "Inspection Detail"
          ? "Create Corrective Task"
          : type === "Team Member"
            ? "Change Assignment"
            : type === "Device Detail"
              ? "Create Related Issue"
              : type === "Settings Detail"
                ? "Save Changes"
                : "Edit Schedule"
  return (
    <div className="drawer-backdrop" onClick={onClose}>
      <aside
        className="detail-drawer"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="drawer-head">
          <div>
            <span className="eyebrow">{type}</span>
            <h2>
              <bdi>{title}</bdi>
            </h2>
          </div>
          <button
            className="icon-button compact"
            onClick={onClose}
            aria-label="Close"
          >
            <Icon name="close" />
          </button>
        </div>
        <Status
          tone={
            state === "Completed" || state === "Resolved"
              ? "ready"
              : "attention"
          }
        >
          {state}
        </Status>
        <dl className="detail-facts">
          <div>
            <dt>Location</dt>
            <dd>{sourceTask?.[2] ?? "Changing Area A"}</dd>
          </div>
          <div>
            <dt>Owner</dt>
            <dd>{sourceTask?.[5] ?? assignee}</dd>
          </div>
          <div>
            <dt>Created</dt>
            <dd>
              Today · <bdi>10:24</bdi>
            </dd>
          </div>
          <div>
            <dt>SLA</dt>
            <dd className="accent">
              <bdi>{sourceTask?.[8] ?? "28 min"}</bdi> remaining
            </dd>
          </div>
        </dl>
        {type === "Task Detail" && state !== "Completed" && (
          <section className="drawer-section assignment-section">
            <span className="eyebrow">ASSIGNMENT</span>
            <h3>Operational owner</h3>
            <Dropdown
              value={assignee}
              options={[
                "Ahmed Hassan · Available · 3 tasks",
                "Sara Omar · On Task · 5 tasks",
                "M. Khalid · On Task · 4 tasks",
              ]}
              onChange={(value) => {
                setAssignee(value.split(" · ")[0])
                setFeedback("Task assigned")
              }}
            />
          </section>
        )}
        <section className="drawer-section">
          <span className="eyebrow">OPERATIONAL CONTEXT</span>
          <h3>
            {type === "Inspection Detail"
              ? "Hospitality standard checklist"
              : "Service activity"}
          </h3>
          <p>
            Facility requires attention to restore the expected OPTIMO
            hospitality standard.
          </p>
          {type === "Inspection Detail" && (
            <div className="checklist">
              {[
                "Surface condition",
                "Supplies available",
                "Guest-ready standard",
              ].map((item, index) => (
                <label key={item}>
                  <span>{item}</span>
                  <Status tone={index === 1 ? "attention" : "ready"}>
                    {index === 1 ? "Rework" : "Passed"}
                  </Status>
                </label>
              ))}
            </div>
          )}
        </section>
        <section className="timeline">
          <span className="eyebrow">ACTIVITY</span>
          {[
            ["10:24", "Request created automatically"],
            ["10:26", `Assigned to ${sourceTask?.[5] ?? "Ahmed Hassan"}`],
            ["10:31", "Work started"],
          ].map(([time, text]) => (
            <div key={time}>
              <time>
                <bdi>{time}</bdi>
              </time>
              <i />
              <span>{text}</span>
            </div>
          ))}
        </section>
        {feedback && (
          <div className="inline-success">
            <span>✓</span>
            {feedback}
          </div>
        )}
        <div className="drawer-actions">
          {type === "Task Detail" && locatableFacility && onLocate && (
            <Button
              kind="ghost"
              onClick={() => {
                onClose()
                onLocate(locatableFacility.id)
              }}
            >
              Locate in Digital Twin
            </Button>
          )}
          <Button kind="ghost" onClick={onClose}>
            Close
          </Button>
          {type === "Task Detail" && state === "In Progress" && (
            <Button onClick={() => act("Blocked", "Task marked as blocked")}>
              Mark Blocked
            </Button>
          )}
          <Button
            kind="primary"
            onClick={() => {
              if (type === "Task Detail")
                act(
                  taskAction[1],
                  taskAction[0] === "View History"
                    ? "History opened"
                    : `Task updated · ${taskAction[1]}`,
                )
              else if (type === "Issue Detail")
                act("Resolved", "Issue resolved")
              else
                setFeedback(
                  type === "Team Member"
                    ? "Assignment updated"
                    : type === "Inspection Detail"
                      ? "Corrective task created"
                      : type === "Device Detail"
                        ? "Related issue created"
                        : type === "Settings Detail"
                          ? "Changes saved successfully."
                          : "Schedule updated",
                )
            }}
          >
            {primaryLabel}
          </Button>
        </div>
      </aside>
    </div>
  )
}

const pageDescriptions: Record<Page, string> = {
  "Excellence Center": "",
  Tasks: "Assign, monitor and resolve operational service work.",
  Schedule: "Plan recurring and routine hospitality operations.",
  Team: "Balance on-shift capacity and assigned operational work.",
  Quality: "Maintain club standards through inspections and rework.",
  Issues: "Track facility faults and operational blockers to resolution.",
  Reports: "Review service performance and recurring operational patterns.",
  Settings: "Configure locations, devices, service rules and access.",
}

function Donut({
  quiet = false,
  onFilter,
}: {
  quiet?: boolean
  onFilter?: () => void
}) {
  return (
    <button
      className={`donut ${quiet ? "quiet" : ""}`}
      onClick={onFilter}
      aria-label={
        quiet
          ? "89 percent within target"
          : "67 percent ready, select to filter"
      }
    >
      <svg viewBox="0 0 120 120">
        <circle className="track" cx="60" cy="60" r="49" />
        <circle
          className="segment main"
          cx="60"
          cy="60"
          r="49"
          pathLength="100"
        />
        {!quiet && (
          <>
            <circle
              className="segment warn"
              cx="60"
              cy="60"
              r="49"
              pathLength="100"
            />
            <circle
              className="segment danger"
              cx="60"
              cy="60"
              r="49"
              pathLength="100"
            />
          </>
        )}
      </svg>
      <span>
        <strong>{quiet ? "89%" : "67%"}</strong>
        <small>{quiet ? "WITHIN TARGET" : "READY"}</small>
      </span>
      {!quiet && (
        <em className="donut-tooltip">
          <b>NEEDS ATTENTION</b>3 facilities · 33%
        </em>
      )}
    </button>
  )
}

function SummaryRow({
  onFilter,
  openTasks,
}: {
  onFilter: () => void
  openTasks: () => void
}) {
  return (
    <section className="summary-grid">
      <article className="summary readiness">
        <div className="section-head">
          <div>
            <span className="eyebrow">WASHROOM STANDARD</span>
            <h2>Operational Readiness</h2>
          </div>
          <Status tone="ready">Live</Status>
        </div>
        <div className="radial-content">
          <Donut onFilter={onFilter} />
          <div className="metric-notes">
            <div>
              <strong>9</strong>
              <span>monitored</span>
            </div>
            <div>
              <strong className="accent">3</strong>
              <span>need attention</span>
            </div>
          </div>
        </div>
      </article>
      <article className="summary performance">
        <div className="section-head">
          <div>
            <span className="eyebrow">WASHROOM SERVICE</span>
            <h2>Response Performance</h2>
          </div>
        </div>
        <div className="radial-content compact">
          <Donut quiet />
          <div className="metric-notes">
            <p>
              <strong>8 / 9</strong> responses inside service target
            </p>
            <span className="positive">+2% today</span>
          </div>
        </div>
      </article>
      <article className="summary workload">
        <div className="section-head">
          <div>
            <span className="eyebrow">WASHROOM · RIGHT NOW</span>
            <h2>Active Workload</h2>
          </div>
          <button className="text-link" onClick={openTasks}>
            Open task board <Icon name="arrow" size={14} />
          </button>
        </div>
        <div className="workload-total">
          <strong>3</strong>
          <span>ACTIVE</span>
          <small>Washroom / Changing Area</small>
        </div>
        <div className="workload-rail washroom">
          <i />
          <i className="accepted" />
          <i className="progress" />
        </div>
        <div className="workload-legend">
          <span>
            <i className="new" />
            <b>1</b> New
          </span>
          <span>
            <i className="accepted" />
            <b>1</b> Accepted
          </span>
          <span>
            <i className="progress" />
            <b>1</b> In Progress
          </span>
        </div>
      </article>
    </section>
  )
}

function OperationsMap({
  selected,
  setSelected,
  attentionOnly,
  setAttentionOnly,
  openTask,
  context,
}: {
  selected: Facility | null
  setSelected: (facility: Facility | null) => void
  attentionOnly: boolean
  setAttentionOnly: (value: boolean) => void
  openTask: () => void
  context: OperationalContext
}) {
  type TwinMode = "Service Status" | "Occupancy" | "Bin Levels" | "Devices"
  const [mode, setMode] = useState<TwinMode>("Service Status")
  const [camera, setCamera] = useState({
    scale: 1,
    panX: 0,
    panY: 0,
    orbitX: 0,
    orbitY: 0,
  })
  const [locate, setLocate] = useState("")
  const [dragging, setDragging] = useState(false)
  const drag = useRef<{
    x: number
    y: number
    panX: number
    panY: number
    orbitX: number
    orbitY: number
    pan: boolean
  } | null>(null)
  const clamp = (value: number, min: number, max: number) =>
    Math.min(max, Math.max(min, value))
  const fitView = () =>
    setCamera({ scale: 1, panX: 0, panY: 0, orbitX: 0, orbitY: 0 })
  const focus = (facility: Facility) => {
    setSelected(facility)
    setCamera({
      scale: 1.3,
      panX: clamp((38 - (6 + facility.x * 0.88)) * 8, -260, 260),
      panY: clamp((45 - (12 + facility.y * 0.76)) * 5, -120, 120),
      orbitX: facility.x < 50 ? 1.5 : -1.5,
      orbitY: 1,
    })
  }
  const locateResults = facilities.filter((facility) =>
    facility.id.toLowerCase().includes(locate.toLowerCase()),
  )
  const visible = facilities
  useEffect(() => {
    if (!selected) return
    setCamera({
      scale: 1.3,
      panX: clamp((38 - (6 + selected.x * 0.88)) * 8, -260, 260),
      panY: clamp((45 - (12 + selected.y * 0.76)) * 5, -120, 120),
      orbitX: selected.x < 50 ? 1.5 : -1.5,
      orbitY: 1,
    })
  }, [selected?.id])
  const markerValue = (facility: Facility) => {
    if (mode === "Occupancy") return facility.occupancy ?? "Not monitored"
    if (mode === "Bin Levels")
      return facility.type === "Waste Bin"
        ? facility.status
        : "Not applicable"
    if (mode === "Devices") return facility.deviceStatus ?? "Unknown"
    return facility.status
  }
  const markerTone = (facility: Facility): Tone => {
    if (mode === "Occupancy")
      return facility.occupancy === "Occupied"
        ? "attention"
        : facility.occupancy === "Unknown"
          ? "muted"
          : "ready"
    if (mode === "Devices")
      return facility.deviceStatus === "Offline"
        ? "critical"
        : facility.deviceStatus === "Delayed"
          ? "attention"
          : "ready"
    return facility.tone
  }
  return (
    <article
      className={`operations-surface digital-twin ${
        selected ? "with-inspector" : ""
      }`}
    >
      <div className="operations-head">
        <div>
          <span className="eyebrow">LIVE SPATIAL OPERATIONS</span>
          <h2>OPTIMO Live Digital Twin</h2>
          <p>
            Drag to orbit · Shift-drag to pan · Select a facility to
            investigate.
          </p>
        </div>
        <div className="twin-toolbar">
          <div className="locate-control">
            <Icon name="search" size={15} />
            <input
              value={locate}
              onChange={(event) => setLocate(event.target.value.toUpperCase())}
              onKeyDown={(event) => {
                if (event.key === "Enter" && locateResults[0])
                  focus(locateResults[0])
              }}
              placeholder="Locate facility"
              aria-label="Locate facility"
            />
            {locate && (
              <button onClick={() => setLocate("")} aria-label="Clear search">
                <Icon name="close" size={13} />
              </button>
            )}
            {locate && (
              <div className="locate-results">
                {locateResults.length ? (
                  locateResults.slice(0, 4).map((facility) => (
                    <button
                      key={facility.id}
                      onClick={() => {
                        focus(facility)
                        setLocate("")
                      }}
                    >
                      <bdi>{facility.id}</bdi>
                      <span>
                        {facility.type} · {facility.zone}
                      </span>
                    </button>
                  ))
                ) : (
                  <span>No facility found</span>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
      <div className="twin-modebar">
        <span>VIEW MODE</span>
        {(
          [
            "Service Status",
            "Occupancy",
            "Bin Levels",
            "Devices",
          ] as TwinMode[]
        ).map((item) => (
          <button
            key={item}
            className={mode === item ? "active" : ""}
            onClick={() => setMode(item)}
          >
            {item}
          </button>
        ))}
        <div className="twin-context">
          <span>
            {context.club} <Icon name="chevron" size={11} /> Ground Floor{" "}
            <Icon name="chevron" size={11} /> Washroom / Changing Area
          </span>
        </div>
      </div>
      {attentionOnly && (
        <div className="filter-notice">
          <span>
            <Status tone="attention">Readiness filter</Status> Showing
            facilities requiring attention
          </span>
          <button onClick={() => setAttentionOnly(false)}>
            Clear filter <Icon name="close" size={14} />
          </button>
        </div>
      )}
      <div className="map-and-inspector">
        <div
          className={`map twin-viewport ${dragging ? "dragging" : ""} ${
            camera.scale > 1.14 ? "zoomed" : ""
          }`}
          onContextMenu={(event) => event.preventDefault()}
          onPointerDown={(event) => {
            event.currentTarget.setPointerCapture(event.pointerId)
            drag.current = {
              x: event.clientX,
              y: event.clientY,
              panX: camera.panX,
              panY: camera.panY,
              orbitX: camera.orbitX,
              orbitY: camera.orbitY,
              pan: event.shiftKey || event.button === 2,
            }
            setDragging(true)
          }}
          onPointerMove={(event) => {
            if (!drag.current) return
            const dx = event.clientX - drag.current.x
            const dy = event.clientY - drag.current.y
            if (drag.current.pan) {
              setCamera((current) => ({
                ...current,
                panX: clamp(drag.current!.panX + dx, -260, 260),
                panY: clamp(drag.current!.panY + dy, -160, 160),
              }))
            } else {
              setCamera((current) => ({
                ...current,
                orbitX: clamp(drag.current!.orbitX + dx * 0.018, -5, 5),
                orbitY: clamp(drag.current!.orbitY - dy * 0.012, -2, 4),
              }))
            }
          }}
          onPointerUp={() => {
            drag.current = null
            setDragging(false)
          }}
          onPointerCancel={() => {
            drag.current = null
            setDragging(false)
          }}
          onWheel={(event) => {
            event.preventDefault()
            setCamera((current) => ({
              ...current,
              scale: clamp(
                current.scale + (event.deltaY > 0 ? -0.08 : 0.08),
                1,
                1.8,
              ),
            }))
          }}
        >
          <div
              className="twin-scene"
              style={{
                transform: `translate3d(${camera.panX + camera.orbitX * 2}px, ${camera.panY + camera.orbitY * 2}px, 0) translateY(-50%) scale(${camera.scale}) skewX(${camera.orbitX * 0.12}deg)`,
              }}
            >
              <img
                src={digitalTwin}
                alt="OPTIMO Changing and Washroom Suite digital twin"
                draggable={false}
              />
              <div className="twin-grounding" />
              {facilities.map((facility) => {
                const tone = markerTone(facility)
                const modeMuted =
                  (mode === "Bin Levels" &&
                    facility.type !== "Waste Bin") ||
                  (mode === "Occupancy" &&
                    facility.type === "Waste Bin")
                const faded =
                  modeMuted ||
                  (attentionOnly &&
                    !["attention", "critical", "cleaning"].includes(
                      facility.tone,
                    )) ||
                  (!!selected && selected.id !== facility.id)
                return (
                  <button
                    key={facility.id}
                    className={`twin-marker ${tone} ${
                      selected?.id === facility.id ? "selected" : ""
                    } ${facility.priority ? "priority" : "low"} ${
                      faded ? "faded" : ""
                    } ${facility.x > 75 ? "edge-right" : ""}`}
                    style={{
                      left: `${facility.x}%`,
                      top: `${facility.y}%`,
                    }}
                    onPointerDown={(event) => event.stopPropagation()}
                    onClick={() => focus(facility)}
                  >
                    <i />
                    <span>
                      <bdi>{facility.id}</bdi>
                    </span>
                    <em>
                      <b>
                        <bdi>{facility.id}</bdi>
                      </b>
                      <small>{facility.type}</small>
                      <strong>{markerValue(facility)}</strong>
                    </em>
                  </button>
                )
              })}
          </div>
          <div
            className="twin-camera-controls"
            onPointerDown={(event) => event.stopPropagation()}
          >
            <button
              onClick={() =>
                setCamera((current) => ({
                  ...current,
                  scale: clamp(current.scale + 0.12, 1, 1.8),
                }))
              }
              title="Zoom in"
              aria-label="Zoom in"
            >
              <Icon name="plus" size={16} />
            </button>
            <button
              onClick={() =>
                setCamera((current) => ({
                  ...current,
                  scale: clamp(current.scale - 0.12, 1, 1.8),
                }))
              }
              title="Zoom out"
              aria-label="Zoom out"
            >
              <span>−</span>
            </button>
            <button
              onClick={() => {
                setSelected(null)
                fitView()
              }}
              title="Reset and fit view"
              aria-label="Reset and fit view"
            >
              <Icon name="Excellence Center" size={16} />
            </button>
          </div>
          <div className="twin-orientation">
            <span>{Math.round(camera.scale * 100)}%</span>
            <i />
            <span>Elevated cutaway</span>
          </div>
          <div className="map-key twin-key">
            {mode === "Service Status" ? (
              <>
                <span>
                  <i className="ready" /> Ready
                </span>
                <span>
                  <i className="attention" /> Service Required
                </span>
                <span>
                  <i className="cleaning" /> Cleaning
                </span>
                <span>
                  <i className="critical" /> Out of Service
                </span>
              </>
            ) : (
              <span>
                {mode} · {visible.length} relevant facilities
              </span>
            )}
          </div>
        </div>
        {selected && (
          <Inspector
            facility={selected}
            close={() => setSelected(null)}
            openTask={openTask}
          />
        )}
      </div>
    </article>
  )
}

function Inspector({
  facility,
  close,
  openTask,
}: {
  facility: Facility
  close: () => void
  openTask: () => void
}) {
  const [detail, setDetail] = useState<"facility" | "device" | "history">(
    "facility",
  )
  const deviceId = facility.deviceId ?? `SNS-${facility.id.replace("-", "")}`
  return (
    <aside className="inspector">
      <div className="inspector-head">
        <span className="eyebrow">SELECTED FACILITY</span>
        <button
          className="icon-button compact"
          onClick={close}
          aria-label="Close inspector"
        >
          <Icon name="close" size={16} />
        </button>
      </div>
      <div>
        <h3>
          <bdi>{facility.id}</bdi>
        </h3>
        <p>
          {facility.type} · {facility.zone}
        </p>
      </div>
      {detail === "facility" && (
        <>
          <Status tone={facility.tone}>{facility.status}</Status>
          <dl>
            {facility.type !== "Waste Bin" && (
              <div>
                <dt>Occupancy</dt>
                <dd>{facility.occupancy ?? "Unknown"}</dd>
              </div>
            )}
            {facility.type === "Waste Bin" && (
              <div>
                <dt>Fill level</dt>
                <dd>{facility.status.includes("%") ? facility.status : "34%"}</dd>
              </div>
            )}
            <div>
              <dt>Device</dt>
              <dd>
                <button
                  className="inline-link"
                  onClick={() => setDetail("device")}
                >
                  <bdi>{deviceId}</bdi> · {facility.deviceStatus ?? "Online"}
                </button>
              </dd>
            </div>
            {facility.lastEvent && (
              <div>
                <dt>Latest Event</dt>
                <dd>{facility.lastEvent}</dd>
              </div>
            )}
            <div>
              <dt>Assigned To</dt>
              <dd>{facility.assigned ?? "Unassigned"}</dd>
            </div>
            {facility.taskStatus && (
              <>
                <div>
                  <dt>Linked Task</dt>
                  <dd>
                    {facility.type === "Shower"
                      ? `Clean Shower ${facility.id}`
                      : facility.type === "Waste Bin"
                        ? `Empty Bin ${facility.id}`
                        : `Clean Toilet ${facility.id}`}
                  </dd>
                </div>
                <div>
                  <dt>Task Status</dt>
                  <dd>
                    <Status
                      tone={
                        facility.taskStatus === "Accepted"
                          ? "ready"
                          : "cleaning"
                      }
                    >
                      {facility.taskStatus}
                    </Status>
                  </dd>
                </div>
                <div>
                  <dt>Response</dt>
                  <dd>Accepted in 00:32</dd>
                </div>
                <div>
                  <dt>Completion</dt>
                  <dd className="accent">Due in 06:30</dd>
                </div>
              </>
            )}
          </dl>
          <div className="inspector-actions">
            {facility.status !== "Ready" && (
              <Button kind="primary" onClick={openTask}>
                Open Task <Icon name="arrow" size={15} />
              </Button>
            )}
            <Button kind="ghost" onClick={() => setDetail("history")}>
              View Service History
            </Button>
            <Button kind="ghost" onClick={() => setDetail("device")}>
              View Device
            </Button>
          </div>
        </>
      )}
      {detail === "device" && (
        <div className="inspector-subview">
          <button className="back-link" onClick={() => setDetail("facility")}>
            ← Facility
          </button>
          <span className="eyebrow">ASSOCIATED DEVICE</span>
          <h4>
            <bdi>{deviceId}</bdi>
          </h4>
          <Status
            tone={
              facility.deviceStatus === "Offline"
                ? "critical"
                : facility.deviceStatus === "Delayed"
                  ? "attention"
                  : "ready"
            }
          >
            {facility.deviceStatus ?? "Online"}
          </Status>
          <dl>
            <div>
              <dt>Device type</dt>
              <dd>
                {facility.type === "Waste Bin"
                  ? "Fill sensor"
                  : "Occupancy sensor"}
              </dd>
            </div>
            <div>
              <dt>Connected facility</dt>
              <dd>
                <bdi>{facility.id}</bdi>
              </dd>
            </div>
            <div>
              <dt>Last update</dt>
              <dd>
                <bdi>10:26 · Now</bdi>
              </dd>
            </div>
            <div>
              <dt>Last event</dt>
              <dd>{facility.status}</dd>
            </div>
          </dl>
          <p className="device-note">
            Monitoring is operating normally. Device details are shown only to
            support service decisions.
          </p>
          <Button kind="ghost" onClick={() => setDetail("facility")}>
            Back to Facility
          </Button>
        </div>
      )}
      {detail === "history" && (
        <div className="inspector-subview">
          <button className="back-link" onClick={() => setDetail("facility")}>
            ← Facility
          </button>
          <span className="eyebrow">SERVICE HISTORY</span>
          <h4>Recent service</h4>
          <div className="mini-history">
            {[
              ["Today · 09:42", "Service completed", "Sara Omar"],
              ["Yesterday · 18:16", "Routine cleaning", "M. Khalid"],
              ["23 Jun · 12:08", "Inspection passed", "N. Faisal"],
            ].map(([time, event, owner]) => (
              <div key={time}>
                <time>
                  <bdi>{time}</bdi>
                </time>
                <strong>{event}</strong>
                <small>{owner}</small>
              </div>
            ))}
          </div>
        </div>
      )}
    </aside>
  )
}

function AttentionQueue({
  onSelect,
  onViewAll,
}: {
  onSelect: (facility: Facility) => void
  onViewAll: () => void
}) {
  const items = [
    {
      id: "SH-04",
      type: "Shower",
      zone: "Changing Area A",
      status: "Service Required",
      time: "Open for 01:32",
      tone: "attention" as Tone,
    },
    {
      id: "WC-02",
      type: "Toilet",
      zone: "Toilet Area",
      status: "Cleaning",
      time: "Open for 03:20",
      tone: "cleaning" as Tone,
    },
    {
      id: "BIN-02",
      type: "Waste Bin",
      zone: "Vanity Area",
      status: "85% Full",
      time: "SLA breach in 18 min",
      tone: "attention" as Tone,
    },
  ]
  const visibleItems = items
  return (
    <article className="attention-panel">
      <div className="section-head">
        <div>
          <span className="eyebrow">DECISION QUEUE</span>
          <h2>Needs Attention</h2>
        </div>
        <span className="count">{visibleItems.length}</span>
      </div>
      <p className="section-intro">
        Prioritized by urgency and service impact.
      </p>
      <div className="exception-list">
        {visibleItems.map((item, index) => (
          <button
            key={item.id}
            onClick={() =>
              onSelect(facilities.find((facility) => facility.id === item.id)!)
            }
          >
            <span className={`priority-bar ${item.tone}`} />
            <span className="exception-rank">0{index + 1}</span>
            <span className="exception-main">
              <strong>{item.id}</strong>
              <small>
                {item.type} · {item.zone}
              </small>
              <span>{item.status}</span>
            </span>
            <span className="exception-time">
              {item.time}
              <Icon name="chevron" size={16} />
            </span>
          </button>
        ))}
        {visibleItems.length === 0 && (
          <div className="compact-empty">
            <strong>All Clear</strong>
            <span>No tasks require attention.</span>
          </div>
        )}
      </div>
      <button className="text-link full" onClick={onViewAll}>
        View all exceptions <Icon name="arrow" size={14} />
      </button>
    </article>
  )
}

function PerformanceChart() {
  const [hovered, setHovered] = useState(false)
  const [range, setRange] = useState("Today")
  const average =
    range === "Today" ? "01:48" : range === "7 days" ? "01:53" : "01:57"
  const insight =
    range === "Today"
      ? "12% faster than target"
      : range === "7 days"
        ? "7% faster than target"
        : "3% faster than target"
  return (
    <article className="chart-panel">
      <div className="section-head">
        <div>
          <span className="eyebrow">TODAY · 08:00—NOW</span>
          <h2>Response Performance</h2>
        </div>
        <Dropdown
          value={range}
          options={["Today", "7 days", "30 days"]}
          onChange={setRange}
        />
      </div>
      <div className="chart-metric">
        <strong>{average}</strong>
        <span>Average response</span>
        <em>{insight}</em>
      </div>
      <div
        className="chart"
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
      >
        <span className="axis top">03:00</span>
        <span className="axis middle">02:00</span>
        <span className="axis bottom">01:00</span>
        <svg
          viewBox="0 0 800 180"
          preserveAspectRatio="none"
          aria-label="Response performance line chart"
        >
          <defs>
            <linearGradient id="chartFill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stopColor="var(--yellow)" stopOpacity=".16" />
              <stop offset="1" stopColor="var(--yellow)" stopOpacity="0" />
            </linearGradient>
          </defs>
          <path className="grid-line" d="M0 45h800M0 90h800M0 135h800" />
          <path className="target-line" d="M0 91h800" />
          <path
            className="area"
            d="M0 106C60 100 82 70 139 83s85 43 139 25 74-50 132-31 80 59 140 40 71-55 129-31 69 31 121 12 65-35 100-29v111H0Z"
          />
          <path
            className="actual-line"
            d="M0 106C60 100 82 70 139 83s85 43 139 25 74-50 132-31 80 59 140 40 71-55 129-31 69 31 121 12 65-35 100-29"
          />
          <line
            className={`hover-line ${hovered ? "show" : ""}`}
            x1="520"
            y1="22"
            x2="520"
            y2="160"
          />
          <circle
            className={`chart-point ${hovered ? "show" : ""}`}
            cx="520"
            cy="110"
            r="5"
          />
        </svg>
        <div className={`chart-tooltip ${hovered ? "show" : ""}`}>
          <b>10:24 AM</b>
          <span>
            Response <strong>01:42</strong>
          </span>
          <span>
            Target <strong>02:00</strong>
          </span>
          <em>18 sec faster</em>
        </div>
        <div className="chart-labels">
          <span>08:00</span>
          <span>09:00</span>
          <span>10:00</span>
          <span>11:00</span>
          <span>12:00</span>
        </div>
      </div>
    </article>
  )
}

function ActivityPanel({
  onFocus,
}: {
  onFocus: (facilityId: string) => void
}) {
  const [expanded, setExpanded] = useState(false)
  const rows = [
    ["10:24", "SH-04", "Service requested", "attention"],
    ["10:18", "BIN-02", "Reached 85% fill", "attention"],
    ["10:12", "SH-01", "Service completed", "ready"],
    ["10:06", "WC-03", "Device signal lost", "critical"],
    ["09:58", "BIN-01", "Bin service completed", "ready"],
    ["09:46", "WC-02", "Cleaning accepted", "cleaning"],
  ]
  return (
    <article className="activity-panel">
      <div className="section-head">
        <div>
          <span className="eyebrow">AWARENESS</span>
          <h2>Live Activity</h2>
        </div>
        <Status tone="ready">Live</Status>
      </div>
      <div className="activity-list">
        {rows
          .slice(0, expanded ? rows.length : 4)
          .map(([time, id, text, tone]) => (
            <button
              className="activity-event"
              key={`${time}${id}`}
              onClick={() => onFocus(id)}
            >
              <time>{time}</time>
              <i className={tone} />
              <span>
                <strong>{id}</strong>
                {text}
              </span>
            </button>
          ))}
      </div>
      <button className="text-link full" onClick={() => setExpanded(!expanded)}>
        {expanded ? "Show recent activity" : "View all activity"}{" "}
        <Icon name="arrow" size={14} />
      </button>
    </article>
  )
}

function ExcellenceCenter({
  navigate,
  context,
  focusFacility,
  openTask,
}: {
  navigate: (page: Page) => void
  context: OperationalContext
  focusFacility: string | null
  openTask: (taskId: string) => void
}) {
  const [selected, setSelected] = useState<Facility | null>(null)
  const [attentionOnly, setAttentionOnly] = useState(false)
  useEffect(() => {
    if (!focusFacility) return
    const facility = facilities.find((item) => item.id === focusFacility)
    if (facility) {
      setSelected(facility)
      setAttentionOnly(false)
    }
  }, [focusFacility])
  const selectException = (facility: Facility) => {
    setAttentionOnly(true)
    setSelected(facility)
  }
  const focusInTwin = (facilityId: string) => {
    const facility = facilities.find((item) => item.id === facilityId)
    if (facility) {
      setAttentionOnly(false)
      setSelected(facility)
    }
  }
  return (
    <div className="dashboard">
      <SummaryRow
        onFilter={() => setAttentionOnly(!attentionOnly)}
        openTasks={() => navigate("Tasks")}
      />
      <section className="primary-grid">
        <OperationsMap
          selected={selected}
          setSelected={setSelected}
          attentionOnly={attentionOnly}
          setAttentionOnly={setAttentionOnly}
          openTask={() =>
            openTask(
              selected?.id === "WC-02"
                ? "TSK-1047"
                : selected?.id === "BIN-02"
                  ? "TSK-1046"
                  : "TSK-1048",
            )
          }
          context={context}
        />
        <AttentionQueue
          onSelect={selectException}
          onViewAll={() => navigate("Tasks")}
        />
      </section>
      <section className="secondary-grid">
        <PerformanceChart />
        <ActivityPanel onFocus={focusInTwin} />
      </section>
    </div>
  )
}

const taskRows = [
  [
    "TSK-1048",
    "SH-04",
    "Changing Area A",
    "Clean shower",
    "Urgent",
    "Rami Hassan",
    "Sensor",
    "Accepted",
    "06:30",
  ],
  [
    "TSK-1047",
    "WC-02",
    "Toilet Area",
    "Routine cleaning",
    "High",
    "Omar Khalid",
    "Threshold",
    "In Progress",
    "12 min",
  ],
  [
    "TSK-1046",
    "BIN-02",
    "Vanity Area",
    "Empty waste bin",
    "Medium",
    "Sara Ali",
    "Sensor",
    "New",
    "18 min",
  ],
  [
    "TSK-1045",
    "SH-07",
    "Changing Room B",
    "Post-use service",
    "Medium",
    "Sara Omar",
    "Sensor",
    "Accepted",
    "46 min",
  ],
  [
    "TSK-1044",
    "PL-03",
    "Pool",
    "Replenish towels",
    "Low",
    "N. Faisal",
    "Manual",
    "Completed",
    "Met",
  ],
  [
    "TSK-1043",
    "TC-08",
    "Personal Training",
    "Inspect cubicle",
    "Low",
    "N. Faisal",
    "Schedule",
    "Completed",
    "Met",
  ],
  [
    "TSK-1042",
    "WB-06",
    "Lounge",
    "Empty waste bin",
    "Medium",
    "Sara Omar",
    "Sensor",
    "Blocked",
    "Breached",
  ],
  [
    "TSK-1041",
    "SH-01",
    "Shower Area",
    "Post-use service",
    "Medium",
    "Ahmed Hassan",
    "Manual",
    "Canceled",
    "—",
  ],
]

function PageToolbar({
  action,
  onAction,
  query,
  setQuery,
  onFilter,
}: {
  action: string
  onAction?: () => void
  query?: string
  setQuery?: (value: string) => void
  onFilter?: () => void
}) {
  return (
    <div className="page-toolbar">
      <label className="search">
        <Icon name="search" size={17} />
        <input
          placeholder="Search facilities, tasks or people"
          value={query}
          onChange={(event) => setQuery?.(event.target.value)}
        />
      </label>
      <div className="toolbar-actions">
        <Button icon="filter" onClick={onFilter}>
          Filters
        </Button>
        <Button kind="primary" icon="plus" onClick={onAction}>
          {action}
        </Button>
      </div>
    </div>
  )
}

function TasksPage({
  focusTask,
  locateFacility,
}: {
  focusTask: string | null
  locateFacility: (facilityId: string) => void
}) {
  const [selectedTask, setSelectedTask] = useState<string | null>(null)
  const [creating, setCreating] = useState(false)
  const [query, setQuery] = useState("")
  const [activeStatus, setActiveStatus] = useState("All")
  const [filterOpen, setFilterOpen] = useState(false)
  const [zone, setZone] = useState("All Zones")
  const [priority, setPriority] = useState("All Priorities")
  const [page, setPage] = useState(1)
  const [descending, setDescending] = useState(true)
  useEffect(() => {
    if (focusTask) setSelectedTask(focusTask)
  }, [focusTask])
  const visibleTasks = taskRows
    .filter((row) => row.join(" ").toLowerCase().includes(query.toLowerCase()))
    .filter((row) => activeStatus === "All" || row[7] === activeStatus)
    .filter((row) => zone === "All Zones" || row[2].includes(zone))
    .filter((row) => priority === "All Priorities" || row[4] === priority)
    .sort((a, b) =>
      descending ? b[0].localeCompare(a[0]) : a[0].localeCompare(b[0]),
    )
  const pageRows = visibleTasks.slice((page - 1) * 5, page * 5)
  const totalPages = Math.max(1, Math.ceil(visibleTasks.length / 5))
  return (
    <div className="content-page">
      <div className="page-stats">
        <Stat
          label="Open tasks"
          value="6"
          detail="2 need assignment"
          tone="attention"
        />
        <Stat
          label="Within response SLA"
          value="96%"
          detail="24 of 25 today"
          tone="ready"
        />
        <Stat
          label="Avg. completion"
          value="08:42"
          detail="1m 18s faster"
          tone="ready"
        />
        <Stat
          label="Blocked"
          value="1"
          detail="Awaiting maintenance"
          tone="critical"
        />
      </div>
      <article className="data-surface">
        <PageToolbar
          action="Create Manual Task"
          onAction={() => setCreating(true)}
          query={query}
          setQuery={(value) => {
            setQuery(value)
            setPage(1)
          }}
          onFilter={() => setFilterOpen(!filterOpen)}
        />
        {filterOpen && (
          <div className="filter-panel">
            <Dropdown
              label="ZONE"
              value={zone}
              options={[
                "All Zones",
                "Changing Room",
                "Functional Training",
                "Pool",
                "Lounge",
              ]}
              onChange={(value) => {
                setZone(value)
                setPage(1)
              }}
            />
            <Dropdown
              label="PRIORITY"
              value={priority}
              options={["All Priorities", "Urgent", "High", "Medium", "Low"]}
              onChange={(value) => {
                setPriority(value)
                setPage(1)
              }}
            />
            <Button
              kind="ghost"
              onClick={() => {
                setZone("All Zones")
                setPriority("All Priorities")
              }}
            >
              Clear Filters
            </Button>
          </div>
        )}
        <div className="chips">
          {[
            "All",
            "New",
            "Accepted",
            "In Progress",
            "Blocked",
            "Completed",
            "Canceled",
          ].map((status) => (
            <button
              className={activeStatus === status ? "active" : ""}
              key={status}
              onClick={() => {
                setActiveStatus(status)
                setPage(1)
              }}
            >
              {status}{" "}
              {status === "All"
                ? taskRows.length
                : taskRows.filter((row) => row[7] === status).length}
            </button>
          ))}
        </div>
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                {[
                  "Task ID",
                  "Facility",
                  "Location",
                  "Type",
                  "Priority",
                  "Assignee",
                  "Source",
                  "Status",
                  "Response SLA",
                  "",
                ].map((head) => (
                  <th
                    key={head}
                    onClick={
                      head === "Task ID"
                        ? () => setDescending(!descending)
                        : undefined
                    }
                    className={head === "Task ID" ? "sortable" : ""}
                  >
                    {head}
                    {head === "Task ID" ? (descending ? " ↓" : " ↑") : ""}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {pageRows.map((row) => (
                <tr key={row[0]} onClick={() => setSelectedTask(row[0])}>
                  {row.map((cell, index) => (
                    <td key={index}>
                      {index === 0 ? (
                        <strong>{cell}</strong>
                      ) : index === 4 ? (
                        <Status
                          tone={
                            cell === "Urgent"
                              ? "critical"
                              : cell === "High"
                                ? "attention"
                                : "muted"
                          }
                        >
                          {cell}
                        </Status>
                      ) : index === 7 ? (
                        <Status
                          tone={
                            cell === "Completed"
                              ? "ready"
                              : cell === "New"
                                ? "attention"
                                : "cleaning"
                          }
                        >
                          {cell}
                        </Status>
                      ) : (
                        cell
                      )}
                    </td>
                  ))}
                  <td>
                    <button className="icon-button compact">
                      <Icon name="more" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {visibleTasks.length === 0 && (
            <div className="empty-state">
              <Icon name="search" size={24} />
              <strong>No search results</strong>
              <span>Try a facility ID, task ID, or employee name.</span>
              <Button
                kind="ghost"
                onClick={() => {
                  setQuery("")
                  setActiveStatus("All")
                  setZone("All Zones")
                  setPriority("All Priorities")
                }}
              >
                Clear search
              </Button>
            </div>
          )}
        </div>
        <div className="pagination">
          <span>
            Showing {visibleTasks.length ? (page - 1) * 5 + 1 : 0}–
            {Math.min(page * 5, visibleTasks.length)} of {visibleTasks.length}{" "}
            tasks
          </span>
          <div>
            <Button
              kind="ghost"
              disabled={page === 1}
              onClick={() => setPage(Math.max(1, page - 1))}
            >
              Previous
            </Button>
            <Button
              kind="secondary"
              disabled={page === totalPages}
              onClick={() => setPage(Math.min(totalPages, page + 1))}
            >
              Next
            </Button>
          </div>
        </div>
      </article>
      {selectedTask && (
        <DetailDrawer
          type="Task Detail"
          title={selectedTask}
          onClose={() => setSelectedTask(null)}
          onLocate={locateFacility}
        />
      )}
      {creating && <TaskForm onClose={() => setCreating(false)} />}
    </div>
  )
}

function TaskForm({ onClose }: { onClose: () => void }) {
  const [submitted, setSubmitted] = useState(false)
  const [facility, setFacility] = useState("")
  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div
        className="action-modal"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="drawer-head">
          <div>
            <span className="eyebrow">MANUAL TASK</span>
            <h2>Create operational task</h2>
          </div>
          <button className="icon-button compact" onClick={onClose}>
            <Icon name="close" />
          </button>
        </div>
        {submitted ? (
          <div className="form-success">
            <span className="success-mark">✓</span>
            <h3>Task created</h3>
            <p>The task is ready for assignment and SLA tracking.</p>
            <Button kind="primary" onClick={onClose}>
              View Task
            </Button>
          </div>
        ) : (
          <>
            <div className="form-grid">
              <label className="field">
                <span>Facility *</span>
                <input
                  value={facility}
                  onChange={(event) => setFacility(event.target.value)}
                  placeholder="e.g. SH-04"
                />
              </label>
              <label className="field">
                <span>Task Type *</span>
                <input placeholder="Cleaning" />
              </label>
              <label className="field">
                <span>Priority</span>
                <input placeholder="High" />
              </label>
              <label className="field">
                <span>Assignee</span>
                <input placeholder="Select employee" />
              </label>
              <label className="field full">
                <span>Description</span>
                <textarea placeholder="Add concise operational context" />
              </label>
            </div>
            <div className="modal-actions">
              <Button kind="ghost" onClick={onClose}>
                Cancel
              </Button>
              <Button
                kind="primary"
                onClick={() => {
                  if (facility) setSubmitted(true)
                }}
              >
                Create Task
              </Button>
            </div>
          </>
        )}
      </div>
    </div>
  )
}

function Stat({
  label,
  value,
  detail,
  tone,
}: {
  label: string
  value: string
  detail: string
  tone: Tone
}) {
  return (
    <div className="stat">
      <span>{label}</span>
      <strong>{value}</strong>
      <small className={tone}>{detail}</small>
    </div>
  )
}

function SchedulePage() {
  const [selectedItem, setSelectedItem] = useState<string | null>(null)
  const [view, setView] = useState<"Day" | "Week">("Day")
  const [dayOffset, setDayOffset] = useState(0)
  const [creating, setCreating] = useState(false)
  const schedule = [
    ["08:00", "Routine Cleaning", "Changing Rooms", "Sara Omar", "Completed"],
    ["10:30", "Facility Inspection", "Pool", "N. Faisal", "In Progress"],
    ["12:00", "Replenishment", "Lounge", "Ahmed Hassan", "Upcoming"],
    [
      "14:30",
      "Routine Cleaning",
      "Functional Training",
      "M. Khalid",
      "Upcoming",
    ],
    ["18:00", "Deep Cleaning", "Showers", "Evening Team", "Upcoming"],
  ]
  return (
    <div className="content-page">
      <div className="schedule-toolbar">
        <div className="date-nav">
          <Button kind="ghost" onClick={() => setDayOffset(0)}>
            Today
          </Button>
          <button
            className="icon-button compact"
            onClick={() => setDayOffset(dayOffset - 1)}
          >
            ‹
          </button>
          <strong>
            {dayOffset === 0
              ? "Monday, 24 June"
              : dayOffset > 0
                ? `Tuesday, ${24 + dayOffset} June`
                : `Sunday, ${24 + dayOffset} June`}
          </strong>
          <button
            className="icon-button compact"
            onClick={() => setDayOffset(dayOffset + 1)}
          >
            ›
          </button>
          <div className="view-switch">
            <button
              className={view === "Day" ? "active" : ""}
              onClick={() => setView("Day")}
            >
              Day
            </button>
            <button
              className={view === "Week" ? "active" : ""}
              onClick={() => setView("Week")}
            >
              Week
            </button>
          </div>
        </div>
        <Button kind="primary" icon="plus" onClick={() => setCreating(true)}>
          Schedule Work
        </Button>
      </div>
      <section className="schedule-layout">
        <article className="calendar">
          <div className="calendar-head">
            <span>MON 24</span>
            <span>Operational schedule</span>
            <span>5 items</span>
          </div>
          {(view === "Day"
            ? schedule
            : [
                ...schedule,
                [
                  "TUE 09:00",
                  "Current Shift",
                  "All Zones",
                  "Ahmed Hassan",
                  "Upcoming",
                ],
                [
                  "WED 18:00",
                  "Deep Cleaning",
                  "Pool",
                  "Evening Team",
                  "Upcoming",
                ],
              ]
          ).map(([time, title, zone, person, status]) => (
            <div
              className="schedule-row"
              key={time}
              onClick={() => setSelectedItem(title)}
            >
              <time>{time}</time>
              <i />
              <div>
                <strong>{title}</strong>
                <span>{zone}</span>
              </div>
              <span>{person}</span>
              <Status
                tone={
                  status === "Completed"
                    ? "ready"
                    : status === "In Progress"
                      ? "cleaning"
                      : "muted"
                }
              >
                {status}
              </Status>
              <button className="icon-button compact">
                <Icon name="more" />
              </button>
            </div>
          ))}
        </article>
        <aside className="day-summary">
          <span className="eyebrow">TODAY</span>
          <h2>Schedule coverage</h2>
          <div className="coverage">
            <strong>92%</strong>
            <span>All critical zones covered</span>
          </div>
          <dl>
            <div>
              <dt>Scheduled</dt>
              <dd>12</dd>
            </div>
            <div>
              <dt>Completed</dt>
              <dd>7</dd>
            </div>
            <div>
              <dt>Remaining</dt>
              <dd>5</dd>
            </div>
          </dl>
          <div className="next-work">
            <span>NEXT ROUTINE</span>
            <strong>Replenishment</strong>
            <small>12:00 · Lounge</small>
          </div>
        </aside>
      </section>
      {selectedItem && (
        <DetailDrawer
          type="Schedule Detail"
          title={selectedItem}
          onClose={() => setSelectedItem(null)}
        />
      )}
      {creating && <ScheduleForm onClose={() => setCreating(false)} />}
    </div>
  )
}

function ScheduleForm({ onClose }: { onClose: () => void }) {
  const [saved, setSaved] = useState(false)
  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div
        className="action-modal"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="drawer-head">
          <div>
            <span className="eyebrow">OPERATIONAL ROUTINE</span>
            <h2>Schedule Work</h2>
          </div>
          <button className="icon-button compact" onClick={onClose}>
            <Icon name="close" />
          </button>
        </div>
        {saved ? (
          <div className="form-success">
            <span className="success-mark">✓</span>
            <h3>Work scheduled</h3>
            <p>The routine is now visible to the assigned team.</p>
            <Button kind="primary" onClick={onClose}>
              Done
            </Button>
          </div>
        ) : (
          <>
            <div className="form-grid">
              <label className="field">
                <span>Routine Type *</span>
                <Dropdown
                  value="Routine Cleaning"
                  options={[
                    "Routine Cleaning",
                    "Inspection",
                    "Replenishment",
                    "Deep Cleaning",
                  ]}
                />
              </label>
              <label className="field">
                <span>Zone *</span>
                <Dropdown
                  value="Changing Rooms"
                  options={[
                    "Changing Rooms",
                    "Pool",
                    "Functional Training",
                    "Lounge",
                  ]}
                />
              </label>
              <label className="field">
                <span>Date *</span>
                <input type="date" defaultValue="2025-06-24" />
              </label>
              <label className="field">
                <span>Time *</span>
                <input type="time" defaultValue="12:00" />
              </label>
              <label className="field">
                <span>Assignee *</span>
                <Dropdown
                  value="Sara Omar · Available"
                  options={[
                    "Sara Omar · Available",
                    "Ahmed Hassan · Available",
                    "M. Khalid · On Task",
                  ]}
                />
              </label>
              <label className="field">
                <span>Recurrence</span>
                <Dropdown value="Once" options={["Once", "Daily", "Weekly"]} />
              </label>
            </div>
            <div className="modal-actions">
              <Button kind="ghost" onClick={onClose}>
                Cancel
              </Button>
              <Button kind="primary" onClick={() => setSaved(true)}>
                Save Schedule
              </Button>
            </div>
          </>
        )}
      </div>
    </div>
  )
}

const team = [
  [
    "AH",
    "Ahmed Hassan",
    "Duty Manager",
    "All zones",
    "SH-04 · Service",
    "3",
    "Available",
  ],
  [
    "SO",
    "Sara Omar",
    "Hospitality Associate",
    "Changing Rooms",
    "SH-07 · Cleaning",
    "5",
    "On task",
  ],
  [
    "MK",
    "M. Khalid",
    "Hospitality Associate",
    "Functional Training",
    "TC-05 · Cleaning",
    "4",
    "On task",
  ],
  [
    "NF",
    "N. Faisal",
    "Quality Supervisor",
    "Pool & Lounge",
    "Pool inspection",
    "2",
    "Available",
  ],
]

function TeamPage() {
  const [selectedMember, setSelectedMember] = useState<string | null>(null)
  const [view, setView] = useState<"team" | "shifts">("team")
  const [shiftForm, setShiftForm] = useState(false)
  const [shiftFeedback, setShiftFeedback] = useState("")
  const [query, setQuery] = useState("")
  const [filterOpen, setFilterOpen] = useState(false)
  const [availability, setAvailability] = useState("All Statuses")
  const visibleTeam = team
    .filter((member) =>
      member.join(" ").toLowerCase().includes(query.toLowerCase()),
    )
    .filter(
      (member) => availability === "All Statuses" || member[6] === availability,
    )
  return (
    <div className="content-page">
      <div className="page-stats">
        <Stat
          label="On shift"
          value="12"
          detail="Full planned coverage"
          tone="ready"
        />
        <Stat
          label="Available"
          value="5"
          detail="Ready for assignment"
          tone="ready"
        />
        <Stat
          label="Active tasks"
          value="6"
          detail="Across 4 zones"
          tone="cleaning"
        />
        <Stat
          label="Overdue"
          value="0"
          detail="Service standard met"
          tone="ready"
        />
      </div>
      <article className="data-surface">
        <PageToolbar
          action={view === "team" ? "Manage Shift" : "Create Shift"}
          onAction={() => {
            setView("shifts")
            setShiftForm(true)
          }}
          query={query}
          setQuery={setQuery}
          onFilter={() => setFilterOpen(!filterOpen)}
        />
        {filterOpen && (
          <div className="filter-panel">
            <Dropdown
              label="AVAILABILITY"
              value={availability}
              options={["All Statuses", "Available", "On task"]}
              onChange={setAvailability}
            />
            <Button
              kind="ghost"
              onClick={() => {
                setAvailability("All Statuses")
                setQuery("")
              }}
            >
              Clear Filters
            </Button>
          </div>
        )}
        <div className="chips">
          <button
            className={view === "team" ? "active" : ""}
            onClick={() => setView("team")}
          >
            Current Team
          </button>
          <button
            className={view === "shifts" ? "active" : ""}
            onClick={() => setView("shifts")}
          >
            Shifts
          </button>
        </div>
        {view === "team" ? (
          <div className="team-list">
            <div className="team-list-head">
              <span>Employee</span>
              <span>Assigned zone</span>
              <span>Current work</span>
              <span>Completed</span>
              <span>Status</span>
              <span />
            </div>
            {visibleTeam.map(
              ([initials, name, role, zone, task, done, status]) => (
                <div
                  className="team-row"
                  key={name}
                  onClick={() => setSelectedMember(name)}
                >
                  <div className="person">
                    <b>{initials}</b>
                    <span>
                      <strong>{name}</strong>
                      <small>{role}</small>
                    </span>
                  </div>
                  <span>{zone}</span>
                  <strong>{task}</strong>
                  <span>{done} today</span>
                  <Status tone={status === "Available" ? "ready" : "cleaning"}>
                    {status}
                  </Status>
                  <button className="icon-button compact">
                    <Icon name="more" />
                  </button>
                </div>
              ),
            )}
            {visibleTeam.length === 0 && (
              <div className="empty-state">
                <strong>No search results</strong>
                <span>No team members match these filters.</span>
                <Button
                  kind="ghost"
                  onClick={() => {
                    setQuery("")
                    setAvailability("All Statuses")
                  }}
                >
                  Clear search
                </Button>
              </div>
            )}
          </div>
        ) : (
          <div className="shift-list">
            {[
              [
                "Morning Operations",
                "07:00—15:00",
                "Current Shift",
                "8 employees",
                "Ahmed Hassan",
              ],
              [
                "Evening Hospitality",
                "15:00—23:00",
                "Upcoming",
                "7 employees",
                "Sara Omar",
              ],
              [
                "Night Deep Clean",
                "23:00—03:00",
                "Upcoming",
                "4 employees",
                "M. Khalid",
              ],
            ].map(([name, time, status, employees, supervisor]) => (
              <div
                key={name}
                className="shift-row"
                onClick={() => setShiftForm(true)}
              >
                <span className="shift-time">
                  <bdi>{time}</bdi>
                </span>
                <span>
                  <strong>{name}</strong>
                  <small>
                    {employees} · Supervisor: {supervisor}
                  </small>
                </span>
                <Status tone={status === "Current Shift" ? "ready" : "muted"}>
                  {status}
                </Status>
                <div className="shift-zones">
                  <i>CR</i>
                  <i>PL</i>
                  <i>FT</i>
                </div>
                <button className="icon-button compact">
                  <Icon name="chevron" />
                </button>
              </div>
            ))}
          </div>
        )}
      </article>
      {selectedMember && (
        <DetailDrawer
          type="Team Member"
          title={selectedMember}
          onClose={() => setSelectedMember(null)}
        />
      )}
      {shiftForm && (
        <ShiftForm
          onClose={() => setShiftForm(false)}
          onSaved={() => {
            setShiftForm(false)
            setShiftFeedback("Shift updated")
          }}
        />
      )}
      {shiftFeedback && (
        <Toast message={shiftFeedback} onClose={() => setShiftFeedback("")} />
      )}
    </div>
  )
}

function ShiftForm({
  onClose,
  onSaved,
}: {
  onClose: () => void
  onSaved: () => void
}) {
  const [start, setStart] = useState("07:00")
  const [end, setEnd] = useState("15:00")
  const [employee, setEmployee] = useState("Ahmed Hassan")
  const [zone, setZone] = useState("Changing Rooms")
  const invalid = end <= start
  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div
        className="action-modal"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="drawer-head">
          <div>
            <span className="eyebrow">SHIFT MANAGEMENT</span>
            <h2>Create Shift</h2>
          </div>
          <button className="icon-button compact" onClick={onClose}>
            <Icon name="close" />
          </button>
        </div>
        <div className="form-grid">
          <label className="field full">
            <span>Shift Name *</span>
            <input defaultValue="Morning Operations" />
          </label>
          <label className="field">
            <span>Start Time *</span>
            <input
              type="time"
              value={start}
              onChange={(event) => setStart(event.target.value)}
            />
          </label>
          <label className={`field ${invalid ? "error" : ""}`}>
            <span>End Time *</span>
            <input
              type="time"
              value={end}
              onChange={(event) => setEnd(event.target.value)}
            />
            <small>{invalid ? "End time must be after start time." : ""}</small>
          </label>
          <label className="field">
            <span>Employee *</span>
            <Dropdown
              value={employee}
              options={[
                "Ahmed Hassan · Available",
                "Sara Omar · On Task",
                "M. Khalid · Conflict",
              ]}
              onChange={(value) => setEmployee(value.split(" · ")[0])}
            />
          </label>
          <label className="field">
            <span>Zone Assignment *</span>
            <Dropdown
              value={zone}
              options={[
                "Changing Rooms",
                "Pool",
                "Functional Training",
                "Lounge",
              ]}
              onChange={setZone}
            />
          </label>
          {employee === "M. Khalid" && (
            <div className="conflict-warning full">
              <Status tone="attention">Availability conflict</Status>
              <span>
                M. Khalid is assigned to Functional Training until{" "}
                <bdi>16:00</bdi>.
              </span>
            </div>
          )}
          <label className="field full">
            <span>Operational Notes</span>
            <textarea placeholder="Add shift context if required" />
          </label>
        </div>
        <div className="modal-actions">
          <Button kind="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button
            kind="primary"
            disabled={invalid || employee === "M. Khalid"}
            onClick={onSaved}
          >
            Save Shift
          </Button>
        </div>
      </div>
    </div>
  )
}

function Toast({ message, onClose }: { message: string; onClose: () => void }) {
  useEffect(() => {
    const timer = window.setTimeout(onClose, 2600)
    return () => window.clearTimeout(timer)
  }, [message])
  return (
    <div className="toast">
      <span>✓</span>
      <strong>{message}</strong>
      <button onClick={onClose}>
        <Icon name="close" size={14} />
      </button>
    </div>
  )
}

function QualityPage() {
  const [selectedInspection, setSelectedInspection] = useState<string | null>(
    null,
  )
  return (
    <div className="content-page">
      <div className="page-stats">
        <Stat
          label="Inspection pass rate"
          value="94%"
          detail="+3% this week"
          tone="ready"
        />
        <Stat
          label="Completed today"
          value="18"
          detail="4 remaining"
          tone="ready"
        />
        <Stat
          label="Rework required"
          value="2"
          detail="Assigned and in progress"
          tone="attention"
        />
        <Stat label="Avg. score" value="9.2" detail="Target 9.0" tone="ready" />
      </div>
      <section className="quality-grid">
        <article className="data-surface standards">
          <div className="section-head">
            <div>
              <span className="eyebrow">TODAY'S INSPECTIONS</span>
              <h2>Quality standards</h2>
            </div>
            <Button
              kind="primary"
              onClick={() => setSelectedInspection("New Inspection")}
            >
              Start Inspection
            </Button>
          </div>
          {[
            ["Changing Rooms", "96%", "Passed", "08:42"],
            ["Pool & Wet Areas", "91%", "Rework", "10:16"],
            ["Training Floors", "98%", "Passed", "09:25"],
            ["Lounge", "89%", "Pending", "—"],
          ].map(([area, score, result, time]) => (
            <div
              className="standard-row"
              key={area}
              onClick={() => setSelectedInspection(area)}
            >
              <span>
                <strong>{area}</strong>
                <small>Hospitality checklist · 12 items</small>
              </span>
              <b>{score}</b>
              <Status
                tone={
                  result === "Passed"
                    ? "ready"
                    : result === "Rework"
                      ? "attention"
                      : "muted"
                }
              >
                {result}
              </Status>
              <time>{time}</time>
              <button className="icon-button compact">
                <Icon name="chevron" />
              </button>
            </div>
          ))}
        </article>
        <aside className="quality-score">
          <span className="eyebrow">7 DAY QUALITY</span>
          <h2>Club standard</h2>
          <div className="large-score">
            9.2<small>/ 10</small>
          </div>
          <p>Quality has remained above target for 6 consecutive days.</p>
          <div className="mini-bars">
            {[76, 84, 82, 91, 88, 94, 92].map((height, index) => (
              <i key={index} style={{ height: `${height}%` }} />
            ))}
          </div>
          <div className="days">
            <span>M</span>
            <span>T</span>
            <span>W</span>
            <span>T</span>
            <span>F</span>
            <span>S</span>
            <span>S</span>
          </div>
        </aside>
      </section>
      {selectedInspection && (
        <DetailDrawer
          type="Inspection Detail"
          title={selectedInspection}
          onClose={() => setSelectedInspection(null)}
        />
      )}
    </div>
  )
}

function IssuesPage() {
  const [selectedIssue, setSelectedIssue] = useState<string | null>(null)
  const [query, setQuery] = useState("")
  const [statusFilter, setStatusFilter] = useState("All")
  const [severityFilter, setSeverityFilter] = useState("All Severities")
  const [filterOpen, setFilterOpen] = useState(false)
  const issues = [
    [
      "ISS-203",
      "Leakage",
      "Shower SH-09",
      "High",
      "Open",
      "11 min ago",
      "Facilities Team",
    ],
    [
      "ISS-202",
      "Damaged fitting",
      "Changing Room B",
      "Medium",
      "In Progress",
      "42 min ago",
      "M. Khalid",
    ],
    [
      "ISS-201",
      "Missing supplies",
      "Lounge",
      "Low",
      "Resolved",
      "1h 18m ago",
      "Sara Omar",
    ],
    [
      "ISS-198",
      "Facility fault",
      "Pool shower",
      "High",
      "Blocked",
      "2h 06m ago",
      "Maintenance",
    ],
  ]
  const visibleIssues = issues
    .filter((issue) =>
      issue.join(" ").toLowerCase().includes(query.toLowerCase()),
    )
    .filter((issue) => statusFilter === "All" || issue[4] === statusFilter)
    .filter(
      (issue) =>
        severityFilter === "All Severities" || issue[3] === severityFilter,
    )
  return (
    <div className="content-page">
      <article className="data-surface">
        <PageToolbar
          action="Report Issue"
          onAction={() => setSelectedIssue("New Issue")}
          query={query}
          setQuery={setQuery}
          onFilter={() => setFilterOpen(!filterOpen)}
        />
        {filterOpen && (
          <div className="filter-panel">
            <Dropdown
              label="SEVERITY"
              value={severityFilter}
              options={["All Severities", "High", "Medium", "Low"]}
              onChange={setSeverityFilter}
            />
            <Button
              kind="ghost"
              onClick={() => setSeverityFilter("All Severities")}
            >
              Clear Filters
            </Button>
          </div>
        )}
        <div className="chips">
          {[
            "All issues 14",
            "Open 3",
            "In Progress 2",
            "Blocked 1",
            "Resolved 8",
          ].map((chip) => {
            const status = chip.startsWith("All")
              ? "All"
              : chip.replace(/\s\d+$/, "")
            return (
              <button
                className={statusFilter === status ? "active" : ""}
                key={chip}
                onClick={() => setStatusFilter(status)}
              >
                {chip}
              </button>
            )
          })}
        </div>
        <div className="issue-list">
          {visibleIssues.map(
            ([id, type, location, severity, status, time, owner]) => (
              <div
                className="issue-row"
                key={id}
                onClick={() => setSelectedIssue(id)}
              >
                <Status
                  tone={
                    severity === "High"
                      ? "critical"
                      : severity === "Medium"
                        ? "attention"
                        : "muted"
                  }
                >
                  {severity}
                </Status>
                <div>
                  <span>{id}</span>
                  <strong>{type}</strong>
                  <small>{location}</small>
                </div>
                <div>
                  <span>STATUS</span>
                  <Status
                    tone={
                      status === "Resolved"
                        ? "ready"
                        : status === "Blocked"
                          ? "critical"
                          : "cleaning"
                    }
                  >
                    {status}
                  </Status>
                </div>
                <div>
                  <span>REPORTED</span>
                  <strong>{time}</strong>
                </div>
                <div>
                  <span>OWNER</span>
                  <strong>{owner}</strong>
                </div>
                <button className="icon-button compact">
                  <Icon name="chevron" />
                </button>
              </div>
            ),
          )}
          {visibleIssues.length === 0 && (
            <div className="empty-state">
              <Icon name="search" size={24} />
              <strong>No search results</strong>
              <span>No issues match these filters.</span>
              <Button
                kind="ghost"
                onClick={() => {
                  setQuery("")
                  setStatusFilter("All")
                  setSeverityFilter("All Severities")
                }}
              >
                Clear search
              </Button>
            </div>
          )}
        </div>
      </article>
      {selectedIssue && (
        <DetailDrawer
          type="Issue Detail"
          title={selectedIssue}
          onClose={() => setSelectedIssue(null)}
        />
      )}
    </div>
  )
}

function ReportsPage() {
  const [period, setPeriod] = useState("Last 30 days")
  const [zone, setZone] = useState("All Zones")
  const [facilityType, setFacilityType] = useState("All Facilities")
  const [exported, setExported] = useState(false)
  const response =
    period === "Last 7 days" ? "01:46" : zone === "Pool" ? "01:38" : "01:52"
  const compliance =
    facilityType === "Waste Bins"
      ? "92.4%"
      : zone === "Changing Rooms"
        ? "94.9%"
        : "95.8%"
  return (
    <div className="content-page">
      <div className="report-filters">
        <Dropdown
          label="PERIOD"
          value={period}
          options={["Last 7 days", "Last 30 days", "This quarter"]}
          onChange={setPeriod}
        />
        <Dropdown
          label="ZONE"
          value={zone}
          options={["All Zones", "Changing Rooms", "Pool", "Training"]}
          onChange={setZone}
        />
        <Dropdown
          label="FACILITY"
          value={facilityType}
          options={["All Facilities", "Showers", "Toilets", "Waste Bins"]}
          onChange={setFacilityType}
        />
        <Button onClick={() => setExported(true)}>Export report</Button>
      </div>
      <div className="page-stats">
        <Stat
          label="SLA performance"
          value={compliance}
          detail="+2.4% vs prior period"
          tone="ready"
        />
        <Stat
          label="Average response"
          value={response}
          detail="8 sec inside target"
          tone="ready"
        />
        <Stat
          label="Tasks completed"
          value="684"
          detail="+6.2% this period"
          tone="ready"
        />
        <Stat
          label="Facility downtime"
          value="2h 18m"
          detail="-14% this period"
          tone="ready"
        />
      </div>
      <section className="reports-grid">
        <PerformanceChart key={`${period}-${zone}-${facilityType}`} />
        <article className="report-breakdown">
          <span className="eyebrow">BY FACILITY TYPE</span>
          <h2>Service standard</h2>
          {[
            ["Showers", "97%", 97],
            ["Toilets", "95%", 95],
            ["Waste Bins", "92%", 92],
            ["Pool Facilities", "98%", 98],
          ].map(([name, value, width]) => (
            <div className="breakdown-row" key={name as string}>
              <span>{name}</span>
              <strong>{value}</strong>
              <i>
                <b style={{ width: `${width}%` }} />
              </i>
            </div>
          ))}
        </article>
      </section>
      {exported && (
        <Toast message="Export ready" onClose={() => setExported(false)} />
      )}
    </div>
  )
}

function SettingsPage() {
  const [section, setSection] = useState("Locations & Zones")
  const [query, setQuery] = useState("")
  const [deviceStatus, setDeviceStatus] = useState("All Statuses")
  const [selectedSetting, setSelectedSetting] = useState<string | null>(null)
  const [threshold, setThreshold] = useState("80")
  const [feedback, setFeedback] = useState("")
  const sections = [
    "Locations & Zones",
    "Users",
    "Roles & Permissions",
    "Facilities & Devices",
    "Operational Thresholds",
    "SLA Rules",
    "Notifications & Alerts",
    "Standard Operating Procedures",
    "Language & Localization",
  ]
  const standardItems: Record<string, string[]> = {
    "Locations & Zones": [
      "Main Club",
      "Level 01",
      "Changing Rooms",
      "Pool & Wet Areas",
      "Functional Training",
    ],
    Users: ["Ahmed Hassan", "Sara Omar", "M. Khalid", "N. Faisal"],
    "Roles & Permissions": [
      "Duty Manager",
      "Operations Manager",
      "Supervisor",
      "Administrator",
    ],
    "SLA Rules": [
      "Service Response · 30 min",
      "Cleaning Completion · 45 min",
      "Critical Issue · 10 min",
    ],
    "Notifications & Alerts": [
      "Service Required",
      "SLA Approaching",
      "Device Offline",
      "Inspection Failed",
    ],
    "Standard Operating Procedures": [
      "Shower Service SOP",
      "Waste Bin Service SOP",
      "Quality Inspection SOP",
    ],
    "Language & Localization": [
      "English",
      "العربية",
      "Saudi Arabia · Asia/Riyadh",
    ],
  }
  const devices = [
    [
      "SNS-SH04",
      "Occupancy sensor",
      "SH-04 · Changing Area A",
      "Online",
      "Now",
    ],
    [
      "SNS-WC02",
      "Usage sensor",
      "WC-02 · Toilet Area",
      "Delayed",
      "6 min ago",
    ],
    ["SNS-BIN02", "Fill sensor", "BIN-02 · Vanity Area", "Online", "Now"],
    ["SNS-WC03", "Occupancy sensor", "WC-03 · Toilet Area", "Offline", "28 min ago"],
  ]
    .filter((row) => row.join(" ").toLowerCase().includes(query.toLowerCase()))
    .filter((row) => deviceStatus === "All Statuses" || row[3] === deviceStatus)
  return (
    <div className="settings-layout">
      <aside>
        {sections.map((item) => (
          <button
            className={item === section ? "active" : ""}
            key={item}
            onClick={() => setSection(item)}
          >
            {item}
            <Icon name="chevron" size={15} />
          </button>
        ))}
      </aside>
      <article className="settings-panel">
        <div className="settings-heading">
          <div>
            <span className="eyebrow">CONFIGURATION</span>
            <h2>{section}</h2>
            <p>
              Manage the operational structure and rules used across Main Club.
            </p>
          </div>
          <Button
            kind="primary"
            icon="plus"
            onClick={() => setSelectedSetting(`New ${section}`)}
          >
            Add {section.split(" ")[0]}
          </Button>
        </div>
        {section === "Facilities & Devices" ? (
          <div className="device-settings">
            <div className="settings-tools">
              <label className="search">
                <Icon name="search" size={16} />
                <input
                  placeholder="Search devices or facilities"
                  value={query}
                  onChange={(event) => setQuery(event.target.value)}
                />
              </label>
              <Dropdown
                value={deviceStatus}
                options={["All Statuses", "Online", "Delayed", "Offline"]}
                onChange={setDeviceStatus}
              />
            </div>
            <div className="device-table">
              <div className="device-row header">
                <span>Device ID</span>
                <span>Type</span>
                <span>Connected Facility</span>
                <span>Connectivity</span>
                <span>Last update</span>
              </div>
              {devices.map(([id, type, connected, status, update]) => (
                <button
                  className="device-row"
                  key={id}
                  onClick={() => setSelectedSetting(id)}
                >
                  <bdi>{id}</bdi>
                  <span>{type}</span>
                  <span>
                    <bdi>{connected}</bdi>
                  </span>
                  <Status
                    tone={
                      status === "Online"
                        ? "ready"
                        : status === "Offline"
                          ? "critical"
                          : "attention"
                    }
                  >
                    {status}
                  </Status>
                  <bdi>{update}</bdi>
                </button>
              ))}
            </div>
            {devices.length === 0 && (
              <div className="empty-state">
                <strong>No search results</strong>
                <span>No devices match these filters.</span>
                <Button
                  kind="ghost"
                  onClick={() => {
                    setQuery("")
                    setDeviceStatus("All Statuses")
                  }}
                >
                  Clear search
                </Button>
              </div>
            )}
          </div>
        ) : section === "Operational Thresholds" ? (
          <div className="threshold-settings">
            <div className="setting-control">
              <span>
                <strong>Waste Bin Service Threshold</strong>
                <small>
                  Create a service task when fill reaches this level.
                </small>
              </span>
              <label>
                <input
                  value={threshold}
                  onChange={(event) =>
                    setThreshold(
                      event.target.value.replace(/\D/g, "").slice(0, 2),
                    )
                  }
                />
                <b>%</b>
              </label>
            </div>
            <div className="setting-control">
              <span>
                <strong>Toilet Usage Threshold</strong>
                <small>
                  Request cleaning after the defined number of uses.
                </small>
              </span>
              <label>
                <input defaultValue="18" />
                <b>uses</b>
              </label>
            </div>
            <div className="settings-save">
              <Button kind="ghost" onClick={() => setThreshold("80")}>
                Cancel
              </Button>
              <Button
                kind="primary"
                disabled={!threshold || Number(threshold) > 95}
                onClick={() => setFeedback("Changes saved successfully.")}
              >
                Save Changes
              </Button>
            </div>
          </div>
        ) : (
          <div className="settings-list">
            {(standardItems[section] ?? []).map((name, index) => (
              <div key={name} onClick={() => setSelectedSetting(name)}>
                <span className="settings-icon">
                  <Icon name={index === 0 ? "Excellence Center" : "Settings"} />
                </span>
                <span>
                  <strong>{name}</strong>
                  <small>
                    {index === 0
                      ? "Primary club · Riyadh"
                      : `${8 + index * 5} monitored facilities`}
                  </small>
                </span>
                <Status tone="ready">Active</Status>
                <button className="icon-button compact">
                  <Icon name="more" />
                </button>
              </div>
            ))}
          </div>
        )}
      </article>
      {selectedSetting && (
        <DetailDrawer
          type={
            section === "Facilities & Devices"
              ? "Device Detail"
              : "Settings Detail"
          }
          title={selectedSetting}
          onClose={() => setSelectedSetting(null)}
        />
      )}
      {feedback && <Toast message={feedback} onClose={() => setFeedback("")} />}
    </div>
  )
}

function SecondaryPage({
  page,
  focusTask,
  locateFacility,
}: {
  page: Page
  focusTask: string | null
  locateFacility: (facilityId: string) => void
}) {
  if (page === "Tasks")
    return (
      <TasksPage
        focusTask={focusTask}
        locateFacility={locateFacility}
      />
    )
  if (page === "Schedule") return <SchedulePage />
  if (page === "Team") return <TeamPage />
  if (page === "Quality") return <QualityPage />
  if (page === "Issues") return <IssuesPage />
  if (page === "Reports") return <ReportsPage />
  return <SettingsPage />
}

export default function App() {
  const [authenticated, setAuthenticated] = useState(false)
  const [language, setLanguage] = useState<Language>("en")
  const [page, setPage] = useState<Page>("Excellence Center")
  const [context] = useState<OperationalContext>({
    club: "Main Club",
    level: "Ground Floor",
    zone: "Washroom / Changing Area",
  })
  const [focusFacility, setFocusFacility] = useState<string | null>(null)
  const [focusTask, setFocusTask] = useState<string | null>(null)
  const root = useArabicTranslation(language, page)
  const content = useMemo(
    () =>
      page === "Excellence Center" ? (
        <ExcellenceCenter
          navigate={setPage}
          context={context}
          focusFacility={focusFacility}
          openTask={(taskId) => {
            setFocusTask(taskId)
            setPage("Tasks")
          }}
        />
      ) : (
        <SecondaryPage
          page={page}
          focusTask={focusTask}
          locateFacility={(facilityId) => {
            setFocusFacility(facilityId)
            setPage("Excellence Center")
          }}
        />
      ),
    [page, context, focusFacility, focusTask],
  )
  if (!authenticated)
    return (
      <Login
        language={language}
        setLanguage={setLanguage}
        onSuccess={() => setAuthenticated(true)}
      />
    )
  return (
    <div
      className="app-shell"
      dir={language === "ar" ? "rtl" : "ltr"}
      lang={language}
      ref={root}
    >
      <Sidebar
        active={page}
        setActive={(nextPage) => {
          setPage(nextPage)
          setFocusFacility(null)
          setFocusTask(null)
        }}
      />
      <main>
        <Header
          page={page}
          language={language}
          setLanguage={setLanguage}
          navigate={setPage}
          context={context}
          openFacility={(facilityId) => {
            setFocusFacility(facilityId)
            setPage("Excellence Center")
          }}
          openTask={(taskId) => {
            setFocusTask(taskId)
            setPage("Tasks")
          }}
          logout={() => {
            setAuthenticated(false)
            setPage("Excellence Center")
            setFocusFacility(null)
            setFocusTask(null)
          }}
        />
        {content}
      </main>
    </div>
  )
}
