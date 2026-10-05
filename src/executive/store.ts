import { useSyncExternalStore } from "react"

// Shared demo data source. Duty Manager and Executive read the same facility IDs.
export type FacilityType = "Shower" | "Toilet" | "Bin" | "Basin" | "Leak point"
export type Occupancy = "Vacant" | "Occupied" | "Unknown"
export type FacilityStatus = "Ready" | "Service Required" | "Cleaning" | "Out of Service"
export type DeviceStatus = "Online" | "Delayed" | "Offline"
export type TaskStatus = "New" | "Accepted" | "In Progress" | "Blocked" | "Completed" | "Canceled"
export type SlaStatus = "Within Target" | "Approaching" | "Breached"
export type Layer = "Service status" | "Occupancy" | "Bin fill" | "Consumables" | "Device connectivity"

export type Task = {
  id: string
  status: TaskStatus
  assignee?: string
  createdAt: number
  responseTarget: number
  completionTarget: number
  rework?: boolean
}
export type Facility = {
  id: string
  type: FacilityType
  zone: string
  level: "L01" | "L02" | "Rooftop"
  x: number
  y: number
  occupancy: Occupancy
  status: FacilityStatus
  device: DeviceStatus
  binFill?: number
  usage?: number
  task?: Task
}
export type Notice = { id: string; title: string; detail: string; group: "Alerts" | "Follow-ups" | "Exports"; unread: boolean; at: number; critical?: boolean; facility?: string }
export type Issue = { id: string; title: string; category: string; facility: string; zone: string; severity: "High" | "Medium" | "Low"; owner: string; status: string; task?: string; openedAt: number; impact: string; history: string[] }
export type Activity = { at: number; facility: string; event: string }

export type State = {
  now: number
  speed: 1 | 5 | 10
  scenario: number
  step: number
  facilities: Facility[]
  notices: Notice[]
  toast?: { title: string; facility?: string }
  changed: string[]
  annotations: boolean
  online: boolean
  queued: number
  qualityFails: number
  rework: number
  history: string[]
  issues: Issue[]
  activity: Activity[]
}

const start = new Date("2026-10-04T10:00:00+03:00").getTime()
const min = 60_000

