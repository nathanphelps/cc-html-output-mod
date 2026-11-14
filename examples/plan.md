# Implementation plan: CSV export for the Reports page

## Summary

Add an "Export CSV" button to the Reports page. The export runs on the server, streams rows instead of loading them into memory, and uses the filters the user has applied. 6 files: 4 new, 2 changed. No database migration.

## Requirements

1. The export contains exactly the rows the current filters select, in the current sort order.
2. Columns match the visible table columns, with the same header labels.
3. Exports of up to 1,000,000 rows complete without the server holding all rows in memory.
4. The user sees progress and can keep using the page while the export runs.
5. Only users with the `reports:read` permission can export.
6. Dates are written as ISO 8601 in UTC. Amounts are written as plain decimals with no currency symbol.

## User flow

1. The user sets filters on the Reports page and clicks **Export CSV**.
2. A notice appears at the bottom right: "Preparing export… 0 rows".
3. The row count in the notice updates every second.
4. When the export finishes, the notice changes to "Export ready" with a **Download** link.
5. If the export fails, the notice shows the reason and a **Retry** button.

## Data flow

`ReportsPage` → `ExportButton` → `POST /api/reports/export` → `csvStream` → temporary file → `GET /api/reports/export/:id/download`

The button sends the current filters, visible columns, and sort order. The server creates an export job, returns its id, and writes rows to a temporary file in batches of 5,000. The client polls the job once per second until its status is `done` or `failed`.

## File structure

```
src/reports/
  ReportsPage.tsx          changed   add ExportButton to the toolbar
  ExportButton.tsx         new       button, notice, download link
  useExport.ts             new       starts the job and polls its status
server/routes/
  reports.ts               changed   three new routes
server/export/
  csvStream.ts             new       turns a row cursor into CSV text
  csvStream.test.ts        new       escaping, dates, large inputs
```

## Interfaces

```ts
type ExportRequest = {
  filters: ReportFilters;
  columns: string[];
  sort: { column: string; direction: "asc" | "desc" };
};

type ExportJob = {
  id: string;
  status: "queued" | "running" | "done" | "failed";
  rowCount: number;
  error?: string;
};
```

## Steps

1. Write `csvStream.ts` and its tests. Check: tests pass for commas, quotes, line breaks, and empty values inside fields.
2. Add `POST /api/reports/export`. Check: a request without `reports:read` returns 403; a valid request returns a job id.
3. Add the status and download routes. Check: the status route reports a rising `rowCount`; the download route returns `text/csv`.
4. Write `useExport.ts`. Check: the hook stops polling when the status is `done` or `failed`.
5. Write `ExportButton.tsx` and add it to `ReportsPage.tsx`. Check: the button is disabled while an export is running.
6. Run a 1,000,000-row export against the staging database. Check: server memory stays under 300 MB and the file opens in a spreadsheet program.

## Risks

| Risk | Likelihood | Effect | Mitigation |
|------|------------|--------|------------|
| A long export holds a database connection | Medium | Other requests slow down | Use the read replica and a 5-minute timeout |
| A field value starts with `=`, `+`, `-`, or `@` | High | A spreadsheet program runs it as a formula | Prefix those values with a single quote |
| Temporary files fill the disk | Low | Later exports fail | Delete files after 1 hour; cap total size at 5 GB |
| Filters change while an export runs | Medium | The user expects the new filters | The notice shows the filters the export used |

## Open questions

1. Should the file name include the date range, for example `reports-2026-01-01-to-2026-03-31.csv`?
2. Is a 1,000,000-row limit acceptable, or should larger exports be sent by email?
3. Should exports be recorded in the audit log?
