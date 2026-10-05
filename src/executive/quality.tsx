import { useEffect, useMemo, useState } from "react"
import type { Lang } from "./i18n"
import { PASS_SERIES, PASS_TARGET, RANGES, failTotal, failedInspections, inspTotal, passRate, reasons, zoneQuality, type Inspection, type Range } from "./data"
import { CardHead, Chips, Empty, HBars, KpiStrip, Legend, LineChart } from "./kit"
import { Code, TypeIcon, useT } from "./status"
import type { State } from "./store"
import { Drawer, Svg, Tertiary, ic } from "./ui"

export type Intent = { kind: string; id?: string; n: number }
export type PageProps = { s: State; lang: Lang; notes: boolean; focus: (facility: string) => void; intent?: Intent }

export const whenText = (ms: number, lang: Lang, daysAgo: number) =>
  daysAgo === 0
    ? new Date(ms).toLocaleTimeString(lang === "ar" ? "ar-SA-u-nu-latn" : "en-GB", { hour: "2-digit", minute: "2-digit", timeZone: "Asia/Riyadh" })
    : new Date(ms).toLocaleDateString(lang === "ar" ? "ar-SA-u-nu-latn" : "en-GB", { weekday: "short", day: "numeric", month: "short", timeZone: "Asia/Riyadh" })

export const ReworkPill = ({ v }: { v: Inspection["rework"] }) => {
  const t = useT()
  return <span className={`ex-pill ${v === "Rework done" ? "ok" : "warn"}`}>{t(v)}</span>
}

