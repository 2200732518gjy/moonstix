# Contributing

1. Keep changes inside the STIX 2.1 object/bundle/patterning scope. Do not add TAXII, ATT&CK download, CVE storage, or YARA scanning.
2. Format and check before sending a patch:

```bash
moon fmt
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc
```

3. Add a focused test when you change validation or the pattern grammar.
4. Run the three examples if you touch `parse_document`, `validate_document`, or patterning.
