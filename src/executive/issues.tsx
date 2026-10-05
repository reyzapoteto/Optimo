import { useEffect, useMemo, useState } from "react"
import { ageBuckets, ageText, hotspots, registerRows } from "./data"
import { CardHead, Columns, Empty, HBars, KpiStrip, Search, Sev, Toolbar } from "./kit"
import type { PageProps } from "./quality"
import { Code, useT } from "./status"
import { Drawer, Select, Svg, Tertiary, ic } from "./ui"

const SEV = ["All severities", "High", "Medium", "Low"]
const STATE = ["Open", "Resolved", "All"]

export default function IssuesPage({ s, notes, focus, intent }: PageProps) {
  const t = useT()
  const [sev, setSev] = useState("All severities")
  const [state, setState] = useState("Open")
  const [q, setQ] = useState("")
  const [open, setOpen] = useState<string>()
  const all = registerRows(s)
  const rows = useMemo(
    () =>
      all.filter((r) => (sev === "All severities" || r.severity === sev) && (state === "All" || (state === "Open") === !r.closed) &&
        (!q || `${r.id} ${r.title} ${r.facility} ${r.zone} ${r.owner}`.toLowerCase().includes(q.toLowerCase()))),
    [all, sev, state, q],
  )
  const sel = all.find((r) => r.id === open)
  const openRows = all.filter((r) => !r.closed)
  const high = openRows.filter((r) => r.severity === "High").length
  const oldest = openRows.length ? Math.max(...openRows.map((r) => s.now - r.openedAt)) : 0
  const avg = openRows.length ? openRows.reduce((a, r) => a + (s.now - r.openedAt), 0) / openRows.length : 0
  const sevCount = (v: string) => all.filter((r) => !r.closed && r.severity === v).length

  useEffect(() => {
    if (intent?.kind === "issue") setOpen(intent.id ?? s.issues[0]?.id)
  }, [intent?.n])

  const kpis = [
    { label: "Open issues", value: openRows.length, accent: true, ctx: `${high} ${t("high priority")}` },
    { label: "High severity", value: high, ctx: high ? t("Supervisor engaged") : t("None open") },
    { label: "Average age", value: <span className="ex-val-sm tnum">{ageText(avg)}</span>, ctx: `${t("Oldest")} ${ageText(oldest)}` },
    { label: "Resolved this week", value: all.filter((r) => r.closed).length + 9, ctx: `${t("Median")} 2h 40m ${t("to resolve")}` },
    { label: "Facilities affected", value: new Set(openRows.map((r) => r.facility)).size, ctx: openRows.some((r) => r.impact.toLowerCase().includes("out")) ? t("1 out of service") : t("All in service") },
  ]

  return (
    <div className="ex-grid">
      <div className="ex-span12"><KpiStrip items={kpis} label="Issues summary" /></div>

      <div className="ex-span4">
        <section className="ex-card">
          <CardHead title="Open by severity" eyebrow="Now" note={{ n: 1, show: notes, text: "Severity is set by the Supervisor, read-only here" }} />
          <HBars rows={["High", "Medium", "Low"].map((v) => ({ label: v, value: sevCount(v), tone: v === "High" ? "bad" : v === "Medium" ? "warn" : "none" }))} max={Math.max(3, ...["High", "Medium", "Low"].map(sevCount))} />
        </section>
      </div>
      <div className="ex-span4">
        <section className="ex-card">
          <CardHead title="Aging" eyebrow="Open issues by age" />
          <Columns rows={ageBuckets(s)} />
        </section>
      </div>
      <div className="ex-span4">
        <section className="ex-card">
          <CardHead title="Hotspots" eyebrow="Issues this week by zone" note={{ n: 2, show: notes, text: "Repeated zones suggest a root cause" }} />
          <HBars rows={hotspots(s).slice(0, 5).map(([label, value]) => ({ label, value, tone: value >= 3 ? "warn" : "" }))} />
        </section>
      </div>

      <div className="ex-span12">
        <section className="ex-card">
          <CardHead title="Issue register" eyebrow="Read-only" note={{ n: 3, show: notes, text: "No create, assign or close actions for Executives" }}>
            <Toolbar>
              <Search value={q} onChange={setQ} label="Search issues" />
              <Select value={sev} options={SEV} onChange={setSev} />
              <Select value={state} options={STATE} onChange={setState} />
            </Toolbar>
          </CardHead>
          {rows.length === 0 ? (
            <Empty title="No issues match" body="Try a different severity or clear the search." action={<Tertiary onClick={() => (setSev("All severities"), setState("All"), setQ(""))}>{t("Clear filters")}</Tertiary>} />
          ) : (
            <div className="ex-table-wrap">
              <table className="ex-table ex-table-rows">
                <thead>
                  <tr>{["Issue", "Title", "Facility", "Zone", "Severity", "Owner", "Status", "Age"].map((h) => <th key={h} scope="col">{t(h)}</th>)}</tr>
                </thead>
                <tbody>
                  {rows.map((r) => (
                    <tr key={r.id} tabIndex={0} onClick={() => setOpen(r.id)} onKeyDown={(e) => e.key === "Enter" && setOpen(r.id)}>
                      <td><Code>{r.id}</Code></td>
                      <td className="strong">{t(r.title)}</td>
                      <td><Code>{r.facility}</Code></td>
                      <td>{t(r.zone)}</td>
                      <td><Sev v={r.severity} /></td>
                      <td>{r.owner}</td>
                      <td>{t(r.status)}</td>
                      <td className="tnum">{r.closed ? `${t("Resolved in")} ${r.resolved}` : ageText(s.now - r.openedAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          <p className="ex-foot">{t("Showing")} {rows.length} {t("of")} {all.length} · {t("Issues are created and closed by Supervisors.")}</p>
        </section>
      </div>

      <Drawer title={sel ? sel.title : "Issue"} code={sel ? `${sel.id} · ${t("Read-only")}` : undefined} open={!!sel} close={() => setOpen(undefined)} width={480}
        footer={sel && <Tertiary onClick={() => (setOpen(undefined), focus(sel.facility))}>{t("Show on Digital Twin")} <Svg d={ic.arrow} size={12} /></Tertiary>}>
        {sel && (
          <>
            <dl className="ex-ledger-dl">
              <dt>{t("Severity")}</dt><dd><Sev v={sel.severity} /></dd>
              <dt>{t("Status")}</dt><dd>{t(sel.status)}</dd>
              <dt>{t("Facility")}</dt><dd><Code>{sel.facility}</Code> · {t(sel.zone)}</dd>
              <dt>{t("Category")}</dt><dd>{t(sel.category)}</dd>
              <dt>{t("Handled by")}</dt><dd>{sel.owner}</dd>
              <dt>{t("Impact")}</dt><dd>{t(sel.impact)}</dd>
              {sel.task && <><dt>{t("Linked task")}</dt><dd><Code>{sel.task}</Code></dd></>}
              <dt>{t("Age")}</dt><dd className="tnum">{sel.closed ? `${t("Resolved in")} ${sel.resolved}` : ageText(s.now - sel.openedAt)}</dd>
            </dl>
            <p className="ex-eyebrow">{t("Timeline")}</p>
            <ol className="ex-timeline">{sel.history.map((h) => <li key={h}>{h}</li>)}</ol>
            <p className="ex-note">{t("Executives can view this page but not change operational settings.")}</p>
          </>
        )}
      </Drawer>
    </div>
  )
}
