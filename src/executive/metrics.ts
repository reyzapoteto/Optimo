import { isReady, responseSla, slaStatus, type State } from "./store"

/* ---------- derived executive metrics (one source for every widget) ---------- */
// The store models a subset of the 42 monitored facilities; the remaining ones are Ready and online.
export const CLUB = { total: 42, showers: 16, background: 6 }
export function metrics(s: State) {
  const open = s.facilities.filter((f) => f.task && f.task.status !== "Completed" && f.task.status !== "Canceled")
  const notReady = s.facilities.filter((f) => !isReady(f))
  const showersDown = s.facilities.filter((f) => f.type === "Shower" && !isReady(f)).length
  const awaiting = s.facilities.filter((f) => f.status === "Service Required" || f.status === "Cleaning")
  const overdue = open.filter((f) => slaStatus(f.task!, s.now) === "Breached")
  const respBreach = open.filter((f) => f.task!.status === "New" && responseSla(f.task!, s.now) < 0).length
  const response = 96 - respBreach * 3
  const completion = 92 - Math.max(0, overdue.length - 1) * 2
  const offline = s.facilities.filter((f) => f.device === "Offline").length
  return {
    ready: CLUB.total - notReady.length,
    readyShowers: CLUB.showers - showersDown,
    awaiting: awaiting.length,
    cleaning: awaiting.filter((f) => f.status === "Cleaning").length,
    active: open.length + CLUB.background,
    blocked: open.filter((f) => f.task!.status === "Blocked").length,
    overdue,
    response,
    completion,
    sla: Math.round((response + completion) / 2),
    issues: s.issues.length,
    high: s.issues.filter((i) => i.severity === "High").length,
    online: CLUB.total - offline,
    offline,
  }
}
export type M = ReturnType<typeof metrics>