const baseFacilities = (): Facility[] => [
  { id: "SH-01", type: "Shower", zone: "Showers", level: "L01", x: 18, y: 28, occupancy: "Vacant", status: "Ready", device: "Online" },
  { id: "SH-02", type: "Shower", zone: "Showers", level: "L01", x: 28, y: 28, occupancy: "Occupied", status: "Ready", device: "Online" },
  { id: "SH-03", type: "Shower", zone: "Showers", level: "L01", x: 38, y: 28, occupancy: "Vacant", status: "Out of Service", device: "Online" },
  { id: "SH-04", type: "Shower", zone: "Showers", level: "L01", x: 48, y: 28, occupancy: "Occupied", status: "Ready", device: "Online" },
  { id: "TC-01", type: "Toilet", zone: "Changing Rooms", level: "L01", x: 18, y: 66, occupancy: "Vacant", status: "Ready", device: "Online", usage: 31 },
  { id: "TC-02", type: "Toilet", zone: "Changing Rooms", level: "L01", x: 30, y: 66, occupancy: "Vacant", status: "Ready", device: "Online", usage: 44 },
  { id: "TC-03", type: "Toilet", zone: "Changing Rooms", level: "L01", x: 42, y: 66, occupancy: "Occupied", status: "Ready", device: "Online", usage: 18 },
  { id: "WB-01", type: "Bin", zone: "Changing Rooms", level: "L01", x: 64, y: 66, occupancy: "Unknown", status: "Ready", device: "Online", binFill: 42 },
  { id: "WB-02", type: "Bin", zone: "Lounge", level: "L01", x: 80, y: 46, occupancy: "Unknown", status: "Ready", device: "Online", binFill: 61 },
  { id: "SH-05", type: "Shower", zone: "Showers", level: "L01", x: 18, y: 42, occupancy: "Vacant", status: "Ready", device: "Online" },
  { id: "SH-06", type: "Shower", zone: "Showers", level: "L01", x: 28, y: 42, occupancy: "Vacant", status: "Ready", device: "Online" },
  { id: "LK-06", type: "Leak point", zone: "Showers", level: "L01", x: 38, y: 42, occupancy: "Unknown", status: "Ready", device: "Online" },
  { id: "TC-05", type: "Toilet", zone: "Changing Rooms", level: "L01", x: 54, y: 66, occupancy: "Vacant", status: "Service Required", device: "Online", usage: 60, task: { id: "T-1039", status: "Accepted", assignee: "Yousef Mansour", createdAt: start - 6 * min, responseTarget: 5, completionTarget: 20 } },
  { id: "BS-01", type: "Basin", zone: "Changing Rooms", level: "L01", x: 64, y: 28, occupancy: "Vacant", status: "Ready", device: "Online" },
  { id: "BS-02", type: "Basin", zone: "Changing Rooms", level: "L01", x: 74, y: 28, occupancy: "Vacant", status: "Ready", device: "Online" },
  { id: "SH-11", type: "Shower", zone: "Pool", level: "L02", x: 30, y: 40, occupancy: "Vacant", status: "Ready", device: "Online" },
  { id: "TC-11", type: "Toilet", zone: "Functional Training", level: "L02", x: 60, y: 50, occupancy: "Vacant", status: "Ready", device: "Online", usage: 12 },
  { id: "WB-07", type: "Bin", zone: "Functional Training", level: "L02", x: 70, y: 56, occupancy: "Unknown", status: "Service Required", device: "Online", binFill: 92, task: { id: "T-1031", status: "Accepted", assignee: "Omar", createdAt: start - 20.6 * min, responseTarget: 5, completionTarget: 20 } },
  { id: "WB-11", type: "Bin", zone: "Personal Training", level: "L02", x: 70, y: 30, occupancy: "Unknown", status: "Ready", device: "Online", binFill: 22 },
  { id: "WB-21", type: "Bin", zone: "Lounge", level: "Rooftop", x: 50, y: 50, occupancy: "Unknown", status: "Ready", device: "Online", binFill: 15 },
]

const initial = (): State => ({
  now: start,
  speed: 1,
  scenario: 0,
  step: 0,
  facilities: baseFacilities(),
  notices: [
    { id: "n0", title: "Weekly report ready", detail: "Executive summary · 27 Sep – 3 Oct", group: "Exports", unread: false, at: start - 90 * min },
    { id: "n1", title: "Follow-up acknowledged", detail: "Ahmed Hassan · Lounge bin cadence", group: "Follow-ups", unread: true, at: start - 30 * min },
  ],
  changed: [],
  annotations: false,
  online: true,
  queued: 0,
  qualityFails: 2,
  rework: 2,
  history: [],
  issues: [
    { id: "ISS-311", title: "Leakage near SH-06", category: "Leakage", facility: "SH-06", zone: "Showers", severity: "High", owner: "Khalid Al-Mutairi", status: "Inspection assigned", task: "T-1045", openedAt: start - 48000, impact: "SH-06 at risk", history: ["09:59 Leak sensor LK-06 alert", "10:00 Issue created by Khalid Al-Mutairi", "10:00 Inspection assigned"] },
    { id: "ISS-309", title: "Missing supplies in Lounge", category: "Missing supplies", facility: "BS-02", zone: "Lounge", severity: "Medium", owner: "Sara Al-Dosari", status: "In progress", openedAt: start - 74 * min, impact: "None", history: ["08:46 Reported by Sara Al-Dosari", "08:52 Restock in progress"] },
    { id: "ISS-305", title: "Damaged fitting SH-03", category: "Damaged fitting", facility: "SH-03", zone: "Showers", severity: "Medium", owner: "Maintenance", status: "Awaiting part", task: "T-1028", openedAt: start - 190 * min, impact: "Out of service", history: ["06:50 Fitting damage reported", "07:05 Facility closed by Duty Manager", "07:30 Part ordered"] },
  ],
  activity: [
    { at: start - 2 * min, facility: "TC-05", event: "Task accepted by Yousef Mansour" },
    { at: start - 6 * min, facility: "WB-02", event: "Bin emptied · now 8%" },
    { at: start - 11 * min, facility: "SH-02", event: "Cleaning completed · Ready" },
  ],
})

