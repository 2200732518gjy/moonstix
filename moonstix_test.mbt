///|
test "stix id accepts type and uuid" {
  let parsed = parse_stix_id("indicator--8e2e2d2b-17d4-4cbf-938f-98ee46b3cd3f").unwrap()
  assert_eq(parsed.type_name, "indicator")
  assert_eq(parsed.uuid, "8e2e2d2b-17d4-4cbf-938f-98ee46b3cd3f")
}

///|
test "stix id rejects missing separator" {
  match parse_stix_id("indicator") {
    Err(message) => assert_true(message.contains("--"))
    Ok(_) => fail("expected invalid id")
  }
}

///|
test "stix id rejects truncated uuid" {
  match parse_stix_id("file--8e2e2d2b-17d4-4cbf-938f") {
    Err(message) => assert_true(message.contains("UUID"))
    Ok(_) => fail("expected invalid uuid")
  }
}

///|
test "timestamp requires timezone" {
  match parse_timestamp("2024-01-02T03:04:05") {
    Err(message) => assert_true(message.contains("timezone"))
    Ok(_) => fail("expected missing timezone")
  }
}

///|
test "timestamp accepts fractional zulu" {
  let parsed = parse_timestamp("2024-02-29T23:59:59.123Z").unwrap()
  assert_eq(parsed.year, 2024)
  assert_eq(parsed.month, 2)
  assert_eq(parsed.day, 29)
  assert_eq(parsed.offset_minutes, 0)
}

///|
test "timestamp accepts offset" {
  let parsed = parse_timestamp("2023-12-31T01:02:03+08:00").unwrap()
  assert_eq(parsed.offset_minutes, 480)
}

///|
test "timestamp rejects impossible day" {
  match parse_timestamp("2023-02-29T00:00:00Z") {
    Err(message) => assert_true(message.contains("day"))
    Ok(_) => fail("expected invalid day")
  }
}

///|
test "ipv4 and cidr" {
  assert_true(valid_ipv4("10.0.0.1"))
  assert_true(valid_ipv4("192.168.0.0/16"))
  assert_true(!valid_ipv4("10.0.0.256"))
  assert_true(!valid_ipv4("1.2.3"))
}

///|
test "network identifiers" {
  assert_true(valid_ipv6("2001:db8::1"))
  assert_true(valid_mac("00:11:22:33:44:55"))
  assert_true(valid_email("soc@example.com"))
  assert_true(valid_url("https://example.com/report"))
}

///|
test "type tables include core objects" {
  assert_true(
    match lookup_type_spec("indicator") {
      Some(_) => true
      None => false
    },
  )
  assert_true(
    match lookup_type_spec("file") {
      Some(_) => true
      None => false
    },
  )
  assert_true(
    match lookup_type_spec("relationship") {
      Some(_) => true
      None => false
    },
  )
  assert_true(known_type_names().length() >= 40)
}
