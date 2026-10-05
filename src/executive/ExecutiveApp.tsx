import { useEffect, useMemo, useRef, useState } from "react"
import type { MouseEvent as RMouseEvent } from "react"
import digitalTwin from "../assets/optimo-digital-twin-isolated.png"
import "./executive.css"
import { translate, type Lang } from "./i18n"
import {
  actions, completionSla, displayStatus, fmtClock, isReady, responseSla, scenarios, slaStatus, useStore,
  type Facility, type Layer, type Notice, type State,
} from "./store"
import { Code, FacilityChip, Mark, OccupancyDot, SignalBars, SlaRing, T, TaskPill, TypeIcon, useT } from "./status"
import { CLUB, metrics, type M } from "./metrics"
import QualityPage, { type Intent } from "./quality"
import IssuesPage from "./issues"
import ReportsPage from "./reports"
import { PageSkeleton, StateCard } from "./states"
import { Delta, Dialog, Drawer, IconBtn, Select, Svg, Tertiary, clock, ic, reduced, useCount } from "./ui"

/* Manager / Executive — read-only briefing. Controls that create, edit, assign,
   close or configure are ABSENT (never disabled) in this workspace. */

type ExPage = "Excellence Center" | "Quality" | "Issues" | "Reports"
type Period = "Today" | "7 days" | "30 days" | "Custom"
type Mode = "Live" | "Loading" | "Stale" | "Empty" | "Error"
const FORBIDDEN = ["#/tasks", "#/schedule", "#/team", "#/settings"]




/* ---------- Row 1: Executive Strip (one plane, six cells) ---------- */
function Cell({ label, value, children, accent, onClick, active }: { label: string; value: React.ReactNode; children: React.ReactNode; accent?: boolean; onClick: () => void; active?: boolean }) {
  const t = useT()
  return (
    <button className={`ex-cell ${accent ? "accent" : ""} ${active ? "active" : ""}`} onClick={onClick} aria-pressed={active}>
      <small>{t(label)}</small>
      <strong className="tnum">{value}</strong>
      <span className="ex-cell-ctx">{children}</span>
    </button>
  )
}
const N = ({ v, suffix = "" }: { v: number; suffix?: string }) => <>{Math.round(useCount(v))}{suffix}</>

function Strip({ m, filter, setFilter, go, compare }: { m: M; filter: string; setFilter: (f: string) => void; go: (p: ExPage) => void; compare: boolean }) {
  const vs = compare ? "vs previous period" : "vs yesterday"
  return (
    <section className="ex-strip" aria-label="Executive strip">
      <Cell label="Ready showers" value={<><N v={m.readyShowers} /><span className="ex-of"> / {CLUB.showers}</span></>} active={filter === "Shower"} onClick={() => setFilter(filter === "Shower" ? "All" : "Shower")}>
        <Delta dir={m.readyShowers >= 14 ? "up" : "down"}>{Math.abs(m.readyShowers - 14) || 1} {vs}</Delta>
      </Cell>
      <Cell label="Awaiting service" value={<N v={m.awaiting} />} active={filter === "Awaiting"} onClick={() => setFilter(filter === "Awaiting" ? "All" : "Awaiting")}>
        {m.cleaning} cleaning in progress
      </Cell>
      <Cell label="Active tasks" value={<N v={m.active} />} onClick={() => go("Reports")}>
        {m.blocked ? `${m.blocked} blocked` : "None blocked"}
      </Cell>
      <Cell label="Overdue tasks" value={<N v={m.overdue.length} />} onClick={() => go("Reports")}>
        <Delta dir={m.overdue.length <= 1 ? "down" : "up"}>{m.overdue.length <= 1 ? 2 : m.overdue.length - 1} {vs}</Delta>
      </Cell>
      <Cell label="SLA compliance" accent value={<N v={m.sla} suffix="%" />} onClick={() => go("Reports")}>
        Response {m.response}% · Completion {m.completion}%
      </Cell>
      <Cell label="Open issues" value={<N v={m.issues} />} onClick={() => go("Issues")}>
        {m.high} high priority
      </Cell>
    </section>
  )
}

/* ---------- Row 2A: OPTIMO Live Digital Twin (read-only) ---------- */
const SCENE_POS: Record<string, { x: number; y: number }> = {
  "SH-01": { x: 19, y: 19 }, "SH-02": { x: 28, y: 23 }, "SH-03": { x: 37, y: 20 }, "SH-04": { x: 46, y: 24 },
  "SH-05": { x: 25, y: 38 }, "SH-06": { x: 35, y: 41 }, "LK-06": { x: 53, y: 31 },
  "BS-01": { x: 62, y: 28 }, "BS-02": { x: 68, y: 37 },
  "TC-01": { x: 76, y: 31 }, "TC-02": { x: 83, y: 38 }, "TC-03": { x: 91, y: 33 }, "TC-05": { x: 84, y: 50 },
  "WB-01": { x: 13, y: 29 }, "WB-02": { x: 68, y: 50 },
  "SH-11": { x: 30, y: 24 }, "TC-11": { x: 80, y: 36 }, "WB-07": { x: 68, y: 50 }, "WB-11": { x: 13, y: 29 }, "WB-21": { x: 50, y: 42 },
}
const LAYERS: Layer[] = ["Service status", "Occupancy", "Bin fill", "Consumables", "Device connectivity"]
function nodeClass(f: Facility, layer: Layer) {
  if (f.device === "Offline") return "nosignal"
  if (layer === "Occupancy") return f.occupancy === "Occupied" ? "occ" : f.occupancy === "Vacant" ? "vac" : "unk"
  if (layer === "Device connectivity") return f.device === "Online" ? "ok" : "warn"
  if (layer === "Bin fill") return f.type !== "Bin" ? "dim" : (f.binFill ?? 0) > 80 ? "warn" : "ok"
  if (layer === "Consumables") return f.type !== "Basin" ? "dim" : f.id === "BS-02" ? "warn" : "ok"
  const d = displayStatus(f)
  if (f.type === "Leak point") return d === "Ready" ? "ok" : "bad"
  return d === "Ready" ? "ok" : d === "Cleaning" ? "work" : d === "Status unknown" ? "nosignal" : d === "Out of Service" ? "bad" : "warn"
}

