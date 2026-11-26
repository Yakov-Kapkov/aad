# Design questions

Questions to put to the user — not rules the skill applies.

## The vocabulary

| Question | When the answer is no |
|---|---|
| Does a pseudo-test need this participant? | it may not be needed yet — propose leaving it out |
| Is it one responsibility, at one level? | ask whether two participants are hiding in it |
| Does an existing participant already hold this concern? | see `SKILL.md`, "Existing code comes first" |
| Does the name say the role, in the domain's language? | propose a name; the user keeps or changes it |
| Is every symbol a pseudo-test names listed here? | ask which participant holds it — never add one yourself |

## Steps and levels

| Question | What to raise |
|---|---|
| Can this pseudo-test only be written a level above where the behaviour lives? | the rule is hidden behind that level's wiring — say so |
| Does it reach into the level below? | ask which participant at that level owns the behaviour, or whether it belongs lower |
| Does this level have no step? | ask whether the level is part of this change; an empty level may be shape without meaning |
| Is a participant used by two levels? | ask which level owns it — shared vocabulary is a design decision |
| Does the same behaviour appear at two levels? | ask what each level proves that the other cannot, or it is one pseudo-test written twice |

## What earns an item

| Test | Question |
|---|---|
| Composition | Does the behaviour arise from ≥2 components interacting, or from crossing a boundary? |
| Design-constraining | Could two different implementations satisfy it differently? |
| Late-cost | Would discovering it late be expensive — ordering, retry, concurrency, consistency? |
