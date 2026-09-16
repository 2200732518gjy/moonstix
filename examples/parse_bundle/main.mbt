///|
fn bundle_json() -> String {
  "{\"type\":\"bundle\",\"id\":\"bundle--00000000-0000-4000-8000-000000000001\",\"objects\":[" +
  "{\"type\":\"identity\",\"spec_version\":\"2.1\",\"id\":\"identity--f431f809-377b-4a0a-aa7a-4c4119c8d3e2\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"name\":\"CERT-Example\",\"identity_class\":\"organization\"}," +
  "{\"type\":\"malware\",\"spec_version\":\"2.1\",\"id\":\"malware--c66d1d3e-3cad-4eb2-912d-86c8272e2fa7\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"name\":\"FamilyX\",\"is_family\":true,\"malware_types\":[\"trojan\"]}," +
  "{\"type\":\"indicator\",\"spec_version\":\"2.1\",\"id\":\"indicator--8e2e2d2b-17d4-4cbf-938f-98ee46b3cd3f\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"name\":\"C2 IP\",\"pattern\":\"[ipv4-addr:value = '203.0.113.10']\",\"pattern_type\":\"stix\",\"valid_from\":\"2024-01-01T00:00:00Z\"}," +
  "{\"type\":\"relationship\",\"spec_version\":\"2.1\",\"id\":\"relationship--44298a74-ba52-4f0c-87a3-1824e67d7fad\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"relationship_type\":\"indicates\",\"source_ref\":\"indicator--8e2e2d2b-17d4-4cbf-938f-98ee46b3cd3f\",\"target_ref\":\"malware--c66d1d3e-3cad-4eb2-912d-86c8272e2fa7\"}" +
  "]}"
}

///|
fn main {
  let parsed = @stix.parse_and_validate(bundle_json()).unwrap()
  let doc = parsed.0
  let issues = parsed.1
  println("issues=\{issues.length()}")
  let objects = @stix.document_objects(doc)
  println("objects=\{objects.length()}")
  for i = 0; i < objects.length(); i = i + 1 {
    let obj = objects[i]
    println("\{obj.stix_type} \{obj.id}")
  }
  println(@stix.stringify_document(doc))
}
