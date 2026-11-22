# Working on this repo

This repo documents my homelab, one lesson at a time. When I finish a lesson with Claude, Claude writes it up and pushes it here itself.

## When a lesson is completed

1. Write `docs/NN-short-name.md` (next number after the highest one in `docs/`), following `docs/_template.md` and the style of the recent lessons: Goal, Background, What I Did (real commands), What Broke (exact error messages), How I Fixed It, What I Learned. First person, plain language. Only write down what actually happened.
2. In `docs/PLAN.md`: add a row to the Progress Log (date, one-line summary, link), add the file to the repo layout list, and tick any checklist items the lesson completed.
3. Put any config files from the lesson in `configs/<service>/` and any scripts in `scripts/`.
4. Commit and push straight to `main` (no pull request). One commit per lesson, message like `Add lesson NN (topic)`.

If a lesson isn't finished yet, mark it "(in progress)" in its title and log row, and finish it in a later commit.

## Never commit

Passwords, keys, tokens, `.env` files, or MAC addresses / serial numbers. Private 192.168.x.x addresses are fine.
