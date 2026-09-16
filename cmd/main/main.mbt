///|
fn main {
  let text = "{\"type\":\"ipv4-addr\",\"spec_version\":\"2.1\",\"id\":\"ipv4-addr--5853f6a4-638f-4b39-ae39-36d06e76e6ff\",\"value\":\"203.0.113.10\"}"
  let parsed = @moonstix.parse_and_validate(text).unwrap()
  println("issues=\{parsed.1.length()}")
  match parsed.0 {
    Object(obj) => println("\{obj.stix_type} \{obj.id}")
    Bundle(_) => println("bundle")
  }
}
