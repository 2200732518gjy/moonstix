///|
/// Parse JSON and collect STIX validation issues.
pub fn parse_and_validate(
  text : String,
) -> Result[(Document, Array[Issue]), StixError] {
  let doc = match parse_document(text) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  Ok((doc, validate_document(doc)))
}

///|
pub fn validate_document(doc : Document) -> Array[Issue] {
  let issues : Array[Issue] = []
  match doc {
    Object(obj) => validate_object(obj, "", issues)
    Bundle(bundle) => validate_bundle(bundle, issues)
  }
  issues
}

///|
fn validate_bundle(bundle : StixBundle, issues : Array[Issue]) -> Unit {
  match parse_stix_id(bundle.id) {
    Err(err) => issues.push(issue("id", "id", err))
    Ok(parsed) =>
      if parsed.type_name != "bundle" {
        issues.push(issue("id-type", "id", "bundle id must use type 'bundle'"))
      }
  }
  let seen : Map[String, Int] = Map([])
  for i = 0; i < bundle.objects.length(); i = i + 1 {
    let obj = bundle.objects[i]
    let path = index_path("objects", i)
    if obj.stix_type == "bundle" {
      issues.push(
        issue("nested-bundle", path, "bundle must not contain another bundle"),
      )
    }
    validate_object(obj, path, issues)
    if obj.id.length() > 0 {
      match seen.get(obj.id) {
        Some(prev) =>
          issues.push(
            issue(
              "duplicate-id",
              path,
              "id \{obj.id} already appears at \{index_path("objects", prev)}",
            ),
          )
        None => seen.set(obj.id, i)
      }
    }
  }
  check_bundle_refs(bundle, seen, issues)
}

///|
fn check_bundle_refs(
  bundle : StixBundle,
  seen : Map[String, Int],
  issues : Array[Issue],
) -> Unit {
  for i = 0; i < bundle.objects.length(); i = i + 1 {
    let obj = bundle.objects[i]
    let path = index_path("objects", i)
    collect_ref_strings(obj.properties, path, seen, issues)
  }
}

///|
fn collect_ref_strings(
  fields : Map[String, Json],
  path : String,
  seen : Map[String, Int],
  issues : Array[Issue],
) -> Unit {
  fields.each(fn(key, value) {
    check_ref_json(value, join_path(path, key), key, seen, issues)
  })
}

///|
fn check_ref_json(
  value : Json,
  path : String,
  key : String,
  seen : Map[String, Int],
  issues : Array[Issue],
) -> Unit {
  if key.has_suffix("_ref") ||
    key.has_suffix("_refs") ||
    key == "object_refs" ||
    key == "sample_refs" ||
    key == "sighting_of_ref" {
    match as_string(value) {
      Some(text) => note_unresolved(text, path, seen, issues)
      None =>
        match as_array(value) {
          None => ()
          Some(items) =>
            for i = 0; i < items.length(); i = i + 1 {
              match as_string(items[i]) {
                Some(text) =>
                  note_unresolved(text, index_path(path, i), seen, issues)
                None => ()
              }
            }
        }
    }
  } else {
    match as_object(value) {
      Some(fields) => collect_ref_strings(fields, path, seen, issues)
      None =>
        match as_array(value) {
          None => ()
          Some(items) =>
            for i = 0; i < items.length(); i = i + 1 {
              check_ref_json(items[i], index_path(path, i), key, seen, issues)
            }
        }
    }
  }
}

///|
fn note_unresolved(
  id : String,
  path : String,
  seen : Map[String, Int],
  issues : Array[Issue],
) -> Unit {
  match parse_stix_id(id) {
    Err(_) => ()
    Ok(_) =>
      if !seen.contains(id) {
        issues.push(
          issue(
            "unresolved-ref",
            path,
            "identifier \{id} is not in this bundle",
          ),
        )
      }
  }
}