function Twin({ s, selected, select, filter, setFilter, togglePresent, presenting, stale, lang }: {
  s: State; selected?: string; select: (id?: string) => void; filter: string; setFilter: (f: string) => void; togglePresent: () => void; presenting: boolean; stale: boolean; lang: Lang
}) {
  const t = useT()
  const [level, setLevel] = useState<"L01" | "L02" | "Rooftop">("L01")
  const [layer, setLayer] = useState<Layer>("Service status")
  const [zoom, setZoom] = useState(1)
  const [pan, setPan] = useState({ x: 0, y: 0 })
  const [hover, setHover] = useState<Facility>()
  const drag = useRef<{ x: number; y: number } | null>(null)
  const sel = s.facilities.find((f) => f.id === selected)
  useEffect(() => { if (sel && sel.level !== level) setLevel(sel.level) }, [selected])
  const nodes = s.facilities.filter(
    (f) => f.level === level && (filter === "All" || (filter === "Awaiting" ? f.status === "Service Required" || f.status === "Cleaning" : f.type === filter)),
  )
  const changed = new Set(s.changed.includes("node") ? [scenarios[s.scenario].facility] : [])
  const tone = (f: Facility) => {
    const c = nodeClass(f, layer)
    return c === "ok" || c === "vac" ? "ready" : c === "warn" || c === "occ" ? "attention" : c === "work" ? "cleaning" : c === "bad" || c === "nosignal" ? "critical" : c === "dim" ? "ready" : "muted"
  }
  const vp = useRef<HTMLDivElement>(null)
  useEffect(() => {
    const el = vp.current
    if (!el) return
    const wheel = (e: WheelEvent) => { e.preventDefault(); setZoom((z) => Math.min(1.8, Math.max(1, z + (e.deltaY > 0 ? -0.08 : 0.08)))) }
    el.addEventListener("wheel", wheel, { passive: false })
    return () => el.removeEventListener("wheel", wheel)
  }, [])
  const reading = (f: Facility) => f.type === "Bin" ? `${f.binFill}% full` : layer === "Occupancy" ? f.occupancy : layer === "Device connectivity" ? f.device : displayStatus(f)
  return (
    <section className={`ex-card ex-twin ${sel ? "inspecting" : ""}`} aria-label="OPTIMO Live Digital Twin">
      <div className="ex-twin-head">
        <div>
          <span className="ex-eyebrow">LIVE SPATIAL OPERATIONS</span>
          <h3>OPTIMO Live Digital Twin <span className="ex-demo-label">{t("Illustrative demo layout")}</span>{stale && <span className="ex-stale-tag"><Svg d={ic.wifiOff} size={12} />Stale</span>} <Mark n={2} show={s.annotations && s.changed.includes("node")} /></h3>
          <p>Drag to pan · Scroll to zoom · Select to inspect.</p>
        </div>
        <div className="ex-head-controls">
          <div className="ex-seg" role="radiogroup" aria-label="Floor">
            {(["L01", "L02", "Rooftop"] as const).map((l) => (
              <button key={l} role="radio" aria-checked={level === l} className={level === l ? "active" : ""} onClick={() => (setLevel(l), select())}>{t(l)}</button>
            ))}
          </div>
          {!presenting && <Select value={filter === "Awaiting" ? "Awaiting service" : filter === "All" ? "All types" : filter} options={["All types", "Awaiting service", "Shower", "Toilet", "Bin", "Basin", "Leak point"]} onChange={(v) => setFilter(v === "All types" ? "All" : v === "Awaiting service" ? "Awaiting" : v)} />}
          <IconBtn label={t(presenting ? "Exit full screen" : "Full screen")} d={presenting ? ic.exitFull : ic.full} onClick={togglePresent} />
        </div>
      </div>
      <div className="ex-modebar">
        <span>VIEW MODE</span>
        <div className="ex-modes" role="radiogroup" aria-label={t("Layers")}>
          {LAYERS.map((l) => <button key={l} role="radio" aria-checked={l === layer} className={l === layer ? "active" : ""} onClick={() => setLayer(l)}>{t(l)}</button>)}
        </div>
        <div className="ex-context">Main Club <Svg d="M6 4l4 4-4 4" size={11} /> {t(level)}</div>
      </div>
      <div className="ex-twin-body">
        <div
          ref={vp}
          className={`ex-canvas ${stale ? "stale" : ""} ${zoom > 1.14 ? "zoomed" : ""}`}
          dir="ltr"
          onPointerDown={(e) => (drag.current = { x: e.clientX - pan.x, y: e.clientY - pan.y })}
          onPointerMove={(e) => drag.current && setPan({ x: Math.max(-260, Math.min(260, e.clientX - drag.current.x)), y: Math.max(-160, Math.min(160, e.clientY - drag.current.y)) })}
          onPointerUp={() => (drag.current = null)}
          onPointerLeave={() => (drag.current = null)}
        >
          <div className="twin-scene ex-scene" style={{ transform: `translate3d(${pan.x}px, ${pan.y}px, 0) translateY(-50%) scale(${zoom})` }}>
            <img src={digitalTwin} alt="OPTIMO Changing and Washroom Suite digital twin" draggable={false} />
            <div className="twin-grounding" />
            {nodes.map((f) => {
              const p = SCENE_POS[f.id] ?? { x: f.x, y: f.y }
              const faded = nodeClass(f, layer) === "dim" || (!!selected && selected !== f.id)
              return (
                <button
                  key={f.id}
                  className={`twin-marker ${tone(f)} ${selected === f.id ? "selected" : ""} ${faded ? "faded" : ""} ${p.x > 75 ? "edge-right" : ""} ${changed.has(f.id) ? "pulse" : ""} ${f.device === "Offline" ? "offline" : ""}`}
                  style={{ left: `${p.x}%`, top: `${p.y}%` }}
                  aria-label={`${f.id}, ${f.type}, ${displayStatus(f)}`}
                  aria-pressed={selected === f.id}
                  onPointerDown={(e) => e.stopPropagation()}
                  onClick={() => select(f.id)}
                  onKeyDown={(e) => {
                    if (!["ArrowRight", "ArrowLeft", "ArrowDown", "ArrowUp"].includes(e.key)) return
                    e.preventDefault()
                    const i = nodes.indexOf(f)
                    const n = nodes[(i + (e.key === "ArrowRight" || e.key === "ArrowDown" ? 1 : nodes.length - 1)) % nodes.length]
                    ;(e.currentTarget.parentElement?.querySelector(`[aria-label^="${n.id},"]`) as HTMLElement)?.focus()
                  }}
                >
                  <i />
                  <span>
                    <bdi>{f.id}</bdi>
                    {f.device === "Offline" && <Svg d={ic.wifiOff} size={10} />}
                    {layer === "Bin fill" && f.type === "Bin" && <b className="tnum">{f.binFill}%</b>}
                  </span>
                  <em>
                    <b><bdi>{f.id}</bdi></b>
                    <small>{t(f.type)} · {t(f.zone)}</small>
                    <strong>{t(reading(f))}</strong>
                  </em>
                </button>
              )
            })}
          </div>
          <div className="twin-orientation ex-orient"><span>{Math.round(zoom * 100)}%</span><i /><span>Elevated cutaway</span></div>
          <div className="twin-camera-controls" onPointerDown={(e) => e.stopPropagation()}>
            <button onClick={() => setZoom((z) => Math.min(1.8, z + 0.12))} title="Zoom in" aria-label="Zoom in"><Svg d={ic.plus} size={16} /></button>
            <button onClick={() => setZoom((z) => Math.max(1, z - 0.12))} title="Zoom out" aria-label="Zoom out"><Svg d={ic.minus} size={16} /></button>
            <button onClick={() => (setZoom(1), setPan({ x: 0, y: 0 }))} title={t("Reset view")} aria-label={t("Reset view")}><Svg d={ic.reset} size={16} /></button>
          </div>
          <div className="map-key twin-key ex-key" aria-label="Legend">
            <span><i className="ready" />{t("Ready")}</span>
            <span><i className="attention" />{t("Attention")}</span>
            <span><i className="critical" />{t("Critical")}</span>
            <span><i className="cleaning" />{t("Cleaning")}</span>
            <span><Svg d={ic.wifiOff} size={11} />{t("Offline")}</span>
          </div>
        </div>
        {sel && <Inspector f={sel} s={s} close={() => select(undefined)} lang={lang} />}
      </div>
    </section>
  )
}

