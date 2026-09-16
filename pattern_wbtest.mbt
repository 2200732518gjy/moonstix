///|
test "pattern parse file hash equality" {
  let expr = parse_pattern(
    "[file:hashes.'SHA-256' = 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f']",
  ).unwrap()
  let types = pattern_object_types(expr)
  assert_eq(types.length(), 1)
  assert_eq(types[0], "file")
  assert_eq(validate_pattern_paths(expr).length(), 0)
}

///|
test "pattern parse observation and" {
  let expr = parse_pattern(
    "[ipv4-addr:value = '10.0.0.1'] AND [domain-name:value = 'evil.example']",
  ).unwrap()
  let types = pattern_object_types(expr)
  assert_true(types.contains("ipv4-addr"))
  assert_true(types.contains("domain-name"))
}

///|
test "pattern parse in like exists and qualifier" {
  let expr = parse_pattern(
    "[network-traffic:dst_port IN (80, 443)] AND [network-traffic:protocols[*] = 'tcp']",
  ).unwrap()
  assert_eq(validate_pattern_paths(expr).length(), 0)
  let qualified = parse_pattern(
    "[file:name LIKE 'drop%.exe'] WITHIN 300 SECONDS",
  ).unwrap()
  match qualified {
    Within(_, amount) => assert_eq(amount, "300")
    _ => fail("expected WITHIN qualifier")
  }
  let exists = parse_pattern("[EXISTS file:parent_directory_ref]").unwrap()
  match exists {
    Observation(Exists(_)) => ()
    _ => fail("expected EXISTS comparison")
  }
}

///|
test "pattern parse followedby start stop" {
  let expr = parse_pattern(
    "[file:name = 'a.exe'] FOLLOWEDBY [process:command_line = 'a.exe'] START t'2024-01-01T00:00:00Z' STOP t'2024-01-02T00:00:00Z'",
  ).unwrap()
  match expr {
    FollowedBy(_, _) => ()
    _ => fail("expected FOLLOWEDBY")
  }
  assert_eq(validate_pattern_paths(expr).length(), 0)
}

///|
test "pattern rejects unknown property" {
  let expr = parse_pattern("[file:not_a_real_field = 'x']").unwrap()
  let issues = validate_pattern_paths(expr)
  assert_true(issues.length() > 0)
  assert_eq(issues[0].code, "pattern-property")
}

///|
test "pattern rejects missing bracket" {
  match parse_pattern("file:name = 'x'") {
    Err(message) => assert_true(message.contains("observation"))
    Ok(_) => fail("expected parse error")
  }
}
