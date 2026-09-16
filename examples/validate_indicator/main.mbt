///|
fn broken_indicator() -> String {
  "{\"type\":\"indicator\",\"spec_version\":\"2.1\",\"id\":\"indicator--8e2e2d2b-17d4-4cbf-938f-98ee46b3cd3f\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"pattern\":\"file:name = 'dropper.exe'\",\"pattern_type\":\"stix\",\"valid_from\":\"2024-01-01T00:00:00Z\"}"
}

///|
fn main raise {
  let parsed = @stix.parse_and_validate(broken_indicator()).unwrap()
  let issues = parsed.1
  println("issue-count=\{issues.length()}")
  for i = 0; i < issues.length(); i = i + 1 {
    let item = issues[i]
    println("\{item.code} at \{item.path}: \{item.message}")
  }
  if issues.length() == 0 {
    assert_true(false)
  }
}
