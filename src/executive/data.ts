import { slaStatus, type FacilityType, type Issue, type State } from "./store"

/* Illustrative demo ledgers for the read-only Executive pages. Live values come from the shared store. */
export type Range = "Today" | "7 days" | "30 days"
export const RANGES: Range[] = ["Today", "7 days", "30 days"]
export const PASS_TARGET = 95
const min = 60_000
const mult = { Today: 1, "7 days": 7, "30 days": 30 } as const

export const ageText = (ms: number) => {
  const m = Math.max(0, Math.round(ms / min))
  return m < 60 ? `${m}m` : m < 1440 ? `${Math.floor(m / 60)}h ${String(m % 60).padStart(2, "0")}m` : `${Math.floor(m / 1440)}d ${Math.floor((m % 1440) / 60)}h`
}

/* ---------- Inspections ---------- */
export type Inspection = { id: string; facility: string; type: FacilityType; zone: string; at: number; reason: string; inspector: string; task: string; rework: "Rework open" | "Rework done"; daysAgo: number }
const START = new Date("2026-10-04T10:00:00+03:00").getTime()
const base = (_s: State) => START - 110 * min
const earlier: Omit<Inspection, "at">[] = [
  { id: "INSP-204", facility: "SH-02", type: "Shower", zone: "Showers", reason: "Grout not clean", inspector: "Khalid Al-Mutairi", task: "T-0981", rework: "Rework done", daysAgo: 1 },
  { id: "INSP-203", facility: "TC-03", type: "Toilet", zone: "Changing Rooms", reason: "Missing supplies", inspector: "Sara Al-Dosari", task: "T-0974", rework: "Rework done", daysAgo: 1 },
  { id: "INSP-199", facility: "BS-02", type: "Basin", zone: "Lounge", reason: "Mirror streaks", inspector: "Khalid Al-Mutairi", task: "T-0958", rework: "Rework done", daysAgo: 2 },
  { id: "INSP-196", facility: "SH-04", type: "Shower", zone: "Showers", reason: "Drain residue", inspector: "Sara Al-Dosari", task: "T-0944", rework: "Rework done", daysAgo: 3 },
  { id: "INSP-191", facility: "TC-11", type: "Toilet", zone: "Functional Training", reason: "Floor not dry", inspector: "Khalid Al-Mutairi", task: "T-0931", rework: "Rework done", daysAgo: 4 },
  { id: "INSP-187", facility: "WB-11", type: "Bin", zone: "Personal Training", reason: "Odour", inspector: "Sara Al-Dosari", task: "T-0920", rework: "Rework done", daysAgo: 5 },
  { id: "INSP-181", facility: "SH-06", type: "Shower", zone: "Showers", reason: "Floor not dry", inspector: "Khalid Al-Mutairi", task: "T-0902", rework: "Rework done", daysAgo: 6 },
  { id: "INSP-172", facility: "TC-02", type: "Toilet", zone: "Changing Rooms", reason: "Drain residue", inspector: "Sara Al-Dosari", task: "T-0877", rework: "Rework done", daysAgo: 9 },
  { id: "INSP-160", facility: "BS-01", type: "Basin", zone: "Changing Rooms", reason: "Mirror streaks", inspector: "Khalid Al-Mutairi", task: "T-0842", rework: "Rework done", daysAgo: 16 },
  { id: "INSP-151", facility: "SH-03", type: "Shower", zone: "Showers", reason: "Grout not clean", inspector: "Sara Al-Dosari", task: "T-0810", rework: "Rework done", daysAgo: 24 },
]
/** Failed inspections, newest first. Today's rows follow the live store counters. */
export function failedInspections(s: State, range: Range): Inspection[] {
  const b = base(s)
  const today: Inspection[] = [
    ...(s.qualityFails > 2 ? [{ id: "INSP-214", facility: "SH-01", type: "Shower" as const, zone: "Showers", at: s.now - 2 * min, reason: "Streaks on glass", inspector: "Khalid Al-Mutairi", task: "T-1047", rework: "Rework open" as const, daysAgo: 0 }] : []),
    { id: "INSP-213", facility: "SH-05", type: "Shower", zone: "Showers", at: b + 25 * min, reason: "Drain residue", inspector: "Khalid Al-Mutairi", task: "T-1029", rework: "Rework open", daysAgo: 0 },
    { id: "INSP-212", facility: "TC-01", type: "Toilet", zone: "Changing Rooms", at: b + 0 * min + 20 * min, reason: "Floor not dry", inspector: "Sara Al-Dosari", task: "T-1024", rework: "Rework open", daysAgo: 0 },
  ]
  const done = Math.max(0, s.qualityFails - s.rework)
  const rows = today.map((r, i) => (i < done ? { ...r, rework: "Rework done" as const } : r))
  const prior = earlier.map((r) => ({ ...r, at: b + 25 * min - r.daysAgo * 1440 * min }))
  const all = [...rows, ...prior]
  return all.filter((r) => (range === "Today" ? r.daysAgo === 0 : range === "7 days" ? r.daysAgo < 7 : r.daysAgo < 30))
}
const extra = (s: State) => s.qualityFails - 2
/** Total failed inspections in the period (the ledger shows the most recent rows). */
export const failTotal = (s: State, r: Range) => (r === "Today" ? s.qualityFails : r === "7 days" ? 14 + extra(s) : 64 + extra(s))
export const inspTotal = (s: State, r: Range) => (r === "Today" ? 34 + extra(s) : r === "7 days" ? 238 + extra(s) : 1020 + extra(s))
export const passRate = (s: State, r: Range) => Math.round(((inspTotal(s, r) - failTotal(s, r)) / inspTotal(s, r)) * 1000) / 10
export const reworkOpen = (s: State) => s.rework