let state = initial()
const listeners = new Set<() => void>()
const emit = () => listeners.forEach((l) => l())
const set = (patch: Partial<State>) => {
  state = { ...state, ...patch }
  emit()
}
export const useStore = () =>
  useSyncExternalStore(
    (l) => (listeners.add(l), () => listeners.delete(l)),
    () => state,
  )

// Demo clock. Accelerated time multiplies elapsed seconds.
setInterval(() => set({ now: state.now + 1000 * state.speed }), 1000)

// ---------- Business rules (12.4) ----------
export type Display = FacilityStatus | "Status unknown"
export const displayStatus = (f: Facility): Display =>
  f.device === "Offline" || (f.device === "Delayed" && f.status === "Ready") ? "Status unknown" : f.status
export const isReady = (f: Facility) => f.device === "Online" && f.status === "Ready"
export const readiness = (fs: Facility[]) => Math.round((fs.filter(isReady).length / fs.length) * 1000) / 10

export const responseSla = (t: Task, now: number) => t.createdAt + t.responseTarget * min - now
export const completionSla = (t: Task, now: number) => t.createdAt + t.completionTarget * min - now
export const slaStatus = (t: Task, now: number): SlaStatus => {
  const left = t.status === "New" ? responseSla(t, now) : completionSla(t, now)
  const total = (t.status === "New" ? t.responseTarget : t.completionTarget) * min
  return left < 0 ? "Breached" : left < total * 0.35 ? "Approaching" : "Within Target"
}
export const fmtClock = (ms: number) => {
  const s = Math.floor(Math.abs(ms) / 1000)
  return `${String(Math.floor(s / 60)).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`
}

export const keyRisks = (s: State) =>
  s.facilities
    .filter((f) => !isReady(f))
    .map((f) => {
      const sla = f.task ? slaStatus(f.task, s.now) : undefined
      const rank = f.device === "Offline" ? 2 : sla === "Breached" ? 3 : sla === "Approaching" ? 2.5 : 1
      return { f, sla, rank }
    })
    .sort((a, b) => b.rank - a.rank)
    .slice(0, 3)

// ---------- Mutations ----------
const patchFacility = (id: string, p: Partial<Facility>) =>
  state.facilities.map((f) => (f.id === id ? { ...f, ...p } : f))
const notify = (title: string, detail: string, group: Notice["group"] = "Alerts", critical = /breach|offline|leak|fail|out of service/i.test(title)) => [
  { id: `n${Date.now()}${Math.random()}`, title, detail, group, unread: true, at: state.now, critical, facility: title.match(/[A-Z]{2}-\d{2}/)?.[0] },
  ...state.notices,
]
const taskFor = (id: string, rework = false): Task => {
  const existing = state.facilities.find((f) => f.id === id)?.task
  // No duplicate open task for the same facility and need.
  if (existing && existing.status !== "Completed" && existing.status !== "Canceled") return existing
  return { id: `T-${1040 + Math.floor(Math.random() * 60)}`, status: "New", createdAt: state.now, responseTarget: 5, completionTarget: 20, rework }
}
const upd = (id: string, fn: (f: Facility) => Partial<Facility>) =>
  state.facilities.map((f) => (f.id === id ? { ...f, ...fn(f) } : f))

