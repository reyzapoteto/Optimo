# OPTIMO Executive — Part 12 Supplement

## Context
Part 12 adds RTL, demo mode, live events, map layers, presentation mode, save states, status languages and an export template to the Executive role. The repo (`src/App.tsx`, 5,845 lines; `src/index.css`; `src/product.css`) only has the **Duty Manager** and **Supervisor** roles. Parts 1–11 (Executive screens) are not in the code. **Assumption:** this plan adds a minimal, additive Executive role and builds Part 12 on top of it. Existing screens stay unchanged (DoD #1).

## Approach
New files go in `src/executive/` so the large App.tsx only gets small hook-in edits.

1. **Role wiring (App.tsx, additive)**: extend `Role` with `"Executive"`, add an `accounts` entry (EX-001) and a `roleForStaffId` mapping, and filter nav to Excellence Center, Performance and Reports. Reuse `Button`, `Dropdown`, `Status`, `Wordmark`, `LanguageSwitch`, `Toast`, `OverflowMenu`, `PermissionState`, `useArabicTranslation`, and the `arabicCopy` dictionary (add new keys to it).
2. **`executive/store.ts`**: one shared event source (`useSyncExternalStore`) with stable facility IDs (SH-04, TC-xx, WB-xx). It holds events from 12.3, the six scenario step scripts from 12.2, speed ×1/×5/×10, and an offline queue. Business-rule selectors cover 12.4: offline/stale → "Status unknown", never Ready; vacant+service ≠ Ready; the SLA clock is not reset on accept.
3. **`executive/status.tsx`**: five distinct primitives from 12.5: OccupancyDot, FacilityChip (rounded square), TaskPill, SignalBars, SlaRing (countdown, tabular numerals, aria-live summaries).
4. **`executive/ExecutiveCenter.tsx`**: readiness and performance KPIs with 450ms count animation, Key Risks (top 3), Highlights, and a map. The map supports Layers popover MD-04, zoom/pan/Reset view, Level selector, keyboard nodes, an "Illustrative demo layout" label, and a node ring pulse at 200ms. It also has presentation mode (64/32 spacing, ×1.25 scale, 44px markers, Share and Export hidden, Exit control and Esc) and an annotation layer.
5. **`executive/Overlays.tsx`**: Presenter Panel MD-23 (480 drawer from the end side, opened with Shift+P or a small icon), Reset dialog MD-24, Notifications MD-14 (Unread filter, Follow-ups tab, sound off by default), and Export MD-05 with the PDF template preview from 12.9 (EN and RTL).
6. **`executive/Performance.tsx`**: SLA charts with a text summary line, MD-13 definitions, and the footnote "Targets are confirmed with Operations."
7. **Header additions**: a Demo badge plus "Accelerated time ×N". Save-state helpers (Pending sync vs Saved, loading width lock, disabled reason), an offline banner, and a states switcher (Loading, Empty, Error, Offline, Pending, Success, Denied).
8. **CSS (`product.css`)**: logical properties only. Add `[dir=rtl]` line-height +12% for Arabic text and `@media (prefers-reduced-motion)` overrides. Use tablet overlays at 384px for 768–1024. Existing tokens only (yellow, Manrope + Noto Sans Arabic, 8pt spacing, radius 8/12/16).

Out of scope per 12.13 stays absent. Developer annotations go in a collapsible "Dev notes" panel per page.

## Verification
Log in as EX-001. Run each of the six scenarios through the Presenter Panel and toggle EN/AR. Check presentation mode, a 900px viewport, and reduced motion. Confirm Duty Manager and Supervisor views are unchanged.
