///|
fn sro_meta_specs() -> Array[TypeSpec] {
  [
    spec(
      "relationship",
      Sro,
      merge_fields(common_sro_fields(), [
        field("relationship_type", true, String),
        field("description", false, String),
        field("source_ref", true, Identifier),
        field("target_ref", true, Identifier),
        field("start_time", false, Timestamp),
        field("stop_time", false, Timestamp),
      ]),
      [],
    ),
    spec(
      "sighting",
      Sro,
      merge_fields(common_sro_fields(), [
        field("description", false, String),
        field("first_seen", false, Timestamp),
        field("last_seen", false, Timestamp),
        field("count", false, NonNegativeInteger),
        field("sighting_of_ref", true, Identifier),
        field("observed_data_refs", false, IdentifierListOf("observed-data")),
        field("where_sighted_refs", false, IdentifierList),
        field("summary", false, Boolean),
      ]),
      [],
    ),
    spec(
      "marking-definition",
      Meta,
      [
        field("type", true, String),
        field("spec_version", false, String),
        field("id", true, Identifier),
        field("created_by_ref", false, IdentifierOf("identity")),
        field("created", true, Timestamp),
        field("external_references", false, ExternalReferences),
        field(
          "object_marking_refs",
          false,
          IdentifierListOf("marking-definition"),
        ),
        field("granular_markings", false, GranularMarkings),
        field("definition_type", true, String),
        field("name", false, String),
        field("definition", true, Dictionary),
      ],
      [],
    ),
    spec(
      "language-content",
      Meta,
      merge_fields(common_sdo_fields(), [
        field("object_ref", true, Identifier),
        field("object_modified", false, Timestamp),
        field("contents", true, Dictionary),
      ]),
      [],
    ),
    spec(
      "extension-definition",
      Meta,
      merge_fields(common_sdo_fields(), [
        field("name", true, String),
        field("description", false, String),
        field("schema", true, String),
        field("version", true, String),
        field("extension_types", true, StringList),
        field("extension_properties", false, StringList),
      ]),
      [],
    ),
    spec(
      "bundle",
      Bundle,
      [
        field("type", true, String),
        field("id", true, Identifier),
        field("objects", false, ObjectList),
      ],
      [],
    ),
  ]
}

///|
fn custom_type_spec(type_name : String) -> TypeSpec {
  spec(type_name, Custom, common_sdo_fields(), [])
}