const ZONES: [string, number, number][] = [
  // zone, inspections today, share of failures
  ["Showers", 10, 0.3], ["Changing Rooms", 8, 0.26], ["Lounge", 5, 0.14], ["Pool", 4, 0.1], ["Functional Training", 3, 0.08], ["Personal Training", 2, 0.07], ["Rooftop", 2, 0.05],
]
export function zoneQuality(s: State, r: Range) {
  const tot = failTotal(s, r)
  const rows = failedInspections(s, "Today")
  const fails = ZONES.map(([z, , share]) => (r === "Today" ? rows.filter((x) => x.zone === z).length : Math.round(tot * share)))
  const diff = tot - fails.reduce((a, b) => a + b, 0)
  fails[0] += diff
  const insp = inspTotal(s, r)
  return ZONES.map(([zone, n], i) => {
    const total = Math.round((n / 34) * insp)
    return { zone, insp: total, fails: fails[i], pass: Math.round(((total - fails[i]) / total) * 1000) / 10 }
  }).sort((a, b) => a.pass - b.pass)
}
export function reasons(s: State, r: Range) {
  const tot = failTotal(s, r)
  const shares: [string, number][] = [["Floor not dry", 0.26], ["Drain residue", 0.22], ["Missing supplies", 0.18], ["Mirror streaks", 0.14], ["Grout not clean", 0.12], ["Odour", 0.08]]
  const rows = shares.map(([k, p]) => [k, Math.round(tot * p)] as [string, number])
  rows[0][1] += tot - rows.reduce((a, [, n]) => a + n, 0)
  return rows.sort((a, b) => b[1] - a[1])
}
export const PASS_SERIES: Record<Range, { x: string[]; v: number[]; prev: number[] }> = {
  Today: { x: ["06:00", "07:00", "08:00", "09:00", "10:00", "11:00", "12:00", "13:00"], v: [95, 94, 93, 92, 94, 95, 94, 94], prev: [93, 92, 91, 92, 92, 93, 92, 92] },
  "7 days": { x: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], v: [92, 93, 95, 94, 93, 95, 94], prev: [91, 92, 92, 93, 91, 93, 92] },
  "30 days": { x: ["W1", "W2", "W3", "W4", "W5"], v: [90, 92, 93, 93, 94], prev: [89, 90, 90, 91, 92] },
}

/* ---------- Issues register ---------- */
export type RegisterRow = Issue & { resolved?: string; closed: boolean }
const resolvedIssues: RegisterRow[] = [
  { id: "ISS-304", title: "Low battery on bin sensor WB-01", category: "Device", facility: "WB-01", zone: "Changing Rooms", severity: "Low", owner: "Maintenance", status: "Resolved", openedAt: 0, impact: "None", history: ["Sensor battery below 10%", "Battery replaced"], resolved: "3h 10m", closed: true },
  { id: "ISS-302", title: "Slippery floor outside showers", category: "Safety", facility: "SH-02", zone: "Showers", severity: "Medium", owner: "Khalid Al-Mutairi", status: "Resolved", openedAt: 0, impact: "None", history: ["Reported by member", "Anti-slip mats placed", "Floor dried and reopened"], resolved: "1h 25m", closed: true },
  { id: "ISS-298", title: "Dripping basin tap BS-01", category: "Damaged fitting", facility: "BS-01", zone: "Changing Rooms", severity: "Low", owner: "Maintenance", status: "Resolved", openedAt: 0, impact: "None", history: ["Drip reported", "Washer replaced"], resolved: "5h 40m", closed: true },
  { id: "ISS-295", title: "Odour near TC-02", category: "Cleanliness", facility: "TC-02", zone: "Changing Rooms", severity: "Medium", owner: "Sara Al-Dosari", status: "Resolved", openedAt: 0, impact: "None", history: ["Odour reported", "Deep clean completed"], resolved: "2h 05m", closed: true },
  { id: "ISS-291", title: "Leak at Pool shower SH-11", category: "Leakage", facility: "SH-11", zone: "Pool", severity: "High", owner: "Khalid Al-Mutairi", status: "Resolved", openedAt: 0, impact: "Closed 40 min", history: ["Leak sensor alert", "Facility closed", "Seal replaced", "Reopened"], resolved: "4h 20m", closed: true },
]
export const registerRows = (s: State): RegisterRow[] => [...s.issues.map((i) => ({ ...i, closed: false })), ...resolvedIssues]
export const ageBuckets = (s: State) => {
  const ages = s.issues.map((i) => s.now - i.openedAt)
  const n = (lo: number, hi: number) => ages.filter((a) => a >= lo * 60 * min && a < hi * 60 * min).length
  return [["< 1h", n(0, 60)], ["1–4h", n(60, 240)], ["4–24h", n(240, 1440)], ["> 24h", n(1440, 1e9)]] as [string, number][]
}
export const hotspots = (s: State) => {
  const m = new Map<string, number>()
  registerRows(s).forEach((r) => m.set(r.zone, (m.get(r.zone) ?? 0) + 1))
  return [...m.entries()].sort((a, b) => b[1] - a[1])
}

