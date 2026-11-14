# Brainstorm: where to cache report results

## Problem

The Reports page runs the same aggregate query every time it loads. The query takes 4 to 9 seconds on the production database. Most users open the page several times a day with the same filters. We want the page to load in under 1 second for repeated views, and we can accept data that is up to 15 minutes old.

## Option A: in-memory cache in each server process

Keep results in a map inside each web server process, keyed by the filter values, with a 15-minute expiry.

- Fits because: no new infrastructure, and it can ship in a day.
- Effort: about 1 day.
- Speed for repeated views: about 5 ms, but only when the request reaches a process that already has the result.
- Staleness: up to 15 minutes, and different processes can show different numbers.
- Risk: with 8 processes, a user can see totals change between page loads. Memory use grows with the number of distinct filter combinations.

## Option B: shared Redis cache

Store results in Redis, keyed by a hash of the filter values, with a 15-minute expiry. All processes read the same entry.

- Fits because: one consistent answer for every process, and Redis is already used for sessions.
- Effort: about 3 days, including a size limit and a way to clear entries.
- Speed for repeated views: about 20 ms.
- Staleness: up to 15 minutes, the same for everyone.
- Risk: large results (over 5 MB) are slow to serialize. A Redis outage must fall back to the direct query, not to an error.

## Option C: precomputed summary table

A scheduled job writes daily totals into a summary table every 15 minutes. The Reports page reads the summary table and never runs the aggregate query.

- Fits because: every view is fast, including the first one, and the load on the production database drops.
- Effort: about 8 days, including the job, a backfill, and a check that totals match.
- Speed for all views: about 80 ms.
- Staleness: up to 15 minutes, the same for everyone, and the page can show the time of the last refresh.
- Risk: every new filter needs a schema change. A bug in the job produces wrong totals that look correct.

## Comparison

| | A: in-memory | B: Redis | C: summary table |
|---|---|---|---|
| Effort | 1 day | 3 days | 8 days |
| Repeated view | 5 ms | 20 ms | 80 ms |
| First view | 4 to 9 s | 4 to 9 s | 80 ms |
| Same numbers for everyone | No | Yes | Yes |
| New infrastructure | None | None | Scheduled job, new table |
| Cost of adding a filter | None | None | Schema change |

## Recommendation

Option B. It meets the 1-second goal for repeated views, gives every user the same numbers, and uses infrastructure we already run. Option A is faster to build but shows inconsistent totals. Option C is the only one that fixes the first view, and it is worth revisiting if first-view time becomes the main complaint.

## What would change this recommendation

- If more than half of page loads are first views, choose C.
- If results are regularly larger than 5 MB, choose C.
- If this is needed before the end of the week, ship A and replace it with B.
