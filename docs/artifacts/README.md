# Artifact Bundles

This toolkit is designed to produce **portable artifacts** that a Solution Architect can attach to a ticket, PR, or review packet.

Starting with UC02 (Inventory + Auto-Documentation), runs can emit an **artifact bundle** in addition to the raw discovery outputs.

## Bundle Layout (UC02)

Default output folder: `out/artifacts/`

Files:
- `metadata.json`: bundle metadata (cloud, scope, timestamps, toolkit git SHA)
- `inventory.json`: normalized inventory (stable schema across clouds)
- `SUMMARY.md`: normalized human-readable summary
- `SCORECARD.md`: quick findings (best-effort, non-authoritative)
- `diagram.mmd`: Mermaid diagram (lightweight architecture picture)

Raw discovery outputs remain at:
- `out/inventory.json`
- `out/SUMMARY.md`

## Schema

Normalized inventories follow: `docs/artifacts/inventory.schema.json`

The schema is intentionally conservative. It provides stable top-level fields and summarized resource counts while allowing cloud-specific extensions under `extensions`.

