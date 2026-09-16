///|
fn sample_identity() -> String {
  "{\"type\":\"identity\",\"spec_version\":\"2.1\",\"id\":\"identity--f431f809-377b-4a0a-aa7a-4c4119c8d3e2\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"name\":\"CERT-Example\",\"identity_class\":\"organization\"}"
}

///|
fn sample_indicator() -> String {
  "{\"type\":\"indicator\",\"spec_version\":\"2.1\",\"id\":\"indicator--8e2e2d2b-17d4-4cbf-938f-98ee46b3cd3f\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"name\":\"Malicious IP\",\"indicator_types\":[\"malicious-activity\"],\"pattern\":\"[ipv4-addr:value = '203.0.113.10']\",\"pattern_type\":\"stix\",\"valid_from\":\"2024-01-01T00:00:00Z\"}"
}

///|
fn sample_file() -> String {
  "{\"type\":\"file\",\"spec_version\":\"2.1\",\"id\":\"file--e9a0f947-b0cf-4e0c-95ed-3c92d4374835\",\"hashes\":{\"SHA-256\":\"aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f\"},\"name\":\"dropper.exe\"}"
}

///|
fn sample_observed() -> String {
  "{\"type\":\"observed-data\",\"spec_version\":\"2.1\",\"id\":\"observed-data--b67d7432-e4de-411a-9e73-10f79adb4ad0\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"first_observed\":\"2024-01-01T00:00:00Z\",\"last_observed\":\"2024-01-01T00:05:00Z\",\"number_observed\":1,\"object_refs\":[\"file--e9a0f947-b0cf-4e0c-95ed-3c92d4374835\"]}"
}

///|
fn sample_sighting() -> String {
  "{\"type\":\"sighting\",\"spec_version\":\"2.1\",\"id\":\"sighting--ee20065d-2555-424f-ad9e-0f8424083eb8\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"count\":1,\"sighting_of_ref\":\"indicator--8e2e2d2b-17d4-4cbf-938f-98ee46b3cd3f\",\"observed_data_refs\":[\"observed-data--b67d7432-e4de-411a-9e73-10f79adb4ad0\"]}"
}

///|
fn sample_relationship() -> String {
  "{\"type\":\"relationship\",\"spec_version\":\"2.1\",\"id\":\"relationship--44298a74-ba52-4f0c-87a3-1824e67d7fad\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"relationship_type\":\"indicates\",\"source_ref\":\"indicator--8e2e2d2b-17d4-4cbf-938f-98ee46b3cd3f\",\"target_ref\":\"malware--c66d1d3e-3cad-4eb2-912d-86c8272e2fa7\"}"
}

///|
fn sample_malware() -> String {
  "{\"type\":\"malware\",\"spec_version\":\"2.1\",\"id\":\"malware--c66d1d3e-3cad-4eb2-912d-86c8272e2fa7\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"name\":\"FamilyX\",\"is_family\":true,\"malware_types\":[\"trojan\"]}"
}

///|
fn wrap_bundle(objects : Array[String]) -> String {
  let mut inner = ""
  for i = 0; i < objects.length(); i = i + 1 {
    if i > 0 {
      inner = "\{inner},"
    }
    inner = "\{inner}\{objects[i]}"
  }
  "{\"type\":\"bundle\",\"id\":\"bundle--00000000-0000-4000-8000-000000000001\",\"objects\":[\{inner}]}"
}

///|
test "valid indicator has no issues" {
  let result = parse_and_validate(sample_indicator()).unwrap()
  assert_eq(result.1.length(), 0)
}

///|
test "missing required field is reported" {
  let text = "{\"type\":\"indicator\",\"spec_version\":\"2.1\",\"id\":\"indicator--8e2e2d2b-17d4-4cbf-938f-98ee46b3cd3f\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"pattern_type\":\"stix\",\"valid_from\":\"2024-01-01T00:00:00Z\"}"
  let result = parse_and_validate(text).unwrap()
  let mut found = false
  result.1.each(fn(item) { if item.code == "missing" { found = true } })
  assert_true(found)
}