type Step = { label: string; changed: string[]; run: () => Partial<State> }
export const scenarios: { name: string; facility: string; steps: Step[] }[] = [
  {
    name: "Shower cleaning",
    facility: "SH-04",
    steps: [
      { label: "Member leaves · vacant", changed: ["node"], run: () => ({ facilities: patchFacility("SH-04", { occupancy: "Vacant" }) }) },
      {
        label: "Service required",
        changed: ["readiness", "node", "risks", "notifications"],
        run: () => ({
          facilities: patchFacility("SH-04", { status: "Service Required", task: taskFor("SH-04") }),
          notices: notify("Service required · SH-04", "Shower · Showers · L01"),
          toast: { title: "Service required", facility: "SH-04" },
        }),
      },
      { label: "Task accepted", changed: ["risks"], run: () => ({ facilities: upd("SH-04", (f) => ({ task: { ...f.task!, status: "Accepted", assignee: "Noura Al-Salem" } })) }) },
      { label: "Cleaning started", changed: ["node"], run: () => ({ facilities: upd("SH-04", (f) => ({ status: "Cleaning", task: { ...f.task!, status: "In Progress" } })) }) },
      { label: "Checklist done", changed: ["node"], run: () => ({}) },
      {
        label: "Ready",
        changed: ["readiness", "node", "risks", "highlights"],
        run: () => ({ facilities: upd("SH-04", (f) => ({ status: "Ready", task: { ...f.task!, status: "Completed" } })), history: [`SH-04 cleaned by Noura Al-Salem`, ...state.history] }),
      },
    ],
  },
  {
    name: "Toilet threshold",
    facility: "TC-02",
    steps: [
      { label: "Usage reaches threshold", changed: ["node", "risks", "readiness"], run: () => ({ facilities: patchFacility("TC-02", { usage: 60, status: "Service Required", task: taskFor("TC-02") }), notices: notify("Usage threshold · TC-02", "60 of 60 visits") }) },
      { label: "Task completed", changed: ["node", "risks", "readiness"], run: () => ({ facilities: upd("TC-02", (f) => ({ status: "Ready", task: { ...f.task!, status: "Completed", assignee: "Yousef Mansour" } })) }) },
      { label: "Counter resets", changed: ["node"], run: () => ({ facilities: patchFacility("TC-02", { usage: 0 }) }) },
    ],
  },
  {
    name: "Bin emptying",
    facility: "WB-02",
    steps: [
      { label: "Fill passes threshold", changed: ["node", "risks", "readiness"], run: () => ({ facilities: patchFacility("WB-02", { binFill: 88, status: "Service Required", task: taskFor("WB-02") }), notices: notify("Bin fill 88% · WB-02", "Lounge · L01") }) },
      { label: "Bin emptied", changed: ["node", "readiness", "risks"], run: () => ({ facilities: upd("WB-02", (f) => ({ status: "Ready", binFill: 4, task: { ...f.task!, status: "Completed", assignee: "Faisal Al-Qahtani" } })) }) },
      { label: "New reading", changed: ["node"], run: () => ({ facilities: patchFacility("WB-02", { binFill: 6 }) }) },
    ],
  },
  {
    name: "SLA escalation",
    facility: "BS-01",
    steps: [
      { label: "Task created, not accepted", changed: ["node", "risks", "readiness"], run: () => ({ facilities: patchFacility("BS-01", { status: "Service Required", task: taskFor("BS-01") }) }) },
      { label: "SLA warning", changed: ["risks", "notifications"], run: () => ({ facilities: upd("BS-01", (f) => ({ task: { ...f.task!, createdAt: state.now - 3.6 * min } })), notices: notify("SLA approaching · BS-01", "Response due soon"), toast: { title: "SLA approaching", facility: "BS-01" } }) },
      { label: "SLA breach", changed: ["risks", "notifications", "performance"], run: () => ({ facilities: upd("BS-01", (f) => ({ task: { ...f.task!, createdAt: state.now - 8.2 * min } })), notices: notify("SLA breached · BS-01", "Response target 5 min"), toast: { title: "SLA breached", facility: "BS-01" } }) },
      { label: "Supervisor notified", changed: ["notifications"], run: () => ({ notices: notify("Supervisor notified · BS-01", "Khalid Al-Mutairi") }) },
      { label: "Reassigned", changed: ["risks"], run: () => ({ facilities: upd("BS-01", (f) => ({ task: { ...f.task!, status: "Accepted", assignee: "Faisal Al-Qahtani" } })) }) },
    ],
  },
  {
    name: "Device offline",
    facility: "SH-02",
    steps: [
      { label: "Stops reporting · stale", changed: ["node", "banner"], run: () => ({ facilities: patchFacility("SH-02", { device: "Delayed" }) }) },
      { label: "Offline", changed: ["node", "readiness", "risks", "banner"], run: () => ({ facilities: patchFacility("SH-02", { device: "Offline", occupancy: "Unknown" }), notices: notify("Device offline · SH-02", "No signal for 5 min") }) },
      { label: "Recovers", changed: ["node", "readiness", "risks", "banner"], run: () => ({ facilities: patchFacility("SH-02", { device: "Online", occupancy: "Vacant" }), notices: notify("Device restored · SH-02", "Signal back") }) },
    ],
  },
  {
    name: "Quality rework",
    facility: "SH-01",
    steps: [
      { label: "Inspection fails", changed: ["quality", "node", "readiness"], run: () => ({ qualityFails: state.qualityFails + 1, rework: state.rework + 1, facilities: patchFacility("SH-01", { status: "Service Required", task: taskFor("SH-01", true) }), notices: notify("Inspection failed · SH-01", "Rework linked to INSP-214") }) },
      { label: "Corrective work done", changed: ["quality", "node", "readiness"], run: () => ({ rework: state.rework - 1, facilities: upd("SH-01", (f) => ({ status: "Ready", task: { ...f.task!, status: "Completed", assignee: "Noura Al-Salem" } })), history: ["SH-01 original task kept in history", ...state.history] }) },
    ],
  },
]