/* Read-only facility inspector — inside the twin card, end side, 320 wide */
function Inspector({ f, s, close, lang }: { f: Facility; s: State; close: () => void; lang: Lang }) {
  const t = useT()
  const [drawer, setDrawer] = useState<"task" | "history" | null>(null)
  const task = f.task && f.task.status !== "Completed" ? f.task : undefined
  const last = f.task?.status === "Completed" ? f.task : undefined
  const issue = s.issues.find((i) => i.facility === f.id || (f.type === "Leak point" && i.category === "Leakage"))
  const recent = s.activity.filter((a) => a.facility === f.id).slice(0, 3)
  return (
    <aside className="ex-inspector" aria-label={`${f.id} facility detail`} onKeyDown={(e) => e.key === "Escape" && close()}>
      <header>
        <div>
          <small className="ex-eyebrow">{t(f.zone)} · {f.level}</small>
          <h3><Code>{f.id}</Code> · {t(f.type)}</h3>
        </div>
        <IconBtn label={t("Close")} d={ic.close} onClick={close} />
      </header>
      <div className="ex-photo" aria-label="Placeholder — official photo to follow"><span>Placeholder — official photo to follow</span></div>
      <dl>
        <dt>Service status</dt><dd><FacilityChip value={displayStatus(f)} type={f.type} /></dd>
        {f.type !== "Bin" && f.type !== "Leak point" && <><dt>{t("Occupancy")}</dt><dd><OccupancyDot value={f.occupancy} /></dd></>}
        <dt>{t("Device")}</dt><dd><SignalBars value={f.device} /></dd>
        <dt>Latest reading</dt>
        <dd className="tnum">
          {f.type === "Bin" ? `Fill ${f.binFill}% / 80% threshold` : f.type === "Toilet" ? `${f.usage} / 60 uses since cleaning` : f.type === "Leak point" ? (f.status === "Ready" ? "No moisture" : "Moisture detected") : f.occupancy}
          <small className="ex-muted"> · {clock(s.now - 40000, lang)}</small>
        </dd>
        {task && <>
          <dt>{t("Task")}</dt><dd><TaskPill value={task.status} /><Code>{task.id}</Code></dd>
          <dt>Assigned</dt><dd>{task.assignee ?? t("Unassigned")}</dd>
          <dt>{t(task.status === "New" ? "Response SLA" : "Completion SLA")}</dt>
          <dd><SlaRing status={slaStatus(task, s.now)} left={task.status === "New" ? responseSla(task, s.now) : completionSla(task, s.now)} total={(task.status === "New" ? task.responseTarget : task.completionTarget) * 60000} label={task.status === "New" ? "Response time" : "Completion time"} /></dd>
        </>}
        <dt>Last service</dt><dd>{last ? `${last.assignee} · ${clock(s.now - 120000, lang)}` : `Noura Al-Salem · ${clock(s.now - 52 * 60000, lang)}`}</dd>
        {f.type === "Leak point" && issue && <><dt>Linked issue</dt><dd><Code>{issue.id}</Code> · {issue.status}</dd></>}
      </dl>
      {f.type === "Toilet" || f.type === "Bin" ? <p className="ex-note">Threshold set by administrator.</p> : null}
      {f.occupancy === "Vacant" && f.status === "Service Required" && <p className="ex-note warn">Vacant is not clean — service still required.</p>}
      {f.device !== "Online" && <p className="ex-note bad"><Svg d={ic.wifiOff} size={12} />{t("Device offline — facility status unknown. It is excluded from Ready.")}</p>}
      {recent.length > 0 && (
        <ul className="ex-mini-feed">{recent.map((a) => <li key={a.at + a.event}><span className="tnum">{clock(a.at, lang)}</span>{a.event}</li>)}</ul>
      )}
      <div className="ex-inspector-actions">
        {(task || last) && <button className="ex-btn secondary" onClick={() => setDrawer("task")}>View Task</button>}
        <Tertiary onClick={() => setDrawer("history")}>View History</Tertiary>
      </div>
      <Drawer title={drawer === "task" ? `Task ${(task ?? last)?.id ?? ""}` : `${f.id} history`} code="Read-only" open={!!drawer} close={() => setDrawer(null)}>
        {drawer === "task" && (task ?? last) && (() => {
          const tk = (task ?? last)!
          return (
            <>
              <dl className="ex-ledger-dl">
                <dt>Status</dt><dd><TaskPill value={tk.status} /></dd>
                <dt>Facility</dt><dd><Code>{f.id}</Code> · {t(f.zone)}</dd>
                <dt>Handled by</dt><dd>{tk.assignee ?? "Awaiting acceptance"} · Supervisor Khalid Al-Mutairi</dd>
                <dt>Created</dt><dd className="tnum">{clock(tk.createdAt, lang)}</dd>
                {tk.status !== "Completed" && <><dt>SLA</dt><dd><SlaRing status={slaStatus(tk, s.now)} left={tk.status === "New" ? responseSla(tk, s.now) : completionSla(tk, s.now)} total={(tk.status === "New" ? tk.responseTarget : tk.completionTarget) * 60000} label="SLA" /></dd></>}
              </dl>
              <p className="ex-note">{t("Accept and reassign do not restart the Completion SLA.")}</p>
            </>
          )
        })()}
        {drawer === "history" && (
          <ol className="ex-timeline">
            {[...s.activity.filter((a) => a.facility === f.id).map((a) => `${clock(a.at, lang)} ${a.event}`), ...(issue?.history ?? []), `${clock(s.now - 52 * 60000, lang)} Cleaning completed · Noura Al-Salem`].map((h) => <li key={h}>{h}</li>)}
          </ol>
        )}
      </Drawer>
    </aside>
  )
}

