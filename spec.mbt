///|
/// High-level STIX object family.
pub(all) enum ObjectKind {
  Sdo
  Sro
  Sco
  Meta
  Bundle
  Custom
} derive(Eq, Debug)

///|
/// Expected JSON shape of one property.
pub(all) enum ValueShape {
  String
  Boolean
  Integer
  NonNegativeInteger
  Timestamp
  Identifier
  IdentifierOf(String)
  StringList
  IdentifierList
  IdentifierListOf(String)
  OpenVocab(String)
  ClosedVocab(String)
  OpenVocabList(String)
  Hashes
  Dictionary
  ObjectList
  ExternalReferences
  KillChainPhases
  GranularMarkings
  Extensions
  Pattern
  HexBinary
  IPv4
  IPv6
  Mac
  Email
  Url
  Any
} derive(Eq, Debug)

///|
/// One named property in a type table.
pub(all) struct FieldSpec {
  name : String
  required : Bool
  shape : ValueShape
} derive(Eq, Debug)

///|
/// Per-type property table used by the validator.
pub(all) struct TypeSpec {
  type_name : String
  kind : ObjectKind
  fields : Array[FieldSpec]
  require_any : Array[String]
} derive(Eq, Debug)

///|
fn field(name : String, required : Bool, shape : ValueShape) -> FieldSpec {
  { name, required, shape, }
}

///|
fn spec(
  type_name : String,
  kind : ObjectKind,
  fields : Array[FieldSpec],
  require_any : Array[String],
) -> TypeSpec {
  { type_name, kind, fields, require_any, }
}

///|
fn common_sdo_fields() -> Array[FieldSpec] {
  [
    field("type", true, String),
    field("spec_version", false, String),
    field("id", true, Identifier),
    field("created_by_ref", false, IdentifierOf("identity")),
    field("created", true, Timestamp),
    field("modified", true, Timestamp),
    field("revoked", false, Boolean),
    field("labels", false, StringList),
    field("confidence", false, NonNegativeInteger),
    field("lang", false, String),
    field("external_references", false, ExternalReferences),
    field("object_marking_refs", false, IdentifierListOf("marking-definition")),
    field("granular_markings", false, GranularMarkings),
    field("defanged", false, Boolean),
    field("extensions", false, Extensions),
  ]
}

///|
fn common_sco_fields() -> Array[FieldSpec] {
  [
    field("type", true, String),
    field("spec_version", false, String),
    field("id", true, Identifier),
    field("object_marking_refs", false, IdentifierListOf("marking-definition")),
    field("granular_markings", false, GranularMarkings),
    field("defanged", false, Boolean),
    field("extensions", false, Extensions),
  ]
}

///|
fn common_sro_fields() -> Array[FieldSpec] {
  common_sdo_fields()
}

///|
fn merge_fields(
  base : Array[FieldSpec],
  extra : Array[FieldSpec],
) -> Array[FieldSpec] {
  let out : Array[FieldSpec] = []
  base.each(fn(item) { out.push(item) })
  extra.each(fn(item) { out.push(item) })
  out
}

///|
fn field_by_name(spec : TypeSpec, name : String) -> FieldSpec? {
  let mut found : FieldSpec? = None
  spec.fields.each(fn(item) { if item.name == name { found = Some(item) } })
  found
}

///|
pub fn lookup_type_spec(type_name : String) -> TypeSpec? {
  type_spec_map().get(type_name)
}

///|
fn type_spec_map() -> Map[String, TypeSpec] {
  let table : Map[String, TypeSpec] = Map([])
  sdo_specs().each(fn(item) { table.set(item.type_name, item) })
  sco_specs().each(fn(item) { table.set(item.type_name, item) })
  sro_meta_specs().each(fn(item) { table.set(item.type_name, item) })
  table
}

///|
pub fn known_type_names() -> Array[String] {
  let names : Array[String] = []
  type_spec_map().each(fn(key, _value) { names.push(key) })
  names
}

///|
pub fn object_kind_of(type_name : String) -> ObjectKind {
  match lookup_type_spec(type_name) {
    Some(spec) => spec.kind
    None => if type_name.has_prefix("x-") { Custom } else { Sdo }
  }
}