export default function QualityPage({ s, lang, notes, focus, intent }: PageProps) {
  const t = useT()
  const [range, setRange] = useState<Range>("Today")
  const [filter, setFilter] = useState<"All" | "Rework open" | "Rework done">("All")
  const [open, setOpen] = useState<string>()
  const rows = useMemo(() => failedInspections(s, range), [s, range])
  const shown = rows.filter((r) => filter === "All" || r.rework === filter)
  const sel = failedInspections(s, "30 days").find((r) => r.id === open)
  const pass = passRate(s, range)
  const gap = Math.round((pass - PASS_TARGET) * 10) / 10
  const series = PASS_SERIES[range]
  const live = range === "Today" ? [...series.v.slice(0, -1), Math.round(pass)] : series.v
  const zones = zoneQuality(s, range)
  const fails = failTotal(s, range)

  useEffect(() => {
    if (intent?.kind === "inspection") setOpen(intent.id ?? rows[0]?.id)
  }, [intent?.n])

  const kpis = [
    { label: "Inspection pass rate", value: `${pass}%`, accent: true, ctx: <span className={gap >= 0 ? "ok" : "warn"}>{Math.abs(gap)} {t("pt")} {t(gap >= 0 ? "above" : "below")} {t("target")} {PASS_TARGET}%</span> },
    { label: "Failed inspections", value: fails, ctx: `${t("of")} ${inspTotal(s, range)} ${t("inspected")}`, onClick: () => document.getElementById("ex-ledger")?.scrollIntoView({ behavior: "smooth", block: "start" }) },
    { label: "Rework open", value: s.rework, ctx: s.rework ? t("Awaiting corrective work") : t("All rework closed") },
    { label: "Avg rework time", value: <>{range === "Today" ? 26 : 28}<span className="ex-of"> {t("min")}</span></>, ctx: `${t("Target")} 30 ${t("min")}` },
    { label: "Weakest zone", value: <span className="ex-val-sm">{t(zones[0].zone)}</span>, ctx: `${zones[0].pass}% ${t("pass rate")}` },
  ]

  return (
    <div className="ex-grid">
      <div className="ex-span12">
        <div className="ex-page-tools">
          <Chips value={range} options={RANGES} onChange={setRange} label="Period" />
          <span className="ex-muted">{t("Illustrative demo data")} · {t("Club time · Asia/Riyadh")}</span>
        </div>
      </div>
      <div className="ex-span12"><KpiStrip items={kpis} label="Quality summary" /></div>

      <div className="ex-span8">
        <section className="ex-card">
          <CardHead eyebrow={range === "Today" ? "Today · 06:00—now" : range === "7 days" ? "Last 7 days" : "Last 30 days"} title="Inspection pass rate" note={{ n: 1, show: notes, text: "Pass rate = passed ÷ total inspections" }}>
            <Legend items={[{ label: "Pass rate" }, { label: "Previous period", cls: "prev" }]} />
          </CardHead>
          <LineChart
            x={series.x} lo={84} hi={100} grid={[96, 92, 88]} target={PASS_TARGET}
            lines={[{ name: t("Pass rate"), data: live, cls: "sla" }, { name: t("Previous period"), data: series.prev, cls: "prev" }]}
            aria={`${t("Inspection pass rate")} ${pass}%, ${t("target")} ${PASS_TARGET}%`}
          />
        </section>
      </div>
      <div className="ex-span4">
        <section className="ex-card">
          <CardHead title="Top failure reasons" eyebrow="Failed inspections" />
          <HBars rows={reasons(s, range).map(([label, value]) => ({ label, value }))} />
        </section>
      </div>

      <div className="ex-span4">
        <section className="ex-card">
          <CardHead title="Quality by zone" eyebrow="Pass rate · lowest first" note={{ n: 2, show: notes, text: "Zones below target are highlighted" }} />
          <HBars
            max={100}
            unit="%"
            rows={zones.map((z) => ({ label: z.zone, value: z.pass, hint: `${z.fails} ${t("failed")} · ${z.insp} ${t("inspected")}`, tone: z.pass < PASS_TARGET ? "warn" : "ok" }))}
          />
          <p className="ex-foot">{t("Bars in yellow are below the pass-rate target.")}</p>
        </section>
      </div>

      <div className="ex-span8" id="ex-ledger">
        <section className="ex-card">
          <CardHead title="Failed inspections & rework" eyebrow="Read-only ledger" note={{ n: 3, show: notes, text: "Original task stays in history; rework is linked" }}>
            <Chips value={filter} options={["All", "Rework open", "Rework done"] as const} onChange={setFilter} label="Rework" />
          </CardHead>
          {shown.length === 0 ? (
            <Empty title="No failed inspections" body="Nothing matches this filter for the selected period." action={<Tertiary onClick={() => setFilter("All")}>{t("Clear filter")}</Tertiary>} />
          ) : (
            <div className="ex-table-wrap">
              <table className="ex-table ex-table-rows">
                <thead>
                  <tr>{["Inspection", "Facility", "Zone", "Reason", "Inspector", "Time", "Rework"].map((h) => <th key={h} scope="col">{t(h)}</th>)}</tr>
                </thead>
                <tbody>
                  {shown.map((r) => (
                    <tr key={r.id} tabIndex={0} onClick={() => setOpen(r.id)} onKeyDown={(e) => e.key === "Enter" && setOpen(r.id)}>
                      <td><Code>{r.id}</Code></td>
                      <td><span className="ex-fac"><TypeIcon type={r.type} /><Code>{r.facility}</Code></span></td>
                      <td>{t(r.zone)}</td>
                      <td>{t(r.reason)}</td>
                      <td>{r.inspector}</td>
                      <td className="tnum">{whenText(r.at, lang, r.daysAgo)}</td>
                      <td><ReworkPill v={r.rework} /></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          <p className="ex-foot">{t("Showing")} {shown.length} {t("of")} {fails} {t("failed")} · {t("Older entries are available in the exported report.")}</p>
        </section>
      </div>

      <Drawer title={sel ? sel.reason : "Inspection"} code={sel ? `${sel.id} · ${t("Read-only")}` : undefined} open={!!sel} close={() => setOpen(undefined)} width={480}
        footer={sel && <Tertiary onClick={() => (setOpen(undefined), focus(sel.facility))}>{t("Show on Digital Twin")} <Svg d={ic.arrow} size={12} /></Tertiary>}>
        {sel && (
          <>
            <dl className="ex-ledger-dl">
              <dt>{t("Facility")}</dt><dd><span className="ex-fac"><TypeIcon type={sel.type} /><Code>{sel.facility}</Code></span> · {t(sel.zone)}</dd>
              <dt>{t("Result")}</dt><dd>{t("Failed")}</dd>
              <dt>{t("Inspector")}</dt><dd>{sel.inspector}</dd>
              <dt>{t("Time")}</dt><dd className="tnum">{whenText(sel.at, lang, sel.daysAgo)}</dd>
              <dt>{t("Rework")}</dt><dd><ReworkPill v={sel.rework} /></dd>
              <dt>{t("Linked task")}</dt><dd><Code>{sel.task}</Code></dd>
            </dl>
            <p className="ex-eyebrow">{t("History")}</p>
            <ol className="ex-timeline">
              <li>{t("Original cleaning task completed")}</li>
              <li>{t("Inspection failed")} · {t(sel.reason)}</li>
              <li>{t("Rework task created and linked")} · <Code>{sel.task}</Code></li>
              {sel.rework === "Rework done" && <li>{t("Corrective work completed · facility Ready")}</li>}
            </ol>
            <p className="ex-note">{t("The original task stays in history. Rework is a linked task, not a reopened one.")}</p>
          </>
        )}
      </Drawer>
    </div>
  )
}
