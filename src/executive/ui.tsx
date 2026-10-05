import { useEffect, useRef, useState } from "react"
import type { Lang } from "./i18n"
import { useT } from "./status"

export const reduced = () => typeof window !== "undefined" && window.matchMedia("(prefers-reduced-motion: reduce)").matches
export const clock = (ms: number, lang: Lang) =>
  new Date(ms).toLocaleTimeString(lang === "ar" ? "ar-SA-u-nu-latn" : "en-GB", { hour: "2-digit", minute: "2-digit", timeZone: "Asia/Riyadh" })

/** KPI count-up, 500ms ease-in-out; instant with reduced motion. */
export function useCount(value: number) {
  const [shown, setShown] = useState(0)
  const from = useRef(0)
  useEffect(() => {
    if (reduced()) return setShown(value)
    const a = from.current
    const t0 = performance.now()
    let raf = 0
    const tick = (t: number) => {
      const k = Math.min(1, (t - t0) / 500)
      const e = k < 0.5 ? 2 * k * k : 1 - (-2 * k + 2) ** 2 / 2
      setShown(a + (value - a) * e)
      if (k < 1) raf = requestAnimationFrame(tick)
      else from.current = value
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [value])
  return shown
}

export const Svg = ({ d, size = 16 }: { d: string; size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
    <path d={d} />
  </svg>
)
export const ic = {
  bell: "M4 11V7a4 4 0 0 1 8 0v4l1 1H3zM6.5 13.5a1.5 1.5 0 0 0 3 0",
  close: "M4 4l8 8M12 4l-8 8",
  layers: "M8 2l6 3-6 3-6-3zM2 8l6 3 6-3M2 11l6 3 6-3",
  full: "M2 6V2h4M10 2h4v4M14 10v4h-4M6 14H2v-4",
  exitFull: "M6 2v4H2M14 6h-4V2M10 14v-4h4M2 10h4v4",
  plus: "M8 3v10M3 8h10",
  minus: "M3 8h10",
  reset: "M3 8a5 5 0 1 0 1.5-3.5M3 2v3h3",
  play: "M5 3l8 5-8 5z",
  check: "M3 8l3 3 7-7",
  up: "M8 13V3M4 7l4-4 4 4",
  down: "M8 3v10M4 9l4 4 4-4",
  flat: "M3 8h10",
  grid: "M2 2h5v5H2zM9 2h5v5H9zM2 9h5v5H2zM9 9h5v5H9z",
  quality: "M8 2l5 2v4c0 3-2 5-5 6-3-1-5-3-5-6V4zM5.5 8l2 2 3-3.5",
  issues: "M8 2l6 11H2zM8 6v3M8 11v.5",
  doc: "M4 2h5l3 3v9H4zM9 2v3h3",
  lock: "M4 7h8v7H4zM6 7V5a2 2 0 0 1 4 0v2",
  wifi: "M2 6a9 9 0 0 1 12 0M4.5 8.5a5 5 0 0 1 7 0M7 11a1.5 1.5 0 0 1 2 0",
  wifiOff: "M2 6a9 9 0 0 1 4-2.2M10 3.8A9 9 0 0 1 14 6M7 11a1.5 1.5 0 0 1 2 0M2 2l12 12",
  arrow: "M3 8h10M9 4l4 4-4 4",
  present: "M2 3h12v8H2zM8 11v3M5 14h6",
}

export function IconBtn({ label, d, onClick, active, badge }: { label: string; d: string; onClick: () => void; active?: boolean; badge?: number }) {
  return (
    <button className={`ex-icon ${active ? "active" : ""}`} aria-label={label} title={label} onClick={onClick}>
      <Svg d={d} />
      {!!badge && <span className="ex-badge tnum">{badge}</span>}
    </button>
  )
}
export const Tertiary = ({ children, onClick }: { children: React.ReactNode; onClick: () => void }) => (
  <button className="ex-tertiary" onClick={onClick}>{children}</button>
)

export function Select({ label, value, options, onChange, icon }: { label?: string; value: string; options: string[]; onChange: (v: string) => void; icon?: string }) {
  const t = useT()
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => {
    const off = (e: MouseEvent) => !ref.current?.contains(e.target as Node) && setOpen(false)
    document.addEventListener("mousedown", off)
    return () => document.removeEventListener("mousedown", off)
  }, [])
  return (
    <div className="ex-select" ref={ref} onKeyDown={(e) => e.key === "Escape" && setOpen(false)}>
      <button className={`ex-select-btn ${open ? "open" : ""}`} aria-expanded={open} aria-haspopup="listbox" onClick={() => setOpen(!open)}>
        {icon && <Svg d={icon} size={14} />}
        <span>{label && <small>{t(label)}</small>}{t(value)}</span>
        <Svg d="M4 6l4 4 4-4" size={12} />
      </button>
      {open && (
        <div className="ex-pop" role="listbox">
          {options.map((o) => (
            <button key={o} role="option" aria-selected={o === value} className={o === value ? "selected" : ""} onClick={() => (onChange(o), setOpen(false))}>
              {t(o)}
              {o === value && <Svg d={ic.check} size={12} />}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

export function useTrap(open: boolean, close: () => void) {
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => {
    if (!open) return
    const prev = document.activeElement as HTMLElement | null
    const el = ref.current
    el?.querySelector<HTMLElement>("button, input, select")?.focus()
    const key = (e: KeyboardEvent) => {
      if (e.key === "Escape") close()
      if (e.key !== "Tab" || !el) return
      const f = [...el.querySelectorAll<HTMLElement>("button:not(:disabled), input, select")]
      if (!f.length) return
      if (e.shiftKey && document.activeElement === f[0]) (e.preventDefault(), f[f.length - 1].focus())
      else if (!e.shiftKey && document.activeElement === f[f.length - 1]) (e.preventDefault(), f[0].focus())
    }
    document.addEventListener("keydown", key)
    return () => (document.removeEventListener("keydown", key), prev?.focus())
  }, [open])
  return ref
}

export function Drawer({ title, code, open, close, children, footer, width = 480 }: { title: string; code?: string; open: boolean; close: () => void; children: React.ReactNode; footer?: React.ReactNode; width?: number }) {
  const t = useT()
  const ref = useTrap(open, close)
  if (!open) return null
  return (
    <div className="ex-backdrop" onMouseDown={(e) => e.target === e.currentTarget && close()}>
      <div className="ex-drawer" role="dialog" aria-modal="true" aria-label={t(title)} ref={ref} style={{ inlineSize: width }}>
        <header>
          <div>
            {code && <small className="ex-eyebrow">{code}</small>}
            <h2>{t(title)}</h2>
          </div>
          <IconBtn label={t("Close")} d={ic.close} onClick={close} />
        </header>
        <div className="ex-drawer-body">{children}</div>
        {footer && <footer>{footer}</footer>}
      </div>
    </div>
  )
}

export function Dialog({ title, open, close, children, actions: act }: { title: string; open: boolean; close: () => void; children: React.ReactNode; actions: React.ReactNode }) {
  const t = useT()
  const ref = useTrap(open, close)
  if (!open) return null
  return (
    <div className="ex-backdrop center" onMouseDown={(e) => e.target === e.currentTarget && close()}>
      <div className="ex-dialog" role="dialog" aria-modal="true" aria-label={t(title)} ref={ref}>
        <h2>{t(title)}</h2>
        {children}
        <footer>{act}</footer>
      </div>
    </div>
  )
}

export function Delta({ dir, children }: { dir: "up" | "down" | "flat"; children: React.ReactNode }) {
  return (
    <span className={`ex-delta ${dir}`}>
      <Svg d={ic[dir]} size={12} />
      {children}
    </span>
  )
}
