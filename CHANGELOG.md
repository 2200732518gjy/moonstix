# Changelog

## 0.1.0

- Parse and stringify STIX 2.1 Bundles and single objects.
- Validate 18 SDOs, relationship/sighting, 18 SCOs, and marking/language/extension metadata against property tables.
- Check identifier uniqueness, object-ref integrity, and a relationship allow-table.
- Parse a STIX patterning subset into an AST and report path/grammar issues on `indicator` objects.
- Ship three runnable examples and wasm-gc tests for identifiers, timestamps, patterns, and bundle graphs.