///|
fn validate_object(
  obj : StixObject,
  path : String,
  issues : Array[Issue],
) -> Unit {
  if obj.stix_type.length() == 0 {
    issues.push(issue("missing", join_path(path, "type"), "type is required"))
    return
  }
  if !valid_stix_type_name(obj.stix_type) {
    issues.push(
      issue("type-name", join_path(path, "type"), "invalid STIX type name"),
    )
  }
  let spec = match lookup_type_spec(obj.stix_type) {
    Some(item) => item
    None => custom_type_spec(obj.stix_type)
  }
  match object_string(obj.properties, "type") {
    None =>
      issues.push(issue("missing", join_path(path, "type"), "type is required"))
    Some(text) =>
      if text != obj.stix_type {
        issues.push(
          issue(
            "type",
            join_path(path, "type"),
            "type field does not match object type",
          ),
        )
      }
  }
  match object_string(obj.properties, "id") {
    None =>
      issues.push(issue("missing", join_path(path, "id"), "id is required"))
    Some(text) =>
      match parse_stix_id(text) {
        Err(err) => issues.push(issue("id", join_path(path, "id"), err))
        Ok(parsed) =>
          if parsed.type_name != obj.stix_type {
            issues.push(
              issue(
                "id-type",
                join_path(path, "id"),
                "id prefix \{parsed.type_name} does not match type \{obj.stix_type}",
              ),
            )
          }
      }
  }
  match object_string(obj.properties, "spec_version") {
    None => ()
    Some(version) =>
      if version != "2.1" && version != "2.0" {
        issues.push(
          issue(
            "spec-version",
            join_path(path, "spec_version"),
            "unsupported spec_version \{version}",
          ),
        )
      }
  }
  spec.fields.each(fn(field) {
    match object_field(obj.properties, field.name) {
      None =>
        if field.required {
          issues.push(
            issue(
              "missing",
              join_path(path, field.name),
              "\{field.name} is required",
            ),
          )
        }
      Some(value) =>
        validate_shape(value, field.shape, join_path(path, field.name), issues)
    }
  })
  obj.properties.each(fn(key, _value) {
    match field_by_name(spec, key) {
      Some(_) => ()
      None =>
        issues.push(
          issue(
            "unknown-property",
            join_path(path, key),
            "property is not in the \{spec.type_name} table",
          ),
        )
    }
  })
  if spec.require_any.length() > 0 {
    let mut found = false
    spec.require_any.each(fn(name) {
      match object_field(obj.properties, name) {
        Some(_) => found = true
        None => ()
      }
    })
    if !found {
      issues.push(
        issue(
          "require-any",
          path,
          "\{spec.type_name} needs one of \{join_names(spec.require_any)}",
        ),
      )
    }
  }
  extra_object_rules(obj, path, issues)
}

///|
fn join_names(names : Array[String]) -> String {
  let mut out = ""
  for i = 0; i < names.length(); i = i + 1 {
    if i == 0 {
      out = names[i]
    } else {
      out = "\{out}, \{names[i]}"
    }
  }
  out
}

///|
fn extra_object_rules(
  obj : StixObject,
  path : String,
  issues : Array[Issue],
) -> Unit {
  check_created_modified(obj, path, issues)
  match obj.stix_type {
    "indicator" => extra_indicator(obj, path, issues)
    "malware" => extra_malware(obj, path, issues)
    "location" => extra_location(obj, path, issues)
    "artifact" => extra_artifact(obj, path, issues)
    "relationship" => extra_relationship(obj, path, issues)
    "sighting" => extra_sighting(obj, path, issues)
    "observed-data" => extra_observed_data(obj, path, issues)
    "network-traffic" => extra_network_traffic(obj, path, issues)
    "marking-definition" => extra_marking(obj, path, issues)
    "file" => extra_file(obj, path, issues)
    "campaign" | "infrastructure" | "intrusion-set" | "threat-actor" =>
      extra_first_last_seen(obj, path, issues)
    _ => ()
  }
  match object_field(obj.properties, "confidence") {
    None => ()
    Some(value) =>
      match as_int(value) {
        None => ()
        Some(number) =>
          if number > 100 {
            issues.push(
              issue(
                "range",
                join_path(path, "confidence"),
                "confidence must be 0-100",
              ),
            )
          }
      }
  }
}

///|
fn check_created_modified(
  obj : StixObject,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match
    (
      object_string(obj.properties, "created"),
      object_string(obj.properties, "modified"),
    ) {
    (Some(created_text), Some(modified_text)) =>
      match (parse_timestamp(created_text), parse_timestamp(modified_text)) {
        (Ok(created), Ok(modified)) =>
          if timestamp_compare(created, modified) > 0 {
            issues.push(
              issue(
                "order",
                join_path(path, "modified"),
                "modified is earlier than created",
              ),
            )
          }
        _ => ()
      }
    _ => ()
  }
}

///|
fn extra_first_last_seen(
  obj : StixObject,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match
    (
      object_string(obj.properties, "first_seen"),
      object_string(obj.properties, "last_seen"),
    ) {
    (Some(first_text), Some(last_text)) =>
      match (parse_timestamp(first_text), parse_timestamp(last_text)) {
        (Ok(first), Ok(last)) =>
          if timestamp_compare(first, last) > 0 {
            issues.push(
              issue(
                "order",
                join_path(path, "last_seen"),
                "last_seen is earlier than first_seen",
              ),
            )
          }
        _ => ()
      }
    _ => ()
  }
}

