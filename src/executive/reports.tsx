import { useEffect, useRef, useState } from "react"
import { DAILY, PASS_TARGET, RANGES, failedInspections, failTotal, inspTotal, passRate, registerRows, seriesFor, taskRows, ageText, type Range } from "./data"
import { CardHead, Chips, Empty, Spark } from "./kit"
import { CLUB, type M } from "./metrics"
import type { PageProps } from "./quality"
import { whenText } from "./quality"
import { Code, useT } from "./status"
import { actions, displayStatus, type State } from "./store"
import { Drawer, Svg, Tertiary, ic } from "./ui"

type Key = "daily" | "tasks" | "inspections" | "readiness" | "issues"
type Ledger = { head: string[]; rows: string[][]; title: string }

const WEEKLY = [
  ["W1 · 7–13 Sep", "91", "93", "89", "90", "812"], ["W2 · 14–20 Sep", "92", "94", "90", "92", "840"], ["W3 · 21–27 Sep", "93", "95", "91", "93", "868"],
  ["W4 · 28 Sep–4 Oct", "94", "96", "92", "94", "907"], ["W5 · 5–11 Oct", "94", "96", "92", "94", "— (in progress)"],
]

export function ledger(key: Key, s: State, range: Range, lang: PageProps["lang"]): Ledger {
  if (key === "daily")
    return {
      title: "Daily scorecard",
      head: ["Day", "SLA %", "Response %", "Completion %", "Pass rate %", "Tasks"],
      rows: range === "30 days" ? WEEKLY : DAILY.map((d) => [d.day, d.sla, d.response, d.completion, d.pass, d.tasks].map(String)),
    }
  if (key === "tasks")
    return { title: "Tasks ledger", head: ["Task", "Facility", "Zone", "Type", "Owner", "Response", "Completion", "SLA", "Status"], rows: taskRows(s).map((r) => [r.id, r.facility, r.zone, r.type, r.owner, r.response, r.completion, r.sla, r.status]) }
  if (key === "inspections")
    return { title: "Failed inspections", head: ["Inspection", "Facility", "Zone", "Reason", "Inspector", "Time", "Rework"], rows: failedInspections(s, range).map((r) => [r.id, r.facility, r.zone, r.reason, r.inspector, whenText(r.at, lang, r.daysAgo), r.rework]) }
  if (key === "readiness")
    return {
      title: "Facilities not Ready",
      head: ["Facility", "Type", "Zone", "Level", "Status", "Device"],
      rows: s.facilities.filter((f) => displayStatus(f) !== "Ready").map((f) => [f.id, f.type, f.zone, f.level, displayStatus(f), f.device]),
    }
  return {
    title: "Open issues",
    head: ["Issue", "Title", "Facility", "Severity", "Owner", "Status", "Age"],
    rows: registerRows(s).filter((r) => !r.closed).map((r) => [r.id, r.title, r.facility, r.severity, r.owner, r.status, ageText(s.now - r.openedAt)]),
  }
}

const tone = (v: string) =>
  /^(Breached|Out of Service|Offline|High)$/.test(v) ? "bad" : /^(Approaching|Service Required|Rework open|Delayed|Status unknown|Medium)$/.test(v) ? "warn" : /^(Within Target|Completed|Ready|Online|Rework done)$/.test(v) ? "ok" : ""

