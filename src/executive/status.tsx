import { createContext, useContext } from "react"
import type { Display, DeviceStatus, FacilityType, Occupancy, SlaStatus, TaskStatus } from "./store"
import { fmtClock } from "./store"

export const T = createContext<(s: string) => string>((s) => s)
export const useT = () => useContext(T)

// Facility codes stay LTR inside Arabic text.
export const Code = ({ children }: { children: string }) => (
  <bdi dir="ltr" className="ex-code">
    {children}
  </bdi>
)

const typeGlyph: Record<FacilityType, string> = {
  Shower: "M8 4v3M5 7h6M6 10v1M8 10v2M10 10v1",
  Toilet: "M5 3h6v5H5zM4 8h8l-1 4H5z",
  Bin: "M4 5h8M6 5V3h4v2M5 5l1 8h4l1-8",
  Basin: "M3 7h10a5 5 0 0 1-10 0M8 3v4",
  "Leak point": "M8 2c2 3 4 5 4 7.5a4 4 0 0 1-8 0C4 7 6 5 8 2z",
}
export const TypeIcon = ({ type, size = 14 }: { type: FacilityType; size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" aria-hidden="true">
    <path d={typeGlyph[type]} />
  </svg>
)

const tone = (s: string) =>
  s === "Ready" || s === "Online" || s === "Completed" || s === "Within Target" || s === "Vacant"
    ? "ok"
    : s === "Cleaning" || s === "In Progress" || s === "Accepted"
      ? "work"
      : s === "Breached" || s === "Out of Service" || s === "Offline" || s === "Blocked"
        ? "bad"
        : s === "Status unknown" || s === "Unknown" || s === "Canceled"
          ? "none"
          : "warn"

/** Occupancy: dot + label */
export function OccupancyDot({ value }: { value: Occupancy }) {
  const t = useT()
  return (
    <span className={`ex-occ ${value.toLowerCase()}`}>
      <i aria-hidden="true" />
      {t(value)}
    </span>
  )
}

/** Facility status: rounded-square chip + facility icon */
export function FacilityChip({ value, type }: { value: Display; type: FacilityType }) {
  const t = useT()
  return (
    <span className={`ex-chip ${tone(value)}`}>
      <TypeIcon type={type} size={12} />
      {t(value)}
    </span>
  )
}

const processGlyph: Record<TaskStatus, string> = {
  New: "M8 3v10M3 8h10",
  Accepted: "M3 8l3 3 7-7",
  "In Progress": "M8 2a6 6 0 1 1-6 6",
  Blocked: "M4 4l8 8M12 4l-8 8",
  Completed: "M3 8l3 3 7-7",
  Canceled: "M3 8h10",
}
/** Task status: pill + process icon (pills are only for task status) */
export function TaskPill({ value }: { value: TaskStatus }) {
  const t = useT()
  return (
    <span className={`ex-pill ${tone(value)}`}>
      <svg width="10" height="10" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
        <path d={processGlyph[value]} />
      </svg>
      {t(value)}
    </span>
  )
}

/** Device status: signal bars */
export function SignalBars({ value }: { value: DeviceStatus }) {
  const t = useT()
  const lit = value === "Online" ? 3 : value === "Delayed" ? 2 : 0
  return (
    <span className={`ex-signal ${tone(value)}`}>
      <span className="bars" aria-hidden="true">
        {[1, 2, 3].map((b) => (
          <i key={b} className={b <= lit ? "on" : ""} style={{ height: 3 + b * 3 }} />
        ))}
        {value === "Offline" && <b>×</b>}
      </span>
      {t(value)}
    </span>
  )
}

/** SLA status: progress ring + countdown */
export function SlaRing({ status, left, total, label }: { status: SlaStatus; left: number; total: number; label: string }) {
  const t = useT()
  const p = Math.max(0, Math.min(1, left / total))
  const c = 2 * Math.PI * 7
  const mins = Math.floor(Math.abs(left) / 60000)
  const secs = Math.floor((Math.abs(left) % 60000) / 1000)
  return (
    <span className={`ex-sla ${tone(status)}`} aria-label={`${label} ${left < 0 ? "breached" : "remaining"} ${mins} minutes ${secs} seconds`}>
      <svg width="18" height="18" viewBox="0 0 18 18" aria-hidden="true">
        <circle cx="9" cy="9" r="7" fill="none" stroke="var(--line)" strokeWidth="2" />
        <circle cx="9" cy="9" r="7" fill="none" stroke="currentColor" strokeWidth="2" strokeDasharray={c} strokeDashoffset={c * (1 - p)} transform="rotate(-90 9 9)" strokeLinecap="round" />
      </svg>
      <span>
        <small>{t(status)}</small>
        <b className="tnum">{left < 0 ? `${t("Breached")} ${fmtClock(left)} ${t("ago")}` : `${t("Breach in")} ${fmtClock(left)}`}</b>
      </span>
    </span>
  )
}

export function Mark({ n, show }: { n: number; show: boolean }) {
  return show ? (
    <span className="ex-mark" aria-label={`Annotation ${n}`}>
      {n}
    </span>
  ) : null
}
