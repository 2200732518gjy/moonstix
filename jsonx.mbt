///|
fn parse_json_text(text : String) -> Result[Json, StixError] {
  let parsed = @json.parse(text) catch {
    err => return Err(JsonSyntax("\{err}"))
  }
  Ok(parsed)
}

///|
fn as_object(value : Json) -> Map[String, Json]? {
  match value {
    Object(fields) => Some(fields)
    _ => None
  }
}

///|
fn as_array(value : Json) -> Array[Json]? {
  match value {
    Array(items) => Some(items)
    _ => None
  }
}

///|
fn as_string(value : Json) -> String? {
  match value {
    String(text) => Some(text)
    _ => None
  }
}

///|
fn as_bool(value : Json) -> Bool? {
  match value {
    True => Some(true)
    False => Some(false)
    _ => None
  }
}

///|
fn as_int(value : Json) -> Int? {
  match value {
    Number(number, ..) => {
      let truncated = number.to_int()
      if truncated.to_double() == number {
        Some(truncated)
      } else {
        None
      }
    }
    _ => None
  }
}

///|
fn object_field(fields : Map[String, Json], name : String) -> Json? {
  fields.get(name)
}

///|
fn object_string(fields : Map[String, Json], name : String) -> String? {
  match fields.get(name) {
    Some(value) => as_string(value)
    None => None
  }
}

///|
fn object_bool(fields : Map[String, Json], name : String) -> Bool? {
  match fields.get(name) {
    Some(value) => as_bool(value)
    None => None
  }
}

///|
fn json_kind_name(value : Json) -> String {
  match value {
    Null => "null"
    True | False => "boolean"
    Number(_) => "number"
    String(_) => "string"
    Array(_) => "array"
    Object(_) => "object"
  }
}

///|
fn json_clone_object(fields : Map[String, Json]) -> Map[String, Json] {
  let copy : Map[String, Json] = Map([])
  fields.each(fn(key, value) { copy.set(key, value) })
  copy
}

///|
fn stringify_json(value : Json) -> String {
  value.stringify()
}