function LedgerTable({ data, lang: _l, focus }: { data: Ledger; lang: PageProps["lang"]; focus?: (f: string) => void }) {
  const t = useT()
  if (!data.rows.length) return <Empty title="Nothing to list" body="Every monitored facility is Ready and online." />
  return (
    <div className="ex-table-wrap">
      <table className="ex-table">
        <thead><tr>{data.head.map((h) => <th key={h} scope="col">{t(h)}</th>)}</tr></thead>
        <tbody>
          {data.rows.map((r) => (
            <tr key={r.join("|")}>
              {r.map((c, i) =>
                /^[A-Z]{2,4}-\d{2,4}$/.test(c) ? (
                  <td key={i}>{focus && /^[A-Z]{2}-\d{2}$/.test(c) ? <button className="ex-link" onClick={() => focus(c)}><Code>{c}</Code></button> : <Code>{c}</Code>}</td>
                ) : (
                  <td key={i} className={`${tone(c)} ${/^[\d.—%\s()a-z–]+$/i.test(c) && /\d/.test(c) ? "tnum" : ""}`}>{t(c)}</td>
                ),
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

/* ---------- export files ---------- */
const ascii = (x: string) => x.normalize("NFKD").replace(/[^\x20-\x7e]/g, "").replace(/[()\\]/g, (c) => `\\${c}`)
function miniPdf(lines: string[]) {
  const pages: string[][] = []
  for (let i = 0; i < lines.length; i += 48) pages.push(lines.slice(i, i + 48))
  const objs: string[] = ["<</Type/Catalog/Pages 2 0 R>>", `<</Type/Pages/Kids[${pages.map((_, i) => `${4 + i * 2} 0 R`).join(" ")}]/Count ${pages.length}>>`, "<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>"]
  pages.forEach((p, i) => {
    const c = `BT /F1 10 Tf 48 800 Td 15 TL ${p.map((l) => `(${ascii(l)}) '`).join(" ")} ET`
    objs.push(`<</Type/Page/Parent 2 0 R/MediaBox[0 0 595 842]/Contents ${5 + i * 2} 0 R/Resources<</Font<</F1 3 0 R>>>>>>`, `<</Length ${c.length}>>\nstream\n${c}\nendstream`)
  })
  let out = "%PDF-1.4\n"
  const off: number[] = []
  objs.forEach((o, i) => ((off[i] = out.length), (out += `${i + 1} 0 obj\n${o}\nendobj\n`)))
  const x = out.length
  out += `xref\n0 ${objs.length + 1}\n0000000000 65535 f \n${off.map((o) => `${String(o).padStart(10, "0")} 00000 n \n`).join("")}trailer\n<</Size ${objs.length + 1}/Root 1 0 R>>\nstartxref\n${x}\n%%EOF`
  return new Blob([out], { type: "application/pdf" })
}
const SECTION_KEYS: { key: Key; label: string }[] = [
  { key: "daily", label: "Headline scorecard" }, { key: "tasks", label: "Service speed · tasks" }, { key: "inspections", label: "Service quality · inspections" },
  { key: "readiness", label: "Readiness & devices" }, { key: "issues", label: "Issues & risks" },
]
export const FILE = "OPTIMO-Performance-Briefing-2026-09-27_2026-10-03"
function download(fmt: "PDF" | "CSV", keys: Key[], s: State, range: Range, lang: PageProps["lang"]) {
  const parts = keys.map((k) => ledger(k, s, range, lang))
  let blob: Blob
  if (fmt === "CSV") blob = new Blob(["﻿" + parts.map((p) => [`# ${p.title}`, p.head.join(","), ...p.rows.map((r) => r.map((c) => `"${c.replace(/"/g, '""')}"`).join(","))].join("\n")).join("\n\n")], { type: "text/csv;charset=utf-8" })
  else blob = miniPdf(["OPTIMO - Performance Briefing", "Main Club - 27 Sep to 3 Oct 2026 - Illustrative demo data", "", ...parts.flatMap((p) => [p.title.toUpperCase(), ...p.rows.map((r) => r.join("  |  ")), ""])])
  const a = document.createElement("a")
  a.href = URL.createObjectURL(blob)
  a.download = `${FILE}.${fmt.toLowerCase()}`
  a.click()
  setTimeout(() => URL.revokeObjectURL(a.href), 2000)
}

type Phase = "idle" | "generating" | "ready" | "failed"
function ExportDrawer({ open, close, preset, s, range, lang, online, fail }: { open: boolean; close: () => void; preset?: Key; s: State; range: Range; lang: PageProps["lang"]; online: boolean; fail: boolean }) {
  const t = useT()
  const [fmt, setFmt] = useState<"PDF" | "CSV">("PDF")
  const [keys, setKeys] = useState<Key[]>(SECTION_KEYS.map((x) => x.key))
  const [phase, setPhase] = useState<Phase>("idle")
  const [pct, setPct] = useState(0)
  const timer = useRef<ReturnType<typeof setInterval> | undefined>(undefined)
  useEffect(() => {
    if (!open) return
    setPhase("idle"); setPct(0)
    if (preset) setKeys([preset])
    else setKeys(SECTION_KEYS.map((x) => x.key))
    setFmt(preset ? "CSV" : "PDF")
    return () => clearInterval(timer.current)
  }, [open, preset])
  const run = () => {
    setPhase("generating"); setPct(0)
    let p = 0
    clearInterval(timer.current)
    timer.current = setInterval(() => {
      p += 9 + Math.random() * 6
      if (fail && p > 62) { clearInterval(timer.current); return setPhase("failed") }
      if (p >= 100) {
        clearInterval(timer.current); setPct(100); setPhase("ready")
        actions.addNotice("Report ready", `Performance Briefing · ${fmt}`, "Exports")
      } else setPct(p)
    }, 260)
  }
  const toggle = (k: Key) => setKeys((c) => (c.includes(k) ? c.filter((x) => x !== k) : [...c, k]))
  const busy = phase === "generating"
  return (
    <Drawer title="Export report" code={`${t("Performance Briefing")} · ${t(range)}`} open={open} close={close} width={440}
      footer={
        phase === "ready" ? (
          <>
            <button className="ex-btn secondary" onClick={() => setPhase("idle")}>{t("Export another")}</button>
            <button className="ex-btn primary" onClick={() => download(fmt, keys, s, range, lang)}><Svg d={ic.down} size={14} />{t(fmt === "PDF" ? "Download PDF" : "Download CSV")}</button>
          </>
        ) : (
          <>
            <button className="ex-btn secondary" onClick={close}>{t("Cancel")}</button>
            <button className="ex-btn primary" disabled={!online || busy || keys.length === 0} onClick={run}>
              {busy ? <><i className="ex-spin" />{t("Generating")} {Math.round(pct)}%</> : !online ? t("Reconnect to export") : phase === "failed" ? t("Retry") : t("Generate")}
            </button>
          </>
        )
      }>
      {!online && <p className="ex-banner warn" role="status"><Svg d={ic.wifiOff} size={14} />{t("You're offline. Actions are queued and will sync when you reconnect.")}</p>}
      {phase === "failed" && <p className="ex-banner bad" role="alert"><Svg d={ic.issues} size={14} />{t("Export failed. Try again.")}</p>}
      {phase === "ready" ? (
        <div className="ex-export-ready">
          <span className="ex-check"><Svg d={ic.check} size={20} /></span>
          <strong>{t("Report ready")}</strong>
          <p className="ex-muted"><bdi dir="ltr">{FILE}.{fmt.toLowerCase()}</bdi></p>
          <small className="ex-muted">{keys.length} {t("sections")} · {fmt === "PDF" ? "1.2 MB" : "48 KB"}</small>
        </div>
      ) : (
        <div className="ex-form">
          <div>
            <span className="ex-label">{t("Format")}</span>
            <div className="ex-seg" role="radiogroup">
              {(["PDF", "CSV"] as const).map((f) => <button key={f} role="radio" aria-checked={fmt === f} className={fmt === f ? "active" : ""} disabled={busy} onClick={() => setFmt(f)}>{f}</button>)}
            </div>
          </div>
          <fieldset className="ex-fieldset" disabled={busy}>
            <legend className="ex-label">{t("Sections")}</legend>
            {SECTION_KEYS.map((x) => (
              <label key={x.key} className="ex-check-row"><input type="checkbox" checked={keys.includes(x.key)} onChange={() => toggle(x.key)} />{t(x.label)}</label>
            ))}
          </fieldset>
          {keys.length === 0 && <small className="ex-why">{t("Select at least one section.")}</small>}
          {busy && <div className="ex-progress" role="progressbar" aria-valuenow={Math.round(pct)} aria-valuemin={0} aria-valuemax={100}><i style={{ inlineSize: `${pct}%` }} /></div>}
          <small className="ex-muted">{t("Illustrative demo data")} · {t("Club time · Asia/Riyadh")}</small>
        </div>
      )}
    </Drawer>
  )
}

/* ---------- page ---------- */
export type ReportsProps = PageProps & { m: M; online: boolean; exportFail: boolean }
export default function ReportsPage({ s, lang, notes, focus, intent, m, online, exportFail }: ReportsProps) {
  const t = useT()
  const ar = lang === "ar"
  const [range, setRange] = useState<Range>("7 days")
  const [drill, setDrill] = useState<Key>()
  const [exp, setExp] = useState(false)
  const [preset, setPreset] = useState<Key>()
  const pass = passRate(s, range)
  const fails = failTotal(s, range)
  const tasks = taskRows(s)
  const open = registerRows(s).filter((r) => !r.closed)
  const high = open.filter((r) => r.severity === "High").length
  const notReady = CLUB.total - m.ready
  const gap = m.sla - 95

  useEffect(() => {
    if (intent?.kind === "ledger") setDrill((intent.id as Key) ?? "tasks")
    if (intent?.kind === "export") { setPreset(undefined); setExp(true) }
  }, [intent?.n])

  const sections: { key: Key; n: string; title: string; story: string; figs: [string, string, string?][]; spark: number[]; lo?: number; hi?: number }[] = [
    {
      key: "daily", n: "01", title: "Headline",
      story: ar
        ? `حافظ النادي على التزام ${m.sla}% باتفاقية الخدمة مقابل هدف 95%${gap >= 0 ? "" : ` بفارق ${Math.abs(gap)} نقطة`}. ${m.overdue.length} مهمة متأخرة و${open.length} مشكلات مفتوحة، منها ${high} عالية الأولوية.`
        : `Service held at ${m.sla}% SLA compliance against a 95% target${gap >= 0 ? "" : `, ${Math.abs(gap)} ${Math.abs(gap) === 1 ? "point" : "points"} short`}. ${m.overdue.length} ${m.overdue.length === 1 ? "task is" : "tasks are"} overdue and ${open.length} ${open.length === 1 ? "issue is" : "issues are"} open, ${high} of them high priority.`,
      figs: [["SLA compliance", `${m.sla}%`], ["Inspection pass rate", `${pass}%`], ["Facilities Ready", `${m.ready}/${CLUB.total}`]],
      spark: seriesFor.sla, lo: 88, hi: 98,
    },
    {
      key: "tasks", n: "02", title: "Service speed",
      story: ar
        ? `متوسط زمن الاستجابة 2 د 40 ث ومتوسط الإنجاز 14 د. التزام الاستجابة ${m.response}% والإنجاز ${m.completion}%، وأبطأ المهام في غرف التبديل.`
        : `Median response was 2m 40s and median completion 14m. Response SLA sits at ${m.response}% and Completion SLA at ${m.completion}%; the slowest tasks were in Changing Rooms.`,
      figs: [["Response SLA", `${m.response}%`], ["Completion SLA", `${m.completion}%`], ["Tasks tracked", String(tasks.length + 850)]],
      spark: seriesFor.response, lo: 90, hi: 99,
    },
    {
      key: "inspections", n: "03", title: "Service quality",
      story: ar
        ? `أُجريت ${inspTotal(s, range)} عملية فحص وأخفقت ${fails} منها، أي نسبة نجاح ${pass}%. توجد ${s.rework} حالات إعادة عمل مفتوحة، ومعظم الإخفاقات في الدشات.`
        : `${inspTotal(s, range)} inspections ran and ${fails} failed, a ${pass}% pass rate against the ${PASS_TARGET}% target. ${s.rework} rework ${s.rework === 1 ? "task remains" : "tasks remain"} open; most failures were in Showers.`,
      figs: [["Pass rate", `${pass}%`], ["Failed", String(fails)], ["Rework open", String(s.rework)]],
      spark: seriesFor.pass, lo: 88, hi: 98,
    },
    {
      key: "readiness", n: "04", title: "Readiness & devices",
      story: ar
        ? `${m.ready} من ${CLUB.total} مرفقاً جاهزة الآن و${m.online} جهازاً متصلاً. ${notReady} مرافق لا تُحتسب جاهزة${m.offline ? " بسبب أجهزة غير متصلة" : ""}.`
        : `${m.ready} of ${CLUB.total} facilities are Ready now and ${m.online} devices are online. ${notReady} ${notReady === 1 ? "facility is" : "facilities are"} not counted as Ready${m.offline ? ", including offline devices" : ""}.`,
      figs: [["Ready now", `${m.ready}/${CLUB.total}`], ["Devices online", `${m.online}/${CLUB.total}`], ["Awaiting service", String(m.awaiting)]],
      spark: seriesFor.ready, lo: 38, hi: 43,
    },
    {
      key: "issues", n: "05", title: "Issues & risks",
      story: ar
        ? `${open.length} مشكلات مفتوحة، ${high} منها عالية. تتركز المشكلات في منطقة الدشات، وتتابعها إدارة الإشراف.`
        : `${open.length} ${open.length === 1 ? "issue is" : "issues are"} open, ${high} high severity. Issues cluster in the Showers zone and are being handled by Supervisors.`,
      figs: [["Open issues", String(open.length)], ["High severity", String(high)], ["Resolved this week", "14"]],
      spark: [4, 5, 3, 4, 6, 4, open.length],
    },
  ]
  const data = drill ? ledger(drill, s, range, lang) : undefined
  const recent = s.notices.filter((n) => n.group === "Exports")

  return (
    <div className="ex-grid">
      <div className="ex-span12">
        <div className="ex-page-tools">
          <Chips value={range} options={RANGES.filter((r) => r !== "Today")} onChange={setRange} label="Period" />
          <span className="ex-muted">{range === "7 days" ? "27 Sep – 3 Oct 2026" : "7 Sep – 4 Oct 2026"} · {t("Illustrative demo data")}</span>
          <button className="ex-btn primary ex-end" onClick={() => (setPreset(undefined), setExp(true))}><Svg d={ic.down} size={14} />{t("Export report")}</button>
        </div>
      </div>

      <div className="ex-span8 ex-stack">
        {sections.map((x, i) => (
          <section key={x.key} className="ex-card ex-brief">
            <CardHead eyebrow={`${x.n} · ${t("Briefing")}`} title={x.title} note={i === 0 ? { n: 1, show: notes, text: "Narrative is generated from live store values" } : i === 2 ? { n: 2, show: notes, text: "Numbers match Quality Overview" } : undefined}>
              <Tertiary onClick={() => setDrill(x.key)}>{t("Open ledger")} <Svg d={ic.arrow} size={12} /></Tertiary>
            </CardHead>
            <p className="ex-story">{x.story}</p>
            <div className="ex-figs">
              {x.figs.map(([l, v], j) => (
                <div key={l}>
                  <small>{t(l)}</small>
                  <strong className="tnum">{v}</strong>
                  {j === 0 && <Spark data={x.spark} lo={x.lo} hi={x.hi} />}
                </div>
              ))}
            </div>
          </section>
        ))}
      </div>

      <div className="ex-span4 ex-stack">
        <section className="ex-card">
          <CardHead title="Export" eyebrow="Share with leadership" note={{ n: 3, show: notes, text: "Export is the only write-like action, and it is offline-aware" }} />
          <p className="ex-muted">{t("Generate a PDF or CSV of this briefing. Files are created from the data shown on this page.")}</p>
          <button className="ex-btn secondary" onClick={() => (setPreset(undefined), setExp(true))}><Svg d={ic.doc} size={14} />{t("Export report")}</button>
          {!online && <small className="ex-why"><Svg d={ic.wifiOff} size={12} /> {t("Reconnect to export")}</small>}
        </section>
        <section className="ex-card">
          <CardHead title="Recent exports" eyebrow="Last 7 days" />
          {recent.length === 0 ? <Empty title="No exports yet" body="Generated reports appear here." /> : (
            <ul className="ex-notices">
              {recent.slice(0, 4).map((n) => (
                <li key={n.id}><div><strong>{t(n.title)}</strong><small>{t(n.detail)} · <span className="tnum">{whenText(n.at, lang, 0)}</span></small></div></li>
              ))}
            </ul>
          )}
        </section>
        <section className="ex-card">
          <CardHead title="SLA definitions" eyebrow="How numbers are measured" />
          <ul className="ex-defs">
            {["Response = task creation → acceptance.", "Completion = task creation → completion.", "Cleaning duration = start of cleaning → completion.", "Offline devices count as needs attention (to be confirmed with Operations)."].map((d) => <li key={d}>{t(d)}</li>)}
          </ul>
          <p className="ex-foot">{t("Targets are confirmed with Operations.")}</p>
        </section>
      </div>

      <Drawer title={data ? data.title : "Ledger"} code={`${t("Read-only")} · ${t(range)}`} open={!!data} close={() => setDrill(undefined)} width={720}
        footer={drill && <><Tertiary onClick={() => { setPreset(drill); setDrill(undefined); setExp(true) }}>{t("Export this ledger")}</Tertiary><button className="ex-btn secondary" onClick={() => setDrill(undefined)}>{t("Close")}</button></>}>
        {data && (
          <>
            <p className="ex-muted">{data.rows.length} {t("rows")} · {t("Click a facility code to see it on the Digital Twin.")}</p>
            <LedgerTable data={data} lang={lang} focus={(f) => (setDrill(undefined), focus(f))} />
          </>
        )}
      </Drawer>
      <ExportDrawer open={exp} close={() => setExp(false)} preset={preset} s={s} range={range} lang={lang} online={online} fail={exportFail} />
    </div>
  )
}
