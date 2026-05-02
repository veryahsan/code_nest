# Standard Commit Messages

Use this guide to write commit messages that are clear, realistic, and easy for anyone on the team to understand.

## Goals

- Explain what changed and why it matters in simple words.
- Keep each message short and useful for future readers.
- Never mention Cursor in commit messages.

## Message Format

Use this structure:

`<type>: <short summary>`

Optional body (1-2 short lines):

- What problem was there before?
- What did this change improve?

## Types to Use

- `feat` - new feature
- `fix` - bug fix
- `refactor` - code cleanup without behavior change
- `docs` - documentation updates
- `test` - tests added or improved
- `chore` - maintenance (config, deps, tooling)

## Rules

1. Write like you are explaining to a teammate, not a machine.
2. Focus on user or developer impact, not just file names.
3. Keep summary line short and specific.
4. Do not use vague messages like "update stuff" or "changes".
5. Do not mention Cursor anywhere.
6. Avoid very long paragraphs; keep body to 1-2 short lines when needed.

## Good Examples

### Feature

`feat: add organisation dashboard for signed-in users`

Body:

`Users now land on a dashboard with teams and projects after login.`
`This makes the first screen useful instead of showing a generic home page.`

### Fix

`fix: redirect users without an organisation to home page`

Body:

`Some users could open the dashboard and hit errors due to missing organisation data.`
`Now they are redirected safely with a clear alert message.`

### Refactor

`refactor: simplify registration flow for organisation signup`

Body:

`The signup logic was hard to follow and repeated checks in many places.`
`This cleanup keeps behavior the same but makes future changes easier.`

### Docs

`docs: add request-response flow explanation for new developers`

Body:

`This explains how routes, controllers, and views work together in this app.`
`It helps new team members understand the project faster.`

### Test

`test: add request specs for dashboard access rules`

Body:

`Covers signed-in, signed-out, and missing-organisation cases.`
`This prevents accidental regressions in access control.`

## Avoid These

- `fix`
- `final changes`
- `updated files`
- `misc improvements`

These are too vague and do not help another reader understand the commit.

## Quick Checklist Before Commit

- Is the summary clear in under one line?
- Does it explain real impact in plain language?
- Is there any mention of Cursor? (If yes, remove it.)
- Is the body short and useful?
