///|
/// One STIX object, including custom `x-*` types.
pub(all) struct StixObject {
  stix_type : String
  id : String
  spec_version : String
  kind : ObjectKind
  properties : Map[String, Json]
  raw : Json
} derive(Debug)

///|
/// Bundle of STIX objects.
pub(all) struct StixBundle {
  id : String
  objects : Array[StixObject]
  raw : Json
} derive(Debug)

///|
/// A document is either a bundle or a single object.
pub(all) enum Document {
  Bundle(StixBundle)
  Object(StixObject)
} derive(Debug)

///|
pub fn parse_document(text : String) -> Result[Document, StixError] {
  let json = match parse_json_text(text) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  parse_document_json(json)
}

///|
pub fn parse_document_json(value : Json) -> Result[Document, StixError] {
  let fields = match as_object(value) {
    Some(map) => map
    None => return Err(NotObject)
  }
  match object_string(fields, "type") {
    Some("bundle") =>
      match parse_bundle(value, fields) {
        Ok(bundle) => Ok(Bundle(bundle))
        Err(err) => Err(err)
      }
    Some(_) =>
      match parse_stix_object(value, "") {
        Ok(obj) => Ok(Object(obj))
        Err(err) => Err(err)
      }
    None => Err(UnexpectedRoot("missing type"))
  }
}

///|
fn parse_bundle(
  raw : Json,
  fields : Map[String, Json],
) -> Result[StixBundle, StixError] {
  let id = match object_string(fields, "id") {
    Some(text) => text
    None => ""
  }
  let objects : Array[StixObject] = []
  match object_field(fields, "objects") {
    None => ()
    Some(Null) => ()
    Some(value) =>
      match as_array(value) {
        None => return Err(UnexpectedRoot("bundle.objects must be an array"))
        Some(items) =>
          for i = 0; i < items.length(); i = i + 1 {
            match parse_stix_object(items[i], index_path("objects", i)) {
              Ok(obj) => objects.push(obj)
              Err(err) => return Err(err)
            }
          }
      }
  }
  Ok({ id, objects, raw, })
}

///|
fn parse_stix_object(
  raw : Json,
  _path : String,
) -> Result[StixObject, StixError] {
  let fields = match as_object(raw) {
    Some(map) => map
    None => return Err(NotObject)
  }
  let stix_type = match object_string(fields, "type") {
    Some(text) => text
    None => ""
  }
  let id = match object_string(fields, "id") {
    Some(text) => text
    None => ""
  }
  let spec_version = match object_string(fields, "spec_version") {
    Some(text) => text
    None => "2.1"
  }
  let kind = object_kind_of(stix_type)
  Ok({
    stix_type,
    id,
    spec_version,
    kind,
    properties: json_clone_object(fields),
    raw,
  })
}

///|
pub fn document_objects(doc : Document) -> Array[StixObject] {
  match doc {
    Bundle(bundle) => bundle.objects
    Object(obj) => [obj]
  }
}

///|
pub fn stringify_document(doc : Document) -> String {
  match doc {
    Bundle(bundle) => stringify_json(bundle.raw)
    Object(obj) => stringify_json(obj.raw)
  }
}