/* ---------- Reports ---------- */
export type DayRow = { day: string; sla: number; response: number; completion: number; pass: number; tasks: number }
export const DAILY: DayRow[] = [
  { day: "Sun 27 Sep", sla: 93, response: 95, completion: 91, pass: 92, tasks: 118 },
  { day: "Mon 28 Sep", sla: 94, response: 96, completion: 92, pass: 93, tasks: 131 },
  { day: "Tue 29 Sep", sla: 92, response: 94, completion: 90, pass: 95, tasks: 124 },
  { day: "Wed 30 Sep", sla: 95, response: 97, completion: 93, pass: 94, tasks: 127 },
  { day: "Thu 1 Oct", sla: 94, response: 96, completion: 92, pass: 93, tasks: 139 },
  { day: "Fri 2 Oct", sla: 96, response: 97, completion: 95, pass: 95, tasks: 146 },
  { day: "Sat 3 Oct", sla: 94, response: 96, completion: 92, pass: 94, tasks: 122 },
]
export type TaskRow = { id: string; facility: string; zone: string; type: string; owner: string; response: string; completion: string; sla: "Within Target" | "Approaching" | "Breached"; status: string }
const pastTasks: TaskRow[] = [
  { id: "T-1033", facility: "SH-04", zone: "Showers", type: "Clean shower", owner: "Noura Al-Salem", response: "1m 50s", completion: "12m", sla: "Within Target", status: "Completed" },
  { id: "T-1030", facility: "WB-02", zone: "Lounge", type: "Empty bin", owner: "Faisal Al-Qahtani", response: "2m 10s", completion: "6m", sla: "Within Target", status: "Completed" },
  { id: "T-1027", facility: "TC-02", zone: "Changing Rooms", type: "Clean toilet", owner: "Yousef Mansour", response: "3m 05s", completion: "17m", sla: "Within Target", status: "Completed" },
  { id: "T-1022", facility: "BS-01", zone: "Changing Rooms", type: "Restock basin", owner: "Omar", response: "6m 40s", completion: "24m", sla: "Breached", status: "Completed" },
  { id: "T-1018", facility: "SH-05", zone: "Showers", type: "Clean shower", owner: "Noura Al-Salem", response: "1m 20s", completion: "11m", sla: "Within Target", status: "Completed" },
  { id: "T-1012", facility: "TC-03", zone: "Changing Rooms", type: "Clean toilet", owner: "Yousef Mansour", response: "2m 30s", completion: "15m", sla: "Within Target", status: "Completed" },
]
export const taskRows = (s: State): TaskRow[] => {
  const live = s.facilities.filter((f) => f.task).map((f) => {
    const t = f.task!
    const st = slaStatus(t, s.now)
    return { id: t.id, facility: f.id, zone: f.zone, type: f.type === "Bin" ? "Empty bin" : f.type === "Leak point" ? "Inspect leak" : `Clean ${f.type.toLowerCase()}`, owner: t.assignee ?? "Unassigned", response: t.status === "New" ? "Pending" : "On time", completion: t.status === "Completed" ? "Done" : "Running", sla: st, status: t.status }
  })
  return [...live, ...pastTasks]
}

export const seriesFor = {
  sla: [93, 94, 92, 95, 94, 96, 94],
  response: [95, 96, 94, 97, 96, 97, 96],
  pass: [92, 93, 95, 94, 93, 95, 94],
  ready: [40, 41, 41, 42, 41, 42, 41],
}