///|
fn extra_indicator(
  obj : StixObject,
  path : String,
  issues : Array[Issue],
) -> Unit {
  let pattern_type = match object_string(obj.properties, "pattern_type") {
    None => "stix"
    Some(text) => text
  }
  match object_string(obj.properties, "pattern") {
    None => ()
    Some(text) =>
      if pattern_type == "stix" {
        match parse_pattern(text) {
          Err(err) =>
            issues.push(issue("pattern", join_path(path, "pattern"), err))
          Ok(expr) => {
            let path_issues = validate_pattern_paths(expr)
            path_issues.each(fn(item) {
              issues.push(
                issue(item.code, join_path(path, "pattern"), item.message),
              )
            })
          }
        }
      }
  }
  match
    (
      object_string(obj.properties, "valid_from"),
      object_string(obj.properties, "valid_until"),
    ) {
    (Some(from_text), Some(until_text)) =>
      match (parse_timestamp(from_text), parse_timestamp(until_text)) {
        (Ok(from), Ok(until)) =>
          if timestamp_compare(from, until) > 0 {
            issues.push(
              issue(
                "order",
                join_path(path, "valid_until"),
                "valid_until is earlier than valid_from",
              ),
            )
          }
        _ => ()
      }
    _ => ()
  }
}

///|
fn extra_malware(
  obj : StixObject,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match object_bool(obj.properties, "is_family") {
    Some(true) =>
      match object_string(obj.properties, "name") {
        None =>
          issues.push(
            issue(
              "missing",
              join_path(path, "name"),
              "malware family requires name",
            ),
          )
        Some(_) => ()
      }
    _ => ()
  }
}

///|
fn extra_location(
  obj : StixObject,
  path : String,
  issues : Array[Issue],
) -> Unit {
  let lat = object_field(obj.properties, "latitude")
  let lon = object_field(obj.properties, "longitude")
  match (lat, lon) {
    (Some(_), None) =>
      issues.push(
        issue(
          "pair",
          join_path(path, "longitude"),
          "longitude is required with latitude",
        ),
      )
    (None, Some(_)) =>
      issues.push(
        issue(
          "pair",
          join_path(path, "latitude"),
          "latitude is required with longitude",
        ),
      )
    (Some(lat_value), Some(lon_value)) => {
      check_number_range(
        lat_value,
        join_path(path, "latitude"),
        -90.0,
        90.0,
        issues,
      )
      check_number_range(
        lon_value,
        join_path(path, "longitude"),
        -180.0,
        180.0,
        issues,
      )
    }
    (None, None) => ()
  }
}

///|
fn extra_artifact(
  obj : StixObject,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match
    (
      object_field(obj.properties, "payload_bin"),
      object_field(obj.properties, "url"),
    ) {
    (Some(_), Some(_)) =>
      issues.push(
        issue("mutex", path, "artifact must not set both payload_bin and url"),
      )
    _ => ()
  }
}

///|
fn extra_relationship(
  obj : StixObject,
  path : String,
  issues : Array[Issue],
) -> Unit {
  let rel = match object_string(obj.properties, "relationship_type") {
    None => return
    Some(text) => text
  }
  if !is_common_relationship_type(rel) {
    issues.push(
      issue(
        "relationship-type",
        join_path(path, "relationship_type"),
        "uncommon relationship_type \{rel}",
      ),
    )
  }
  let source = match object_string(obj.properties, "source_ref") {
    None => return
    Some(text) => text
  }
  let target = match object_string(obj.properties, "target_ref") {
    None => return
    Some(text) => text
  }
  match (parse_stix_id(source), parse_stix_id(target)) {
    (Ok(src), Ok(dst)) =>
      if !relationship_allowed(src.type_name, rel, dst.type_name) {
        issues.push(
          issue(
            "relationship-constraint",
            path,
            "\{src.type_name} \{rel} \{dst.type_name} is not in the STIX 2.1 table",
          ),
        )
      }
    _ => ()
  }
  match
    (
      object_string(obj.properties, "start_time"),
      object_string(obj.properties, "stop_time"),
    ) {
    (Some(start_text), Some(stop_text)) =>
      match (parse_timestamp(start_text), parse_timestamp(stop_text)) {
        (Ok(start), Ok(stop)) =>
          if timestamp_compare(start, stop) > 0 {
            issues.push(
              issue(
                "order",
                join_path(path, "stop_time"),
                "stop_time is earlier than start_time",
              ),
            )
          }
        _ => ()
      }
    _ => ()
  }
}

