# Web/backend API contract audit

Audit date: 2026-09-29

## Result

- Backend controller mappings discovered: 146.
- Direct frontend API calls discovered: 100.
- Statically resolvable method/path mismatches after fixes: 0.
- Dynamic calls reviewed manually: agenda section/item operations, paged report selection, report exports, device actions, and generic CRUD resource paths.

## Contract fixes

1. User role, board type, and access profile options now submit enum identifiers such as `BOARD_SECRETARY`, not their display labels.
2. Access profiles are restricted to the selected backend role.
3. User status filtering now sends `DEACTIVATED` instead of the unsupported `INACTIVE` value.
4. Agenda item types now use `HEADING`, `SUB_HEADING`, `PAPER`, `AUDIO`, and `VIDEO` from `AgendaItemType`.
5. Approval decisions now use `APPROVE`, `REJECT`, `ABSTAIN`, `INTEREST`, and `RPT` from `ApprovalStatus`.
6. Paper creation inside a meeting now uploads the primary PDF and sends `filePath` and `fileName` before calling `POST /papers`.
7. The approval request no longer sends the unsupported `userId` field.

Run `npm run audit:api` to repeat the controller/path comparison.
