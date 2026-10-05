import { useState } from "react"
import type { MouseEvent as RMouseEvent, ReactNode } from "react"
import { Mark } from "./status"
import { useT } from "./status"
import { Svg, ic } from "./ui"

/* Shared building blocks for the Executive pages. All read-only, token-only. */

export type Kpi = { label: string; value: ReactNode; ctx: ReactNode; accent?: boolean; onClick?: () => void }
export function KpiStrip({ items, label }: { items: Kpi[]; label: string }) {
  const t = useT()
  return (
    <section className="ex-strip ex-strip-n" style={{ ["--n" as string]: items.length }} aria-label={t(label)}>
      {items.map((k) => {
        const inner = (
          <>
            <small>{t(k.label)}</small>
            <strong className="tnum">{k.value}</strong>
            <span className="ex-cell-ctx">{k.ctx}</span>
          </>
        )
        return k.onClick ? (
          <button key={k.label} className={`ex-cell ${k.accent ? "accent" : ""}`} onClick={k.onClick}>{inner}</button>
        ) : (
          <div key={k.label} className={`ex-cell static ${k.accent ? "accent" : ""}`}>{inner}</div>
        )
      })}
    </section>
  )
}

export function CardHead({ eyebrow, title, note, children }: { eyebrow?: string; title: string; note?: { n: number; show: boolean; text: string }; children?: ReactNode }) {
  const t = useT()
  return (
    <div className="ex-card-head">
      <div>
        {eyebrow && <span className="ex-eyebrow">{t(eyebrow)}</span>}
        <h3>{t(title)} {note && <Mark n={note.n} show={note.show} />}</h3>
      </div>
      {children}
    </div>
  )
}

export function Chips<T extends string>({ value, options, onChange, label }: { value: T; options: readonly T[]; onChange: (v: T) => void; label: string }) {
  const t = useT()
  return (
    <div className="ex-chips" role="radiogroup" aria-label={t(label)}>
      {options.map((o) => <button key={o} role="radio" aria-checked={o === value} className={o === value ? "active" : ""} onClick={() => onChange(o)}>{t(o)}</button>)}
    </div>
  )
}

/** Horizontal bars with a label, value and optional target tick. */
export function HBars({ rows, max, unit = "", tone }: { rows: { label: string; value: number; hint?: string; tone?: string }[]; max?: number; unit?: string; tone?: (v: number) => string }) {
  const t = useT()
  const top = max ?? Math.max(1, ...rows.map((r) => r.value))
  return (
    <ul className="ex-hbars">
      {rows.map((r) => (
        <li key={r.label}>
          <span className="l">{t(r.label)}</span>
          <span className="track" role="img" aria-label={`${t(r.label)} ${r.value}${unit}`}>
            <i className={r.tone ?? tone?.(r.value) ?? ""} style={{ inlineSize: `${Math.min(100, (r.value / top) * 100)}%` }} />
          </span>
          <b className="tnum">{r.value}{unit}</b>
          {r.hint && <small>{r.hint}</small>}
        </li>
      ))}
    </ul>
  )
}

export function Columns({ rows }: { rows: [string, number][] }) {
  const t = useT()
  const top = Math.max(1, ...rows.map(([, n]) => n))
  return (
    <div className="ex-cols" role="img" aria-label={rows.map(([l, n]) => `${l}: ${n}`).join(", ")}>
      {rows.map(([l, n]) => (
        <div key={l}>
          <b className="tnum">{n}</b>
          <span className="bar"><i className={n ? "has" : ""} style={{ blockSize: `${Math.max(n ? 12 : 3, (n / top) * 100)}%` }} /></span>
          <small>{t(l)}</small>
        </div>
      ))}
    </div>
  )
}

export function Spark({ data, lo, hi }: { data: number[]; lo?: number; hi?: number }) {
  const a = lo ?? Math.min(...data) - 1, b = hi ?? Math.max(...data) + 1
  const W = 120, H = 32
  const pts = data.map((v, i) => `${i ? "L" : "M"}${(i * W) / (data.length - 1)},${H - ((v - a) / (b - a)) * H}`).join(" ")
  return (
    <svg className="ex-spark" viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" aria-hidden="true">
      <path d={pts} />
    </svg>
  )
}