///|
fn extra_sighting(
  obj : StixObject,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match object_string(obj.properties, "sighting_of_ref") {
    None => ()
    Some(text) =>
      match parse_stix_id(text) {
        Err(_) => ()
        Ok(parsed) =>
          if object_kind_of(parsed.type_name) == Sco {
            issues.push(
              issue(
                "sighting-target",
                join_path(path, "sighting_of_ref"),
                "sighting_of_ref should reference an SDO, not an SCO",
              ),
            )
          }
      }
  }
  match object_field(obj.properties, "count") {
    None => ()
    Some(value) =>
      match as_int(value) {
        None => ()
        Some(number) =>
          if number > 999999999 {
            issues.push(
              issue(
                "range",
                join_path(path, "count"),
                "sighting count exceeds 999999999",
              ),
            )
          }
      }
  }
  extra_first_last_seen(obj, path, issues)
}

///|
fn extra_observed_data(
  obj : StixObject,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match object_field(obj.properties, "number_observed") {
    None => ()
    Some(value) =>
      match as_int(value) {
        None => ()
        Some(number) =>
          if number < 1 {
            issues.push(
              issue(
                "range",
                join_path(path, "number_observed"),
                "number_observed must be >= 1",
              ),
            )
          }
      }
  }
  match
    (
      object_string(obj.properties, "first_observed"),
      object_string(obj.properties, "last_observed"),
    ) {
    (Some(first_text), Some(last_text)) =>
      match (parse_timestamp(first_text), parse_timestamp(last_text)) {
        (Ok(first), Ok(last)) =>
          if timestamp_compare(first, last) > 0 {
            issues.push(
              issue(
                "order",
                join_path(path, "last_observed"),
                "last_observed is earlier than first_observed",
              ),
            )
          }
        _ => ()
      }
    _ => ()
  }
}

///|
fn extra_network_traffic(
  obj : StixObject,
  path : String,
  issues : Array[Issue],
) -> Unit {
  check_port(obj, path, "src_port", issues)
  check_port(obj, path, "dst_port", issues)
  match
    (
      object_string(obj.properties, "start"),
      object_string(obj.properties, "end"),
    ) {
    (Some(start_text), Some(end_text)) =>
      match (parse_timestamp(start_text), parse_timestamp(end_text)) {
        (Ok(start), Ok(end)) =>
          if timestamp_compare(start, end) > 0 {
            issues.push(
              issue(
                "order",
                join_path(path, "end"),
                "end is earlier than start",
              ),
            )
          }
        _ => ()
      }
    _ => ()
  }
}

///|
fn extra_marking(
  obj : StixObject,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match object_string(obj.properties, "definition_type") {
    Some("tlp") | Some("statement") => ()
    Some(text) =>
      if !text.has_prefix("x-") {
        issues.push(
          issue(
            "marking-type",
            join_path(path, "definition_type"),
            "definition_type should be tlp, statement, or a custom x-* type",
          ),
        )
      }
    None => ()
  }
}

///|
fn extra_file(obj : StixObject, path : String, issues : Array[Issue]) -> Unit {
  match object_field(obj.properties, "size") {
    None => ()
    Some(value) =>
      match as_int(value) {
        None => ()
        Some(number) =>
          if number < 0 {
            issues.push(
              issue("range", join_path(path, "size"), "file size must be >= 0"),
            )
          }
      }
  }
}

///|
fn check_port(
  obj : StixObject,
  path : String,
  name : String,
  issues : Array[Issue],
) -> Unit {
  match object_field(obj.properties, name) {
    None => ()
    Some(value) =>
      match as_int(value) {
        None => ()
        Some(number) =>
          if number > 65535 {
            issues.push(
              issue("range", join_path(path, name), "port must be 0-65535"),
            )
          }
      }
  }
}

///|
fn check_number_range(
  value : Json,
  path : String,
  min : Double,
  max : Double,
  issues : Array[Issue],
) -> Unit {
  match value {
    Number(number, ..) =>
      if number < min || number > max {
        issues.push(issue("range", path, "number is out of range"))
      }
    _ => type_mismatch(path, "number", value, issues)
  }
}

///|
fn timestamp_compare(left : Timestamp, right : Timestamp) -> Int {
  let a = timestamp_key(left)
  let b = timestamp_key(right)
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn timestamp_key(ts : Timestamp) -> Int64 {
  let minutes = (
      (ts.year.to_int64() * 12L + ts.month.to_int64()) * 32L + ts.day.to_int64()
    ) *
    24L *
    60L +
    ts.hour.to_int64() * 60L +
    ts.minute.to_int64() -
    ts.offset_minutes.to_int64()
  minutes * 60L + ts.second.to_int64()
}
