# Wish App → Yearlit: Comments + Upvotes Integration Plan

## Context
Yearlit currently integrates Wish App only for feature **requests** (list + create + delete) via `FeatureRequestManager` and the Convex HTTP endpoints (`/api/project/:id/requests/`, `/api/project/:id/request/`, `/api/project/:id/request/:reqID`).

Wish App now exposes **comments** and **upvotes** for requests via Convex HTTP:
- `GET  /api/project/:id/request/:reqID/comments`
- `POST /api/project/:id/request/:reqID/comment`
- `POST /api/project/:id/request/:reqID/upvote`

Source (wish-app repo): `convex/http.ts`, `convex/requestComments.ts`, `convex/requestUpvotes.ts`.

## Goal
Surface request discussion + prioritization inside Yearlit, using the same public client ID used for request creation.

---

## API Contract (Wish App)
**Comments**
- **List:** `GET /api/project/:id/request/:reqID/comments`
  - Response: `{ comments: Comment[] }`
- **Create:** `POST /api/project/:id/request/:reqID/comment`
  - Body: `{ clientId: string, body: string }`

**Upvotes**
- **Toggle:** `POST /api/project/:id/request/:reqID/upvote`
  - Body: `{ clientId: string }`

**Notes**
- Requires `clientId` for public (non‑auth) usage.
- Upvote response currently empty `200` from HTTP layer (no payload).

---

## Yearlit Changes (Plan)
### 1) Models
Add models mirroring Wish App payloads:
- `RequestComment`
  - `_id`, `requestId`, `projectId`, `authorType`, `authorClientId?`, `authorUserId?`, `body`, `createdAt`
- `RequestCommentsResponse` (`comments: [RequestComment]`)

Extend `Request` with:
- `upvoteCount: Int?` (already in Wish App schema; add to decode safely)

### 2) FeatureRequestManager API
Add methods:
- `getComments(requestId:)` → `RequestCommentsResponse`
- `addComment(requestId:, body:)`
- `toggleUpvote(requestId:)`

Implementation:
- Use existing `user.id` as `clientId` (already used in createRequest).
- Use `HTTP.get` / `HTTP.post` like existing calls.

### 3) UI/UX
**Request Detail** (FeatureRequestDetailView):
- Add a comments section under request body
- Show comment list + count
- Add composer (text field + send)

**Request List / Card** (FeatureRequestsListItem):
- Add upvote pill/button with count
- Highlight if current user upvoted (requires a local cache or derived state)

### 4) Caching / State
- Extend `FeatureRequestManager` to cache:
  - comments per request (in‑memory)
  - viewer upvotes set (if we add a dedicated endpoint later)

Given the HTTP toggle endpoint returns no payload, we can either:
- Optimistically update local upvote count and state
- Or refetch the request list after a toggle

### 5) Error Handling
- Surface inline error messages (toast / alert) for:
  - comment validation (empty / too long)
  - network failures

---

## Open Questions
1. Do we want to **display developer comments** differently (authorType = `developer`) inside Yearlit?
2. Should we expose **delete comment** in Yearlit? (Wish App supports it only for authenticated devs.)
3. Upvote button placement: in list only, or list + detail?
4. Should we add a **viewer upvote state** endpoint in Wish App HTTP for public clients? (Currently only toggle exists.)

---

## Suggested Implementation Order
1. Add models + manager methods
2. Add comments UI in detail view
3. Add upvote UI on list item + optimistic local update
4. Polish empty states + errors

---

## Files to Touch (Yearlit)
- `My Year/Models/FeatureRequests.swift`
- `My Year/Managers/FeatureRequestManager.swift`
- `My Year/Views/Settings/FeatureRequest/FeatureRequestDetailView.swift`
- `My Year/Views/Settings/FeatureRequest/FeatureRequestsListItem.swift`
- `My Year/Views/Settings/FeatureRequest/FeatureRequestsList.swift` (if we need to refresh / invalidate after upvote)