/* ---------- Row 2B ---------- */
function Rail({ label, value, target, delta }: { label: string; value: number; target: number; delta: number }) {
  const v = useCount(value)
  return (
    <div className="ex-rail-block">
      <div className="ex-rail-row"><small>{label}</small><strong className="tnum">{Math.round(v)}%</strong></div>
      <div className="ex-rail" role="img" aria-label={`${label} ${value}% against target ${target}%`}>
        <i style={{ inlineSize: `${v}%` }} />
        <b style={{ insetInlineStart: `${target}%` }} />
      </div>
      <span className="ex-rail-cap">
        Target {target}% · <Delta dir={delta >= 0 ? "up" : "down"}>{Math.abs(delta)} pt {delta >= 0 ? "above" : "below"} target</Delta>
      </span>
    </div>
  )
}
function ServiceLevel({ m }: { m: M }) {
  return (
    <section className="ex-card ex-half">
      <div className="ex-card-head"><div><span className="ex-eyebrow">TODAY · LIVE</span><h3>Service Level</h3></div></div>
      <div className="ex-rails">
        <Rail label="Response SLA" value={m.response} target={95} delta={m.response - 95} />
        <Rail label="Completion SLA" value={m.completion} target={90} delta={m.completion - 90} />
      </div>
    </section>
  )
}

