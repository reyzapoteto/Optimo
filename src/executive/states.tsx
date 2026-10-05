import { useT } from "./status"
import { Svg, ic } from "./ui"

export type PageName = "Excellence Center" | "Quality" | "Issues" | "Reports"

export function PageSkeleton({ page }: { page: PageName }) {
  const t = useT()
  const strip = page === "Excellence Center" ? 136 : 120
  return (
    <div className="ex-grid" aria-busy="true" aria-label={t("Loading")}>
      <i className="ex-sk" style={{ gridColumn: "1 / -1", blockSize: strip }} />
      {page === "Reports" ? (
        <>
          <div className="ex-span8 ex-stack">{[0, 1, 2].map((i) => <i key={i} className="ex-sk" style={{ blockSize: 190 }} />)}</div>
          <div className="ex-span4 ex-stack">{[0, 1].map((i) => <i key={i} className="ex-sk" style={{ blockSize: 240 }} />)}</div>
        </>
      ) : (
        <>
          <i className="ex-sk" style={{ gridColumn: "span 8", blockSize: 300 }} />
          <i className="ex-sk" style={{ gridColumn: "span 4", blockSize: 300 }} />
          <i className="ex-sk" style={{ gridColumn: "1 / -1", blockSize: 280 }} />
        </>
      )}
    </div>
  )
}

export function StateCard({ kind, retry, change }: { kind: "empty" | "error"; retry: () => void; change?: () => void }) {
  const t = useT()
  return (
    <div className="ex-state" role={kind === "error" ? "alert" : "status"}>
      <span className={`ex-state-ico ${kind}`}><Svg d={kind === "error" ? ic.issues : ic.doc} size={24} /></span>
      <h2>{t(kind === "error" ? "Something went wrong loading this view." : "No data for this period.")}</h2>
      <p>{t(kind === "error" ? "Live facility status is not affected. Your data has not changed." : "Try a longer period or another location. Live status stays available on the Excellence Center.")}</p>
      <div className="ex-state-actions">
        <button className="ex-btn secondary" onClick={retry}>{t(kind === "error" ? "Retry" : "Show live data")}</button>
        {change && <button className="ex-tertiary" onClick={change}>{t("Back to Excellence Center")}</button>}
      </div>
    </div>
  )
}
