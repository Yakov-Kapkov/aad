# Statuses

Every artifact earns exactly one of seven statuses at every level. Each is a different repair.

## The seven statuses

- `present` — one or more documents answer its entry, and a route reaches them: a
  readme link, or a location outside the repo the agent can open unaided. Nothing
  to do.
- `partial` — the routed documents answer part of its entry. Finish the missing
  items.
- `orphaned` — a document exists, but no readme links to it. Add one link; whether
  it is complete is settled after that.
- `broken` — a readme link is broken or points to a document that doesn't exist.
  Repair or remove the link. A dead link that routes no artifact is reported in
  the level's `check-links` line, never as an artifact row.
- `absent` — nothing is written, and no readme links to it. Someone has to write it.
- `unverified` — a readme links to where the answer lives outside the repo, and the
  agent cannot fetch it. Confirm access, or copy it in.
- `n/a` — the artifact does not apply at this level: the repo declares it out of
  scope, or the level has none (a library has no deployment). Not a gap.

## Routes that leave the repo

A route may leave the repo — a wiki, a dashboard, Confluence, a design tool — but
it must name the system *and* the location: "BA context lives in Confluence" is not
a route; a space, a page tree, or a URL is. `check-links` resolves relative links
only, so unaided access is the agent's call: needing a human or an access grant —
log in, ask the BA team, open the deck — makes the route `unverified`.
