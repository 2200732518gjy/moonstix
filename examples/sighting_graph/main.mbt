///|
fn graph_json() -> String {
  "{\"type\":\"bundle\",\"id\":\"bundle--00000000-0000-4000-8000-000000000002\",\"objects\":[" +
  "{\"type\":\"file\",\"spec_version\":\"2.1\",\"id\":\"file--e9a0f947-b0cf-4e0c-95ed-3c92d4374835\",\"name\":\"dropper.exe\",\"hashes\":{\"SHA-256\":\"aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f\"}}," +
  "{\"type\":\"observed-data\",\"spec_version\":\"2.1\",\"id\":\"observed-data--b67d7432-e4de-411a-9e73-10f79adb4ad0\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"first_observed\":\"2024-01-01T00:00:00Z\",\"last_observed\":\"2024-01-01T00:05:00Z\",\"number_observed\":3,\"object_refs\":[\"file--e9a0f947-b0cf-4e0c-95ed-3c92d4374835\"]}," +
  "{\"type\":\"indicator\",\"spec_version\":\"2.1\",\"id\":\"indicator--8e2e2d2b-17d4-4cbf-938f-98ee46b3cd3f\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"name\":\"dropper hash\",\"pattern\":\"[file:hashes.'SHA-256' = 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f']\",\"pattern_type\":\"stix\",\"valid_from\":\"2024-01-01T00:00:00Z\"}," +
  "{\"type\":\"sighting\",\"spec_version\":\"2.1\",\"id\":\"sighting--ee20065d-2555-424f-ad9e-0f8424083eb8\",\"created\":\"2024-01-01T00:00:00.000Z\",\"modified\":\"2024-01-01T00:00:00.000Z\",\"count\":3,\"sighting_of_ref\":\"indicator--8e2e2d2b-17d4-4cbf-938f-98ee46b3cd3f\",\"observed_data_refs\":[\"observed-data--b67d7432-e4de-411a-9e73-10f79adb4ad0\"]}" +
  "]}"
}

///|
fn main raise {
  let parsed = @stix.parse_and_validate(graph_json()).unwrap()
  let issues = parsed.1
  println("issues=\{issues.length()}")
  let objects = @stix.document_objects(parsed.0)
  let mut files = 0
  let mut sightings = 0
  for i = 0; i < objects.length(); i = i + 1 {
    if objects[i].stix_type == "file" {
      files += 1
    }
    if objects[i].stix_type == "sighting" {
      sightings += 1
    }
  }
  println("files=\{files}")
  println("sightings=\{sightings}")
  if issues.length() != 0 || files != 1 || sightings != 1 {
    assert_true(false)
  }
}
