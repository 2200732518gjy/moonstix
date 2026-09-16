# MoonStix

OASIS STIX 2.1 cyber threat intelligence objects, bundles, and patterning for MoonBit.

The library parses STIX JSON, checks property tables for the core 2.1 SDOs, SROs, SCOs and metadata objects, walks identifier references inside a Bundle, and parses the STIX patterning grammar. It does not speak TAXII, download ATT&CK, store CVEs, or scan files with YARA.

Package name: `2200732518gjy/moonstix`. License: Apache-2.0, with BSD-3-Clause attribution for the Python STIX libraries in `THIRD_PARTY.md`.

## Install

Clone the repository and use a recent MoonBit toolchain (wasm-gc is the preferred target):

```bash
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc
```

The crate is not published to mooncakes.io yet; depend on the Git source or a local checkout.

## Use

```moonbit
let parsed = @stix.parse_and_validate(text).unwrap()
let doc = parsed.0
let issues = parsed.1
let _ = @stix.parse_pattern("[ipv4-addr:value = '203.0.113.10']")
```

`issues` is empty when the document matches the built-in 2.1 tables. Pattern parse errors on an `indicator` with `pattern_type` `stix` are reported as `pattern` issues. `stringify_document` round-trips the parsed JSON.

Public entry points also include `parse_document`, `validate_document`, `parse_stix_id`, `parse_timestamp`, `lookup_type_spec`, `known_type_names`, and the IPv4/IPv6/MAC/email helpers.

## Examples

```bash
moon run examples/parse_bundle --target wasm-gc
moon run examples/validate_indicator --target wasm-gc
moon run examples/sighting_graph --target wasm-gc
```

- `parse_bundle` loads a four-object bundle (identity, malware, indicator, relationship) and prints type/id pairs when `issues=0`.
- `validate_indicator` shows a STIX pattern that is missing `[...]` and prints a `pattern` issue.
- `sighting_graph` checks a self-contained sighting, observed-data, and file SCO graph.

## Scope

Supported: STIX 2.1 Bundle; 18 SDOs; relationship and sighting; 18 SCOs; marking-definition, language-content, extension-definition; common properties; a STIX patterning subset (AND/OR/FOLLOWEDBY, START/STOP/WITHIN/REPEATS, IN/LIKE/MATCHES/ISSUBSET/ISSUPERSET/EXISTS).

Not supported: TAXII 2.x transport, MITRE ATT&CK catalog sync, CVE/NVD storage, live pattern evaluation against telemetry, STIX 2.0 `observed-data.objects` dictionaries.

## Verify

```bash
python tools/count_effective_moonbit.py --check-core 2000
moon fmt --check
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc
```

## License

Apache-2.0. See `LICENSE` and `THIRD_PARTY.md`. AI assistance is disclosed in `AI_USAGE.md`. The library does not open network sockets or read host telemetry.
