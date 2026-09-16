# Duplication check — MoonStix

- Date: 2026-09-16
- Recheck: 2026-09-16
- Candidate: MoonStix, package `2200732518gjy/moonstix`
- Scope: OASIS STIX 2.1 cyber threat intelligence object graph (Bundle, SDO, SRO, SCO, marking/language/extension metadata), property tables, object-ref integrity, STIX patterning parse, JSON roundtrip
- Non-goals: TAXII HTTP transport, MITRE ATT&CK catalog download, CVE/NVD storage, YARA byte scanning, live pattern evaluation against telemetry

## Search keywords

stix, stix2, taxii, taxii2, misp, opencti, cybox, sighting, indicator, threat-actor, intrusion-set, observed-data, malware-analysis, patterning, cti, ioc

## mooncakes.io / moon search

Toolchain: moonsqlguard-evidence/moon-latest/bin/moon.exe (0.1.20260915+0c0e245ee). User-scope ~/.moon/bin/moon.exe has no search subcommand.

Live `moon search --limit 20` (empty result files were 19 bytes, the CLI "No modules found" payload):

| Term | Result |
| --- | --- |
| stix | empty |
| stix2 | empty |
| taxii | empty |
| taxii2 | empty |
| misp | empty |
| opencti | empty |
| cybox | empty |
| sighting | empty |
| stix_pattern | empty |
| threat-actor | empty / false positives |
| indicator | empty / false positives |

False positive: bobzhang/games neon_taxi_rush_2026 (arcade), not TAXII.

## osc2026-guide

Used installed skill osc2026-guide. Guide requires local moon search plus mooncakes.io docs URLs. No MoonBit STIX/TAXII/MISP/OpenCTI package was found. Adjacent security packages were recorded as different problem loops.

## Adjacent repositories (not the same loop)

- Hjyyutr/moonyara@0.1.5 — YARA compile/scan on bytes (PE/ELF/ZIP). Not CTI object interchange.
- LuoYunze06/moonspdx@0.3.0, clbbbb/moonbit-license-audit@0.1.1 — SPDX license expressions. Not STIX.
- Derk2006/sarifkit@0.1.1, Noverberrain/moonsarif — SARIF static-analysis reports. Not STIX.
- liyun/moonseal@0.2.1 — CycloneDX SBOM. Not STIX.
- hutingyu-nuist/moonsqlguard@0.1.0 — SQLi detection. Not STIX.
- ryota0624/moonbit_cloudevents@0.1.2 — CloudEvents envelope. Not CTI objects.
- moonbit-community/opentelemetry@0.1.5, brickfrog/moontrace@0.14.0 — telemetry SDK. Not STIX.
- oyjh0381/moonipfix — IPFIX decoder. Flow meters, not intelligence objects.
- Policy languages (moon_cel, mooncedar, Casbin) — authorization, not STIX patterning.

GitHub name 2200732518gjy/moonstix returned 404 at check time.

## Overlap judgement

No MoonCakes package implements STIX 2.x objects, bundles, or patterning. Security-neighbour packages exist, but they do not parse STIX IDs, SDO/SRO/SCO property tables, bundle identity uniqueness, or the STIX patterning grammar. That is a different core data model and workflow.

Prior user fingerprints excluded: Fountain screenplay parsing; SPDX license-expression maintenance.

## Decision

Select MoonStix. Rejected alternatives in the same matrix: XMPP (messaging-protocol neighbourhood) and GTFS (geo/calendar neighbourhood).