scenarios.push({
  name: "Leak alert",
  facility: "LK-06",
  steps: [
    { label: "Urgent leak alert", changed: ["node", "risks", "notifications"], run: () => ({ facilities: patchFacility("LK-06", { status: "Service Required" }), notices: notify("Leak alert · LK-06", "Near SH-06 · Showers"), toast: { title: "Leak alert", facility: "LK-06" } }) },
    { label: "Inspect task assigned", changed: ["risks"], run: () => ({ issues: state.issues.map((i) => (i.id === "ISS-311" ? { ...i, status: "Inspecting · Faisal Al-Qahtani", history: [...i.history, "Inspect task accepted by Faisal Al-Qahtani"] } : i)) }) },
    { label: "Issue created", changed: ["risks"], run: () => ({ issues: [{ id: "ISS-312", title: "Leak at LK-06", category: "Leakage", facility: "LK-06", zone: "Showers", severity: "High", owner: "Khalid Al-Mutairi", status: "Open", task: "T-1046", openedAt: state.now, impact: "SH-06 closed", history: ["Issue created from inspection"] }, ...state.issues] }) },
  ],
})

export const actions = {
  setScenario: (scenario: number) => set({ scenario, step: 0, changed: [] }),
  advance: () => {
    const sc = scenarios[state.scenario]
    if (state.step >= sc.steps.length) return
    const s = sc.steps[state.step]
    const patch = s.run()
    set({ ...patch, step: state.step + 1, changed: s.changed, activity: [{ at: state.now, facility: sc.facility, event: s.label }, ...state.activity].slice(0, 20) })
  },
  setSpeed: (speed: State["speed"]) => set({ speed }),
  toggleAnnotations: () => set({ annotations: !state.annotations }),
  dismissToast: () => set({ toast: undefined }),
  reset: () => {
    const { annotations, speed } = state
    state = { ...initial(), annotations, speed }
    emit()
  },
  setOnline: (online: boolean) => set({ online, queued: online ? 0 : state.queued }),
  queue: () => set({ queued: state.queued + 1 }),
  markRead: () => set({ notices: state.notices.map((n) => ({ ...n, unread: false })) }),
  addNotice: (title: string, detail: string, group: Notice["group"]) => set({ notices: notify(title, detail, group) }),
}