/** Line chart that shares the Service Performance visual language. */
export type Line = { name: string; data: number[]; cls: "sla" | "pass" | "prev" }
export function LineChart({ x, lines, lo, hi, grid, target, aria, fmt = (v) => `${v}%` }: { x: string[]; lines: Line[]; lo: number; hi: number; grid: number[]; target?: number; aria: string; fmt?: (v: number) => string }) {
  const [hover, setHover] = useState<number>()
  const W = 800, H = 180, last = x.length - 1
  const X = (i: number) => (i * W) / last
  const Y = (v: number) => ((hi - v) / (hi - lo)) * H
  const path = (a: number[]) => a.map((v, i) => `${i ? "L" : "M"}${X(i)},${Y(v)}`).join(" ")
  const pct = (v: number) => `${(Y(v) / H) * 100}%`
  const main = lines[0]
  const onMove = (e: RMouseEvent<HTMLDivElement>) => {
    const r = e.currentTarget.getBoundingClientRect()
    setHover(Math.round(Math.min(1, Math.max(0, (e.clientX - r.left) / r.width)) * last))
  }
  const gid = `g${aria.length}${lo}`
  return (
    <div className="ex-chart" dir="ltr">
      {grid.map((g) => <span key={g} className="ex-y tnum" style={{ top: pct(g) }}>{fmt(g)}</span>)}
      <div className="ex-chart-plot" onMouseMove={onMove} onMouseLeave={() => setHover(undefined)}>
        <svg viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" role="img" aria-label={aria}>
          <defs><linearGradient id={gid} x1="0" x2="0" y1="0" y2="1"><stop offset="0" stopColor="var(--yellow)" stopOpacity=".16" /><stop offset="1" stopColor="var(--yellow)" stopOpacity="0" /></linearGradient></defs>
          {grid.map((g) => <line key={g} x1={0} x2={W} y1={Y(g)} y2={Y(g)} className="grid" />)}
          {target !== undefined && <line x1={0} x2={W} y1={Y(target)} y2={Y(target)} className="target" />}
          <path d={`${path(main.data)} L${W},${H} L0,${H} Z`} fill={`url(#${gid})`} />
          {[...lines].reverse().map((l) => <path key={l.name} d={path(l.data)} className={l.cls} />)}
          {hover !== undefined && <line x1={X(hover)} x2={X(hover)} y1={0} y2={H} className="cursor" />}
        </svg>
        {hover !== undefined && (
          <>
            {lines.filter((l) => l.cls !== "prev").map((l) => <i key={l.name} className={`ex-dot ${l.cls === "pass" ? "pass" : ""}`} style={{ left: `${(hover / last) * 100}%`, top: pct(l.data[hover]) }} />)}
            <div className="ex-chart-tip" style={{ left: `clamp(0px, calc(${(hover / last) * 100}% - 74px), calc(100% - 148px))` }}>
              <b>{x[hover]}</b>
              {lines.map((l) => <span key={l.name}>{l.name} <strong>{fmt(l.data[hover])}</strong></span>)}
              {target !== undefined && <span>Target <strong>{fmt(target)}</strong></span>}
            </div>
          </>
        )}
      </div>
      <div className="ex-chart-labels">{x.map((v) => <span key={v}>{v}</span>)}</div>
    </div>
  )
}

export function Legend({ items }: { items: { label: string; cls?: string }[] }) {
  const t = useT()
  return (
    <div className="ex-legend-inline" aria-hidden="true">
      {items.map((i) => <span key={i.label}><i className={i.cls} />{t(i.label)}</span>)}
    </div>
  )
}

export const Sev = ({ v }: { v: "High" | "Medium" | "Low" }) => {
  const t = useT()
  return <span className={`ex-sev ${v.toLowerCase()}`}><i aria-hidden="true" />{t(v)}</span>
}

export function Toolbar({ children }: { children: ReactNode }) {
  return <div className="ex-toolbar">{children}</div>
}

export function Search({ value, onChange, label }: { value: string; onChange: (v: string) => void; label: string }) {
  const t = useT()
  return (
    <label className="ex-searchbox">
      <Svg d="M7 12.5a5.5 5.5 0 1 1 0-11 5.5 5.5 0 0 1 0 11zM11 11l3.5 3.5" size={14} />
      <input value={value} onChange={(e) => onChange(e.target.value)} placeholder={t(label)} aria-label={t(label)} />
      {value && <button aria-label={t("Clear")} onClick={() => onChange("")}><Svg d={ic.close} size={12} /></button>}
    </label>
  )
}

export const Empty = ({ title, body, action }: { title: string; body: string; action?: ReactNode }) => {
  const t = useT()
  return (
    <div className="ex-empty">
      <Svg d={ic.check} size={20} />
      <strong>{t(title)}</strong>
      <p>{t(body)}</p>
      {action}
    </div>
  )
}
