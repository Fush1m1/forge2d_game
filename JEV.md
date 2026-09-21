# Jev integration

## Password gate

- Not a real security control — just friction against an accidental tap
  burning through Jev credits.

## What gets sent

Jev only sees each lane's top-ball summary, not individual ball positions
or full board geometry.

## Not "just drop at the lowest point"

No local code ranks lanes by height and picks the minimum. The lane
choice is entirely up to Jev; the app only sends it a 2-tier instruction:

1. Prefer a lane whose topmost ball matches the next ball's level (merge).
2. Otherwise, prefer the lane with the lowest stack.

Whether Jev's model actually follows this is not verified/guaranteed —
it's inferring from natural-language `criteria` text, not doing exact
numeric optimization. `answers.lane.probabilities` / `confidence` in the
debug log are the way to check how it's actually weighting lanes.