///|
test "invalid pattern is reported" {
  let text = "{\"type\":\"indicator\",\"spec_version\":\"2.1\",\"id\":\"indicator--8e2e2d2b-17d4-4cbf-938f-98ee46b3cd3f\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"pattern\":\"not a pattern\",\"pattern_type\":\"stix\",\"valid_from\":\"2024-01-01T00:00:00Z\"}"
  let result = parse_and_validate(text).unwrap()
  let mut found = false
  result.1.each(fn(item) { if item.code == "pattern" { found = true } })
  assert_true(found)
}

///|
test "relationship constraint" {
  let bad = "{\"type\":\"relationship\",\"spec_version\":\"2.1\",\"id\":\"relationship--44298a74-ba52-4f0c-87a3-1824e67d7fad\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"relationship_type\":\"indicates\",\"source_ref\":\"malware--c66d1d3e-3cad-4eb2-912d-86c8272e2fa7\",\"target_ref\":\"indicator--8e2e2d2b-17d4-4cbf-938f-98ee46b3cd3f\"}"
  let result = parse_and_validate(bad).unwrap()
  let mut found = false
  result.1.each(fn(item) {
    if item.code == "relationship-constraint" {
      found = true
    }
  })
  assert_true(found)
}

///|
test "bundle uniqueness and refs" {
  let text = wrap_bundle([
    sample_indicator(),
    sample_malware(),
    sample_relationship(),
    sample_file(),
    sample_observed(),
    sample_sighting(),
    sample_identity(),
  ])
  let result = parse_and_validate(text).unwrap()
  assert_eq(result.1.length(), 0)
  match result.0 {
    Bundle(bundle) => assert_eq(bundle.objects.length(), 7)
    Object(_) => fail("expected bundle")
  }
}

///|
test "duplicate id in bundle" {
  let text = wrap_bundle([sample_file(), sample_file()])
  let result = parse_and_validate(text).unwrap()
  let mut found = false
  result.1.each(fn(item) { if item.code == "duplicate-id" { found = true } })
  assert_true(found)
}

///|
test "unresolved ref in bundle" {
  let text = wrap_bundle([sample_observed()])
  let result = parse_and_validate(text).unwrap()
  let mut found = false
  result.1.each(fn(item) { if item.code == "unresolved-ref" { found = true } })
  assert_true(found)
}

///|
test "json syntax error" {
  match parse_document("{") {
    Err(JsonSyntax(_)) => ()
    _ => fail("expected json syntax error")
  }
}

///|
test "roundtrip stringify preserves object json" {
  let text = sample_file()
  let doc = parse_document(text).unwrap()
  let again = parse_document(stringify_document(doc)).unwrap()
  match (doc, again) {
    (Object(a), Object(b)) => assert_eq(a.id, b.id)
    _ => fail("expected objects")
  }
}

///|
test "ipv4 object validates" {
  let text = "{\"type\":\"ipv4-addr\",\"spec_version\":\"2.1\",\"id\":\"ipv4-addr--5853f6a4-638f-4b39-ae39-36d06e76e6ff\",\"value\":\"203.0.113.10\"}"
  let result = parse_and_validate(text).unwrap()
  assert_eq(result.1.length(), 0)
}

///|
test "location requires coordinates pair" {
  let text = "{\"type\":\"location\",\"spec_version\":\"2.1\",\"id\":\"location--a6e9345f-5a15-4c29-8bb3-7dcc5d168d62\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"latitude\":33.2}"
  let result = parse_and_validate(text).unwrap()
  let mut found = false
  result.1.each(fn(item) { if item.code == "pair" { found = true } })
  assert_true(found)
}

///|
test "vocab closed opinion" {
  let text = "{\"type\":\"opinion\",\"spec_version\":\"2.1\",\"id\":\"opinion--5ed67b32-cc89-4aba-ab12-9ead48161642\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"opinion\":\"maybe\",\"object_refs\":[\"malware--c66d1d3e-3cad-4eb2-912d-86c8272e2fa7\"]}"
  let result = parse_and_validate(text).unwrap()
  let mut found = false
  result.1.each(fn(item) { if item.code == "vocab" { found = true } })
  assert_true(found)
}
