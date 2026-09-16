///|
/// Parsed STIX identifier: `<type>--<uuid>`.
pub(all) struct StixId {
  type_name : String
  uuid : String
  text : String
} derive(Eq, Debug)

///|
pub fn parse_stix_id(text : String) -> Result[StixId, String] {
  if text.length() == 0 {
    return Err("empty STIX id")
  }
  match text.find("--") {
    None => Err("STIX id must contain '--'")
    Some(idx) => {
      if idx == 0 {
        return Err("STIX id is missing a type prefix")
      }
      let type_name = slice_to(text, 0, idx)
      let uuid = slice_from(text, idx + 2)
      if !valid_stix_type_name(type_name) {
        return Err("invalid STIX type name '\{type_name}'")
      }
      if !valid_stix_uuid(uuid) {
        return Err("invalid UUID in STIX id '\{text}'")
      }
      Ok({ type_name, uuid, text, })
    }
  }
}

///|
pub fn valid_stix_type_name(name : String) -> Bool {
  if name.length() == 0 {
    return false
  }
  if name.has_prefix("x-") {
    return valid_custom_type_name(name)
  }
  match char_at(name, 0) {
    Some(ch) => if !is_ascii_id_start(ch) { return false }
    None => return false
  }
  for i = 1; i < name.length(); i = i + 1 {
    match char_at(name, i) {
      Some(ch) => if !is_ascii_id_continue(ch) { return false }
      None => return false
    }
  }
  match char_at(name, name.length() - 1) {
    Some('-') => false
    Some(_) => true
    None => false
  }
}

///|
fn valid_custom_type_name(name : String) -> Bool {
  if name.length() < 3 {
    return false
  }
  for i = 2; i < name.length(); i = i + 1 {
    match char_at(name, i) {
      Some(ch) => if !is_ascii_id_continue(ch) { return false }
      None => return false
    }
  }
  match char_at(name, name.length() - 1) {
    Some('-') => false
    Some(_) => true
    None => false
  }
}

///|
pub fn valid_stix_uuid(text : String) -> Bool {
  if text.length() != 36 {
    return false
  }
  let groups = [8, 4, 4, 4, 12]
  let mut pos = 0
  for g = 0; g < groups.length(); g = g + 1 {
    if g > 0 {
      if !char_eq(text, pos, '-') {
        return false
      }
      pos += 1
    }
    let width = groups[g]
    for _i = 0; _i < width; _i = _i + 1 {
      match char_at(text, pos) {
        Some(ch) => if !ch.is_ascii_hexdigit() { return false }
        None => return false
      }
      pos += 1
    }
  }
  pos == text.length()
}

///|
pub fn id_type_matches(id : StixId, expected : String) -> Bool {
  id.type_name == expected
}