type Attention = { id: string; facility: string; line1: string; line2: string; line3: string; tone: "bad" | "warn" }
function attention(s: State): Attention[] {
  const items: (Attention & { rank: number })[] = []
  s.issues.filter((i) => i.severity === "High").forEach((i) =>
    items.push({ id: i.id, facility: i.facility === "SH-06" ? "LK-06" : i.facility, line1: `${i.title} · ${i.severity}`, line2: `Handled by ${i.owner.split(" ")[0]} · ${i.status}`, line3: `Open for ${fmtClock(s.now - i.openedAt)}`, tone: "bad", rank: 3 }),
  )
  s.facilities.forEach((f) => {
    const tk = f.task
    if (f.device === "Offline") items.push({ id: f.id, facility: f.id, line1: `${f.id} · ${f.type} · Device offline`, line2: "Status unknown · Supervisor notified · Manual check available", line3: "Not counted as Ready", tone: "warn", rank: 2 })
    if (!tk || tk.status === "Completed") return
    const st = slaStatus(tk, s.now)
    if (st === "Within Target") return
    const left = tk.status === "New" ? responseSla(tk, s.now) : completionSla(tk, s.now)
    const handling = tk.assignee ? (f.id === "BS-01" ? `Supervisor notified · Reassigned to ${tk.assignee.split(" ")[0]}` : `Supervisor notified · Assigned to ${tk.assignee.split(" ")[0]}`) : st === "Breached" ? "Supervisor notified · Awaiting reassignment" : "Awaiting acceptance"
    items.push({
      id: f.id, facility: f.id,
      line1: `${f.id} · ${f.type} · ${f.zone}`,
      line2: handling,
      line3: st === "Breached" ? `Overdue by ${fmtClock(left)}` : tk.status === "New" ? `Response due in ${fmtClock(left)}` : `SLA breach in ${fmtClock(left)}`,
      tone: st === "Breached" ? "bad" : "warn", rank: st === "Breached" ? 2.5 : 1,
    })
  })
  return items.sort((a, b) => b.rank - a.rank)
}
function ManagementAttention({ items, focus, go, marks }: { items: Attention[]; focus: (id: string) => void; go: () => void; marks: boolean }) {
  return (
    <section className="ex-card ex-half" aria-live="polite">
      <div className="ex-card-head"><h3>Management Attention <Mark n={3} show={marks} /></h3><Tertiary onClick={go}>All issues <Svg d={ic.arrow} size={12} /></Tertiary></div>
      {items.length === 0 ? (
        <p className="ex-calm"><Svg d={ic.check} size={16} />All monitored facilities are operating normally.</p>
      ) : (
        <ul className="ex-attn">
          {items.slice(0, 4).map((a) => (
            <li key={a.id}>
              <button onClick={() => focus(a.facility)} className={a.tone}>
                <span className="ex-attn-1"><Svg d={a.tone === "bad" ? ic.issues : ic.bell} size={12} />{a.line1}</span>
                <span className="ex-attn-2">{a.line2}</span>
                <span className="ex-attn-3 tnum">{a.line3}</span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </section>
  )
}

/* ---------- Row 3: Service Performance (speed + quality) ---------- */
const SERIES: Record<Exclude<Period, "Custom">, { x: string[]; sla: number[]; pass: number[]; prev: number[] }> = {
  Today: { x: ["06:00", "07:00", "08:00", "09:00", "10:00", "11:00", "12:00", "13:00"], sla: [97, 95, 92, 93, 96, 94, 95, 94], pass: [95, 94, 93, 92, 94, 95, 94, 94], prev: [93, 92, 90, 91, 92, 93, 92, 92] },
  "7 days": { x: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], sla: [93, 94, 92, 95, 94, 96, 94], pass: [92, 93, 95, 94, 93, 95, 94], prev: [91, 92, 92, 93, 91, 93, 92] },
  "30 days": { x: ["W1", "W2", "W3", "W4", "W5"], sla: [91, 92, 93, 94, 94], pass: [90, 92, 93, 93, 94], prev: [89, 90, 90, 91, 92] },
}
function TrendChart({ period, setPeriod, compare, setCompare, liveSla }: { period: Period; setPeriod: (p: Period) => void; compare: boolean; setCompare: (c: boolean) => void; liveSla: number }) {
  const key = period === "Custom" ? "7 days" : period
  const d = SERIES[key]
  const sla = key === "Today" ? [...d.sla.slice(0, -1), liveSla] : d.sla
  const [hover, setHover] = useState<number>()
  const W = 800, H = 180, lo = 84, hi = 100
  const n = d.x.length, last = n - 1
  const X = (i: number) => (i * W) / last
  const Y = (v: number) => ((hi - v) / (hi - lo)) * H
  const path = (arr: number[]) => arr.map((v, i) => `${i ? "L" : "M"}${X(i)},${Y(v)}`).join(" ")
  const pct = (v: number) => `${(Y(v) / H) * 100}%`
  const gap = sla[last] - 95
  const onMove = (e: RMouseEvent<HTMLDivElement>) => {
    const r = e.currentTarget.getBoundingClientRect()
    const f = Math.min(1, Math.max(0, (e.clientX - r.left) / r.width))
    setHover(Math.round(f * last))
  }
  return (
    <section className="ex-card ex-trend">
      <div className="ex-card-head">
        <div>
          <span className="ex-eyebrow">{key === "Today" ? "TODAY · 06:00—NOW" : key === "7 days" ? "LAST 7 DAYS" : "LAST 30 DAYS"}</span>
          <h3>Service Performance</h3>
        </div>
        <div className="ex-head-controls">
          <div className="ex-chips" role="radiogroup" aria-label="Period">
            {(["Today", "7 days", "30 days"] as const).map((p) => <button key={p} role="radio" aria-checked={key === p} className={key === p ? "active" : ""} onClick={() => setPeriod(p)}>{p}</button>)}
          </div>
          <label className="ex-switch"><input type="checkbox" checked={compare} onChange={(e) => setCompare(e.target.checked)} /><span />Compare</label>
        </div>
      </div>
      <div className="ex-metric">
        <strong className="tnum">{sla[last]}%</strong>
        <span>SLA compliance · pass rate {d.pass[last]}%</span>
        <em className="tnum" style={gap < 0 ? { color: "var(--yellow)" } : undefined}>{Math.abs(gap)} pt {gap >= 0 ? "above" : "below"} 95% target{compare ? ` · ${sla[last] - d.prev[last] >= 0 ? "+" : ""}${sla[last] - d.prev[last]} pt vs previous` : ""}</em>
      </div>
      <div className="ex-legend-inline" aria-hidden="true">
        <span><i />SLA compliance</span><span><i className="pass" />Inspection pass rate</span>{compare && <span><i className="prev" />Previous period</span>}
      </div>
      <div className="ex-chart" dir="ltr">
        {[96, 92, 88].map((g) => <span key={g} className="ex-y tnum" style={{ top: pct(g) }}>{g}%</span>)}
        <div className="ex-chart-plot" onMouseMove={onMove} onMouseLeave={() => setHover(undefined)}>
          <svg viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" role="img" aria-label={`Line chart of SLA compliance and inspection pass rate. Latest SLA ${sla[last]}%, pass rate ${d.pass[last]}%, target 95%.`}>
            <defs><linearGradient id="exfill" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stopColor="var(--yellow)" stopOpacity=".16" /><stop offset="1" stopColor="var(--yellow)" stopOpacity="0" /></linearGradient></defs>
            {[96, 92, 88].map((g) => <line key={g} x1={0} x2={W} y1={Y(g)} y2={Y(g)} className="grid" />)}
            <line x1={0} x2={W} y1={Y(95)} y2={Y(95)} className="target" />
            <path d={`${path(sla)} L${W},${H} L0,${H} Z`} fill="url(#exfill)" />
            {compare && <path d={path(d.prev)} className="prev" />}
            <path d={path(d.pass)} className="pass" />
            <path d={path(sla)} className="sla" />
            {hover !== undefined && <line x1={X(hover)} x2={X(hover)} y1={0} y2={H} className="cursor" />}
          </svg>
          {hover !== undefined && <>
            <i className="ex-dot" style={{ left: `${(hover / last) * 100}%`, top: pct(sla[hover]) }} />
            <i className="ex-dot pass" style={{ left: `${(hover / last) * 100}%`, top: pct(d.pass[hover]) }} />
            <div className="ex-chart-tip" style={{ left: `clamp(0px, calc(${(hover / last) * 100}% - 74px), calc(100% - 148px))` }}>
              <b>{d.x[hover]}</b>
              <span>SLA <strong>{sla[hover]}%</strong></span>
              <span>Pass rate <strong>{d.pass[hover]}%</strong></span>
              <span>Target <strong>95%</strong></span>
            </div>
          </>}
        </div>
        <div className="ex-chart-labels">{d.x.map((x) => <span key={x}>{x}</span>)}</div>
      </div>
    </section>
  )
}

function LiveActivity({ s, lang, openAll }: { s: State; lang: Lang; openAll: () => void }) {
  // Never reorder under the cursor: freeze while hovered, offer "N new · Show".
  const [frozen, setFrozen] = useState<typeof s.activity | null>(null)
  const shown = frozen ?? s.activity
  const fresh = frozen ? s.activity.length - frozen.length : 0
  return (
    <section className="ex-card ex-activity" onMouseEnter={() => setFrozen(s.activity)} onMouseLeave={() => setFrozen(null)}>
      <div className="ex-card-head">
        <h3>Live Activity</h3>
        {fresh > 0 && <Tertiary onClick={() => setFrozen(s.activity)}>{fresh} new · Show</Tertiary>}
      </div>
      <ul className="ex-feed">
        {shown.slice(0, 4).map((a) => (
          <li key={a.at + a.event + a.facility}>
            <span className="tnum">{clock(a.at, lang)}</span>
            <Code>{a.facility}</Code>
            <p>{a.event}</p>
          </li>
        ))}
      </ul>
      <Tertiary onClick={openAll}>View all activity <Svg d={ic.arrow} size={12} /></Tertiary>
    </section>
  )
}

function CenterSkeleton() {
  return (
    <div className="ex-grid" aria-busy="true" aria-label="Loading">
      <i className="ex-sk" style={{ gridColumn: "1 / -1", blockSize: 136 }} />
      <i className="ex-sk" style={{ gridColumn: "span 8", blockSize: 504 }} />
      <div className="ex-col4"><i className="ex-sk" style={{ blockSize: 240 }} /><i className="ex-sk" style={{ blockSize: 240 }} /></div>
      <i className="ex-sk" style={{ gridColumn: "span 8", blockSize: 296 }} />
      <i className="ex-sk" style={{ gridColumn: "span 4", blockSize: 296 }} />
    </div>
  )
}

function PermissionState({ back }: { back: () => void }) {
  return (
    <div className="ex-state">
      <Svg d={ic.lock} size={28} />
      <h2>This area is available to supervisors and administrators.</h2>
      <p>Your Executive account has a read-only overview. Task, schedule and team detail is reachable as read-only drill-downs from the Excellence Center and Reports.</p>
      <button className="ex-btn secondary" onClick={back}>Back to Excellence Center</button>
    </div>
  )
}

const PAGE_NOTES: Record<ExPage, string[]> = {
  "Excellence Center": [],
  Quality: ["Pass rate = passed ÷ total inspections", "Zones below target are highlighted", "Original task stays in history; rework is linked"],
  Issues: ["Severity is set by the Supervisor, read-only here", "Repeated zones suggest a root cause", "No create, assign or close actions for Executives"],
  Reports: ["Narrative is generated from live store values", "Numbers match Quality Overview", "Export is the only write-like action, and it is offline-aware"],
}

/* ---------- shell ---------- */
export default function ExecutiveApp({ language, setLanguage, logout }: { language: Lang; setLanguage: (l: Lang) => void; logout: () => void }) {
  const t = useMemo(() => translate(language), [language])
  const s = useStore()
  const m = metrics(s)
  const [page, setPage] = useState<ExPage>("Excellence Center")
  const [denied, setDenied] = useState(FORBIDDEN.includes(location.hash))
  const [mode, setMode] = useState<Mode>("Loading")
  const [period, setPeriod] = useState<Period>("Today")
  const [compare, setCompare] = useState(false)
  const [customOpen, setCustomOpen] = useState(false)
  const [location_, setLocation] = useState("Main Club · All floors")
  const [selected, setSelected] = useState<string>()
  const [filter, setFilter] = useState("All")
  const [presenter, setPresenter] = useState(false)
  const [confirmReset, setConfirmReset] = useState(false)
  const [notes, setNotes] = useState(false)
  const [allActivity, setAllActivity] = useState(false)
  const [tab, setTab] = useState<"All" | "Unread" | "Critical">("All")
  const [sound, setSound] = useState(false)
  const [menu, setMenu] = useState(false)
  const [presenting, setPresenting] = useState(false)
  const [chrome, setChrome] = useState(true)
  const [toasts, setToasts] = useState<Notice[]>([])
  const [intent, setIntent] = useState<Intent>()
  const [exportFail, setExportFail] = useState(false)
  const seen = useRef(new Set(s.notices.map((n) => n.id)))
  const sc = scenarios[s.scenario]
  const unread = s.notices.filter((n) => n.unread).length
  const stale = mode === "Stale"
  const conn = stale ? "Offline" : s.facilities.some((f) => f.device === "Delayed") ? "Delayed" : "Online"
  const attn = attention(s)
  const offline = !s.online
  const titles: Record<ExPage, string> = { "Excellence Center": "Hospitality Excellence Center", Quality: "Quality Overview", Issues: "Issues Register", Reports: "Performance Briefing" }
  const blurb: Record<ExPage, string> = {
    "Excellence Center": "Live club performance and service quality. ",
    Quality: "Inspection results, failure patterns and rework. ",
    Issues: "Open risks, aging and hotspots across the club. ",
    Reports: "A narrative briefing with drill-down ledgers and export. ",
  }
  const pageProps = { s, lang: language, notes: s.annotations, focus: (id: string) => focus(id), intent }
  const open = (p: ExPage, kind: string, id?: string) => (go(p), setIntent({ kind, id, n: Date.now() }))

  useEffect(() => { const id = setTimeout(() => setMode("Live"), 900); return () => clearTimeout(id) }, [])
  useEffect(() => {
    const onHash = () => setDenied(FORBIDDEN.includes(location.hash))
    window.addEventListener("hashchange", onHash)
    return () => window.removeEventListener("hashchange", onHash)
  }, [])
  useEffect(() => {
    const key = (e: KeyboardEvent) => {
      if (e.shiftKey && e.key.toLowerCase() === "p" && !(e.target instanceof HTMLInputElement)) setPresenter((v) => !v)
      if (e.key === "Escape" && presenting && !presenter) setPresenting(false)
    }
    document.addEventListener("keydown", key)
    return () => document.removeEventListener("keydown", key)
  }, [presenting, presenter])
  // Toasts: executive-relevant (critical) notices only; max 3; 8s except critical.
  useEffect(() => {
    const fresh = s.notices.filter((n) => !seen.current.has(n.id))
    fresh.forEach((n) => seen.current.add(n.id))
    const relevant = fresh.filter((n) => n.critical)
    if (!relevant.length) return
    setToasts((cur) => [...relevant, ...cur].slice(0, 3))
    relevant.forEach((n) => { if (!/leak|out of service/i.test(n.title)) setTimeout(() => setToasts((c) => c.filter((x) => x.id !== n.id)), 8000) })
  }, [s.notices])
  // Presentation mode: controls auto-hide after 3s of inactivity.
  useEffect(() => {
    if (!presenting) return setChrome(true)
    let id = setTimeout(() => setChrome(false), 3000)
    const wake = () => (setChrome(true), clearTimeout(id), (id = setTimeout(() => setChrome(false), 3000)))
    window.addEventListener("pointermove", wake)
    window.addEventListener("keydown", wake)
    return () => (clearTimeout(id), window.removeEventListener("pointermove", wake), window.removeEventListener("keydown", wake))
  }, [presenting])

  const focus = (id?: string) => (setPage("Excellence Center"), setFilter("All"), setSelected(id))
  const go = (p: ExPage) => (setPage(p), setDenied(false), history.replaceState(null, "", " "))
  const nav: [ExPage, string][] = [["Excellence Center", ic.grid], ["Quality", ic.quality], ["Issues", ic.issues], ["Reports", ic.doc]]
  const list = s.notices.filter((n) => tab === "All" || (tab === "Unread" ? n.unread : n.critical))
  const today = list.filter((n) => s.now - n.at < 60 * 60000)
  const earlier = list.filter((n) => s.now - n.at >= 60 * 60000)
  const announce = attn[0] ? `${attn[0].line1}. ${attn[0].line2}.` : "All monitored facilities are operating normally."

  const center = (
    <div className="ex-grid">
      <div className="ex-span12"><Strip m={m} filter={filter} setFilter={setFilter} go={go} compare={compare} /></div>
      <div className={presenting ? "ex-span12" : "ex-span8"}>
        <Twin s={s} selected={selected} select={setSelected} filter={filter} setFilter={setFilter} togglePresent={() => setPresenting(!presenting)} presenting={presenting} stale={stale} lang={language} />
      </div>
      {!presenting && (
        <div className="ex-col4">
          <ServiceLevel m={m} />
          <ManagementAttention items={attn} focus={focus} go={() => go("Issues")} marks={s.annotations && s.changed.includes("risks")} />
        </div>
      )}
      {!presenting ? (
        <>
          <div className="ex-span8"><TrendChart period={period} setPeriod={(p) => (p === "Custom" ? setCustomOpen(true) : setPeriod(p))} compare={compare} setCompare={setCompare} liveSla={m.sla} /></div>
          <div className="ex-span4"><LiveActivity s={s} lang={language} openAll={() => setAllActivity(true)} /></div>
        </>
      ) : (
        <div className="ex-span12 ex-present-feed">
          {s.activity.slice(0, 3).map((a) => <span key={a.at + a.event}><b className="tnum">{clock(a.at, language)}</b><Code>{a.facility}</Code>{a.event}</span>)}
        </div>
      )}
    </div>
  )

  return (
    <T.Provider value={t}>
      <div className={`ex-shell ${presenting ? "presenting" : ""} ${presenting && !chrome ? "chrome-hidden" : ""}`} dir={language === "ar" ? "rtl" : "ltr"} lang={language}>
        <p className="sr" aria-live="polite">{announce}</p>
        {!presenting && (
          <aside className="ex-side">
            <div className="ex-logo" aria-label="OPTIMO">OPTIMO</div>
            <nav aria-label="Executive">
              {nav.map(([p, d]) => (
                <button key={p} className={page === p && !denied ? "active" : ""} aria-current={page === p ? "page" : undefined} onClick={() => go(p)}>
                  <Svg d={d} /><span>{t(p)}</span>
                </button>
              ))}
            </nav>
            <div className="ex-side-foot">
              <small className="ex-eyebrow">{t("Main Club")}</small>
              <span><i className={m.offline ? "warn" : "ok"} />{m.online} {t("devices online")}</span>
            </div>
          </aside>
        )}
        <div className="ex-body">
          <header className="ex-header">
            <div className="ex-header-title">
              {presenting && <span className="ex-logo inline">OPTIMO</span>}
              {presenting && <h1>Hospitality Excellence Center</h1>}
              {presenting && <span className="ex-head-chip">{location_}</span>}
            </div>
            <div className="ex-header-tools">
              <span className={`ex-head-chip conn ${conn.toLowerCase()}`}><Svg d={conn === "Online" ? ic.wifi : ic.wifiOff} size={14} />{t(conn)}<bdi className="tnum">{clock(s.now, language)}</bdi></span>
              <span className="ex-demo" role="status"><i aria-hidden="true" />{t("Demo")}{s.speed > 1 && <em className="tnum">{t("Accelerated time")} ×{s.speed}</em>}</span>
              <IconBtn label={t("Notifications")} d={ic.bell} badge={unread} onClick={() => setNotes(true)} />
              {!presenting && <button className="ex-btn secondary" onClick={() => setPresenting(true)}><Svg d={ic.present} size={14} />Present</button>}
              {presenting && <IconBtn label={t("Exit full screen")} d={ic.exitFull} onClick={() => setPresenting(false)} />}
              {!presenting && (
                <div className="ex-select">
                  <button className="ex-user" aria-label="User menu" aria-expanded={menu} onClick={() => setMenu(!menu)}>
                    <span className="ex-avatar">FR</span>
                    <span className="ex-user-text"><b>Fahad Al-Rashid</b><span className="ex-role" title="Read-only access">Executive</span></span>
                  </button>
                  {menu && (
                    <div className="ex-pop end" onKeyDown={(e) => e.key === "Escape" && setMenu(false)}>
                      <p className="ex-pop-label">Read-only access</p>
                      <p className="ex-pop-label">{t("Language")}</p>
                      {(["en", "ar"] as Lang[]).map((l) => (
                        <button key={l} lang={l} className={language === l ? "selected" : ""} onClick={() => (setLanguage(l), setMenu(false))}>
                          {l === "en" ? "English" : "العربية"}{language === l && <Svg d={ic.check} size={12} />}
                        </button>
                      ))}
                      <hr />
                      <button onClick={logout}>{t("Sign out")}</button>
                    </div>
                  )}
                </div>
              )}
            </div>
          </header>

          <main className="ex-content">
            {!presenting && (
              <div className="ex-intro">
                <div className="ex-intro-copy">
                  <h1>{t(titles[page])}</h1>
                  <p>{t(blurb[page])}<span className="ex-live"><i />{t(stale ? "STALE · LAST UPDATED 10:24" : "LIVE OPERATIONS · UPDATED NOW")}</span></p>
                </div>
                {page === "Excellence Center" && <div className="ex-intro-actions">
                  <Select icon={ic.layers} value={location_} options={["Main Club · All floors", "Main Club · L01", "Main Club · L02", "Main Club · Rooftop"]} onChange={setLocation} />
                  <Select value={period} options={["Today", "7 days", "30 days", "Custom"]} onChange={(v) => (v === "Custom" ? setCustomOpen(true) : setPeriod(v as Period))} />
                  <label className="ex-switch" title="Applies to trends and reports, never to live status"><input type="checkbox" checked={compare} onChange={(e) => setCompare(e.target.checked)} /><span />Compare</label>
                </div>}
              </div>
            )}
            {stale && !denied && (
              <p className="ex-banner warn" role="status">
                <Svg d={ic.wifiOff} size={14} />Live facility data temporarily unavailable. Last updated 10:24 AM.
                <Tertiary onClick={() => (setMode("Loading"), setTimeout(() => setMode("Live"), 900))}>Retry</Tertiary>
              </p>
            )}
            {offline && !denied && (
              <p className="ex-banner warn" role="status">
                <Svg d={ic.wifiOff} size={14} />{t("You're offline. Actions are queued and will sync when you reconnect.")}
                <Tertiary onClick={() => actions.setOnline(true)}>{t("Reconnect")}</Tertiary>
              </p>
            )}
            {denied ? <PermissionState back={() => go("Excellence Center")} />
              : mode === "Loading" ? (page === "Excellence Center" ? <CenterSkeleton /> : <PageSkeleton page={page} />)
                : mode === "Error" || mode === "Empty" ? <StateCard kind={mode === "Error" ? "error" : "empty"} retry={() => (setMode("Loading"), setTimeout(() => setMode("Live"), 900))} change={page === "Excellence Center" ? undefined : () => (setMode("Live"), go("Excellence Center"))} />
                  : page === "Quality" ? <QualityPage {...pageProps} />
                    : page === "Issues" ? <IssuesPage {...pageProps} />
                      : page === "Reports" ? <ReportsPage {...pageProps} m={m} online={s.online} exportFail={exportFail} />
                        : center}
          </main>
        </div>

        {s.annotations && page !== "Excellence Center" && !denied && mode === "Live" && (
          <div className="ex-annot-legend ex-notes" aria-label="Dev notes">
            <small className="ex-eyebrow">{t("Dev notes")}</small>
            {PAGE_NOTES[page].map((n, i) => <span key={n}><Mark n={i + 1} show />{t(n)}</span>)}
          </div>
        )}
        {s.annotations && page === "Excellence Center" && s.changed.length > 0 && (
          <div className="ex-annot-legend" aria-label="Annotation legend">
            <small className="ex-eyebrow">{t("Changed after last step")}</small>
            {[["node", 2, "Twin node"], ["risks", 3, "Management Attention"]]
              .filter(([k]) => s.changed.includes(k as string))
              .map(([k, n, l]) => <span key={k as string}><Mark n={n as number} show />{l}</span>)}
            <span>Strip · Activity · Bell update live</span>
          </div>
        )}

        <div className="ex-toasts" aria-live="polite">
          {toasts.map((n) => (
            <div className="ex-toast" role="status" key={n.id}>
              <Svg d={/leak|breach|offline/i.test(n.title) ? ic.issues : ic.bell} size={16} />
              <div>
                <strong>{n.title}</strong>
                <small className="tnum">{n.detail} · {clock(n.at, language)}</small>
              </div>
              <Tertiary onClick={() => (focus(n.facility), setToasts((c) => c.filter((x) => x.id !== n.id)))}>{t("View")}</Tertiary>
              <IconBtn label={t("Close")} d={ic.close} onClick={() => setToasts((c) => c.filter((x) => x.id !== n.id))} />
            </div>
          ))}
        </div>

        <Drawer title="Notifications" open={notes} close={() => setNotes(false)} width={420}
          footer={<>
            <label className="ex-switch"><input type="checkbox" checked={sound} onChange={(e) => setSound(e.target.checked)} /><span />{t("Sound")} <em className="ex-confirm">To confirm</em></label>
            <Tertiary onClick={actions.markRead}>{t("Mark all read")}</Tertiary>
          </>}>
          <div className="ex-tabs" role="tablist">
            {(["All", "Unread", "Critical"] as const).map((x) => (
              <button key={x} role="tab" aria-selected={tab === x} className={tab === x ? "active" : ""} onClick={() => setTab(x)}>{t(x)}</button>
            ))}
          </div>
          {list.length === 0 ? <p className="ex-calm"><Svg d={ic.check} size={14} />No notifications here.</p> : (
            [["Today", today], ["Earlier", earlier]].map(([g, items]) => (items as Notice[]).length > 0 && (
              <div key={g as string}>
                <p className="ex-eyebrow">{g as string}</p>
                <ul className="ex-notices">
                  {(items as Notice[]).map((n) => (
                    <li key={n.id}>
                      <button className={n.unread ? "unread" : ""} onClick={() => (n.facility && focus(n.facility), setNotes(false))}>
                        <strong>{n.critical && <span className="ex-crit">Critical</span>}{n.title}</strong>
                        <small>{n.detail} · <span className="tnum">{clock(n.at, language)}</span></small>
                      </button>
                    </li>
                  ))}
                </ul>
              </div>
            ))
          )}
        </Drawer>

        <Drawer title="All activity" code="Read-only" open={allActivity} close={() => setAllActivity(false)}>
          <ul className="ex-feed">
            {s.activity.map((a) => <li key={a.at + a.event + a.facility}><span className="tnum">{clock(a.at, language)}</span><Code>{a.facility}</Code><p>{a.event}</p></li>)}
          </ul>
        </Drawer>

        <Dialog title="Custom date range" open={customOpen} close={() => setCustomOpen(false)}
          actions={<>
            <button className="ex-btn secondary" onClick={() => setCustomOpen(false)}>{t("Cancel")}</button>
            <button className="ex-btn primary" onClick={() => (setPeriod("Custom"), setCustomOpen(false))}>Apply</button>
          </>}>
          <div className="ex-form ex-pad">
            <label>From<input type="date" defaultValue="2026-09-27" /></label>
            <label>To<input type="date" defaultValue="2026-10-04" /></label>
            <small className="ex-muted">{t("Club time · Asia/Riyadh")} · week starts Sunday (to confirm)</small>
          </div>
        </Dialog>

        {/* Presenter Panel — demo control, never part of Executive navigation (Shift+P or header icon in demo) */}
        {!presenting && <button className="ex-presenter-fab" aria-label="Presenter Panel (Shift+P)" title="Presenter Panel (Shift+P)" onClick={() => setPresenter(true)}><Svg d={ic.play} size={12} /></button>}
        <Drawer title="Presenter Panel" code="Demo control · Shift+P" open={presenter} close={() => setPresenter(false)}
          footer={<>
            <button className="ex-btn destructive" onClick={() => setConfirmReset(true)}>{t("Reset demo data")}</button>
            <span className="ex-divider" aria-hidden="true" />
            <button className="ex-btn primary" disabled={s.step >= sc.steps.length} onClick={actions.advance}>
              {s.step >= sc.steps.length ? t("Scenario complete") : t("Advance step")}
            </button>
          </>}>
          <div className="ex-form">
            <label>{t("Scenario")}
              <select value={s.scenario} onChange={(e) => actions.setScenario(+e.target.value)}>
                {scenarios.map((x, i) => <option key={x.name} value={i}>{i + 1}. {x.name}</option>)}
              </select>
            </label>
            <div>
              <span className="ex-label">{t("Speed")}</span>
              <div className="ex-seg" role="radiogroup">
                {([1, 5, 10] as const).map((v) => <button key={v} role="radio" aria-checked={s.speed === v} className={s.speed === v ? "active" : ""} onClick={() => actions.setSpeed(v)}>×{v}</button>)}
              </div>
            </div>
            <label className="ex-toggle"><input type="checkbox" checked={s.annotations} onChange={actions.toggleAnnotations} />{t("Show annotations")}</label>
            <ol className="ex-steps">
              {sc.steps.map((st, i) => (
                <li key={st.label} className={i < s.step ? "done" : i === s.step ? "next" : ""}>
                  <span className="tnum">{i < s.step ? "✓" : i + 1}</span>{st.label}
                </li>
              ))}
            </ol>
            <div>
              <span className="ex-label">Preview state</span>
              <div className="ex-seg">
                <button className={mode === "Live" && !denied ? "active" : ""} onClick={() => (setMode("Live"), setDenied(false), history.replaceState(null, "", " "))}>{t("Live")}</button>
                <button onClick={() => (setMode("Loading"), setTimeout(() => setMode("Live"), 1200))}>{t("Loading")}</button>
                <button className={stale ? "active" : ""} onClick={() => setMode("Stale")}>Stale</button>
                <button className={mode === "Empty" ? "active" : ""} onClick={() => setMode("Empty")}>{t("Empty")}</button>
                <button className={mode === "Error" ? "active" : ""} onClick={() => setMode("Error")}>{t("Error")}</button>
                <button className={denied ? "active" : ""} onClick={() => (location.hash = "#/tasks")}>{t("Permission denied")}</button>
              </div>
            </div>
            <div>
              <span className="ex-label">Network</span>
              <div className="ex-seg">
                <button className={s.online ? "active" : ""} onClick={() => actions.setOnline(true)}>{t("Online")}</button>
                <button className={!s.online ? "active" : ""} onClick={() => actions.setOnline(false)}>{t("Offline")}</button>
              </div>
            </div>
            <label className="ex-toggle"><input type="checkbox" checked={exportFail} onChange={(e) => setExportFail(e.target.checked)} />Simulate export failure</label>
            <div>
              <span className="ex-label">Prototype flows</span>
              <ol className="ex-flows">
                {([
                  ["1 · Morning briefing", "Open the Excellence Center, read the strip and the twin", () => (setPresenter(false), setMode("Live"), focus(undefined))],
                  ["2 · Investigate a risk", "Jump to TC-05 on the twin and open the inspector", () => (setPresenter(false), setMode("Live"), focus("TC-05"))],
                  ["3 · Quality follow-up", "Quality → failed inspection → rework detail", () => (setPresenter(false), setMode("Live"), open("Quality", "inspection", "INSP-213"))],
                  ["4 · Issue review", "Issues register → ISS-311 leak detail", () => (setPresenter(false), setMode("Live"), open("Issues", "issue", "ISS-311"))],
                  ["5 · Brief the board", "Reports → tasks ledger → export", () => (setPresenter(false), setMode("Live"), open("Reports", "ledger", "tasks"))],
                  ["6 · Export offline", "Go offline, then try to export", () => (setPresenter(false), setMode("Live"), actions.setOnline(false), open("Reports", "export"))],
                  ["7 · Arabic walkthrough", "Switch to Arabic RTL on the Reports page", () => (setPresenter(false), setMode("Live"), setLanguage("ar"), go("Reports"))],
                  ["8 · Present on a screen", "Full-screen presentation mode", () => (setPresenter(false), setMode("Live"), go("Excellence Center"), setPresenting(true))],
                ] as [string, string, () => void][]).map(([n, d, fn]) => (
                  <li key={n}><button onClick={fn}><b>{n}</b><small>{d}</small></button></li>
                ))}
              </ol>
            </div>
          </div>
        </Drawer>

        <Dialog title="Reset demo data?" open={confirmReset} close={() => setConfirmReset(false)}
          actions={<>
            <button className="ex-btn secondary" onClick={() => setConfirmReset(false)}>{t("Cancel")}</button>
            <button className="ex-btn danger" onClick={() => (actions.reset(), setConfirmReset(false))}>{t("Reset")}</button>
          </>}>
          <p className="ex-muted ex-pad">{t("All simulated activity will return to the starting state.")}</p>
        </Dialog>
      </div>
    </T.Provider>
  )
}
