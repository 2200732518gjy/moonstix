///|
fn validate_shape(
  value : Json,
  shape : ValueShape,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match shape {
    String => expect_string_value(value, path, issues)
    Boolean => expect_bool_value(value, path, issues)
    Integer =>
      match as_int(value) {
        None => type_mismatch(path, "integer", value, issues)
        Some(_) => ()
      }
    NonNegativeInteger =>
      match as_int(value) {
        None => type_mismatch(path, "non-negative integer", value, issues)
        Some(number) =>
          if number < 0 {
            issues.push(issue("range", path, "expected a non-negative integer"))
          }
      }
    Timestamp =>
      match as_string(value) {
        None => type_mismatch(path, "timestamp string", value, issues)
        Some(text) =>
          match parse_timestamp(text) {
            Ok(_) => ()
            Err(err) => issues.push(issue("timestamp", path, err))
          }
      }
    Identifier => validate_identifier(value, path, None, issues)
    IdentifierOf(expected) =>
      validate_identifier(value, path, Some(expected), issues)
    StringList => validate_string_list(value, path, issues)
    IdentifierList => validate_identifier_list(value, path, None, issues)
    IdentifierListOf(expected) =>
      validate_identifier_list(value, path, Some(expected), issues)
    OpenVocab(vocab) => validate_open_vocab(value, path, vocab, issues)
    ClosedVocab(vocab) => validate_closed_vocab(value, path, vocab, issues)
    OpenVocabList(vocab) => validate_open_vocab_list(value, path, vocab, issues)
    Hashes => validate_hashes(value, path, issues)
    Dictionary =>
      match as_object(value) {
        None => type_mismatch(path, "object", value, issues)
        Some(_) => ()
      }
    ObjectList => validate_object_list(value, path, issues)
    ExternalReferences => validate_external_references(value, path, issues)
    KillChainPhases => validate_kill_chain_phases(value, path, issues)
    GranularMarkings => validate_granular_markings(value, path, issues)
    Extensions => validate_extensions(value, path, issues)
    Pattern =>
      match as_string(value) {
        None => type_mismatch(path, "pattern string", value, issues)
        Some(text) =>
          if text.length() == 0 {
            issues.push(issue("empty", path, "pattern must not be empty"))
          }
      }
    HexBinary =>
      match as_string(value) {
        None => type_mismatch(path, "hex string", value, issues)
        Some(text) =>
          if !valid_hex_binary(text) {
            issues.push(issue("hex", path, "expected even-length hex"))
          }
      }
    IPv4 =>
      match as_string(value) {
        None => type_mismatch(path, "IPv4 string", value, issues)
        Some(text) =>
          if !valid_ipv4(text) {
            issues.push(issue("ipv4", path, "invalid IPv4 address or CIDR"))
          }
      }
    IPv6 =>
      match as_string(value) {
        None => type_mismatch(path, "IPv6 string", value, issues)
        Some(text) =>
          if !valid_ipv6(text) {
            issues.push(issue("ipv6", path, "invalid IPv6 address or CIDR"))
          }
      }
    Mac =>
      match as_string(value) {
        None => type_mismatch(path, "MAC string", value, issues)
        Some(text) =>
          if !valid_mac(text) {
            issues.push(issue("mac", path, "invalid MAC address"))
          }
      }
    Email =>
      match as_string(value) {
        None => type_mismatch(path, "email string", value, issues)
        Some(text) =>
          if !valid_email(text) {
            issues.push(issue("email", path, "invalid email address"))
          }
      }
    Url =>
      match as_string(value) {
        None => type_mismatch(path, "URL string", value, issues)
        Some(text) =>
          if !valid_url(text) {
            issues.push(issue("url", path, "invalid URL"))
          }
      }
    Any => ()
  }
}

///|
fn type_mismatch(
  path : String,
  expected : String,
  value : Json,
  issues : Array[Issue],
) -> Unit {
  issues.push(
    issue(
      "type",
      path,
      "expected \{expected} but found \{json_kind_name(value)}",
    ),
  )
}

///|
fn expect_string_value(
  value : Json,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match as_string(value) {
    None => type_mismatch(path, "string", value, issues)
    Some(text) =>
      if text.length() == 0 {
        issues.push(issue("empty", path, "string must not be empty"))
      }
  }
}

///|
fn expect_bool_value(
  value : Json,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match as_bool(value) {
    None => type_mismatch(path, "boolean", value, issues)
    Some(_) => ()
  }
}

///|
fn validate_identifier(
  value : Json,
  path : String,
  expected : String?,
  issues : Array[Issue],
) -> Unit {
  match as_string(value) {
    None => type_mismatch(path, "STIX identifier", value, issues)
    Some(text) =>
      match parse_stix_id(text) {
        Err(err) => issues.push(issue("id", path, err))
        Ok(parsed) =>
          match expected {
            None => ()
            Some(type_name) =>
              if !id_type_matches(parsed, type_name) {
                issues.push(
                  issue(
                    "id-type",
                    path,
                    "identifier type \{parsed.type_name} does not match \{type_name}",
                  ),
                )
              }
          }
      }
  }
}

///|
fn validate_string_list(
  value : Json,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match as_array(value) {
    None => type_mismatch(path, "string array", value, issues)
    Some(items) => {
      if items.length() == 0 {
        issues.push(issue("empty", path, "array must not be empty"))
      }
      for i = 0; i < items.length(); i = i + 1 {
        expect_string_value(items[i], index_path(path, i), issues)
      }
    }
  }
}

///|
fn validate_identifier_list(
  value : Json,
  path : String,
  expected : String?,
  issues : Array[Issue],
) -> Unit {
  match as_array(value) {
    None => type_mismatch(path, "identifier array", value, issues)
    Some(items) => {
      if items.length() == 0 {
        issues.push(issue("empty", path, "identifier array must not be empty"))
      }
      for i = 0; i < items.length(); i = i + 1 {
        validate_identifier(items[i], index_path(path, i), expected, issues)
      }
    }
  }
}

///|
fn validate_open_vocab(
  value : Json,
  path : String,
  vocab : String,
  issues : Array[Issue],
) -> Unit {
  match as_string(value) {
    None => type_mismatch(path, "string", value, issues)
    Some(text) =>
      if !is_open_vocab_value(text) {
        issues.push(issue("vocab", path, "open vocabulary value is empty"))
      } else {
        ignore_vocab_name(vocab)
      }
  }
}

///|
fn validate_closed_vocab(
  value : Json,
  path : String,
  vocab : String,
  issues : Array[Issue],
) -> Unit {
  match as_string(value) {
    None => type_mismatch(path, "string", value, issues)
    Some(text) =>
      if !vocab_contains(vocab, text) {
        issues.push(
          issue("vocab", path, "value is not in closed vocabulary \{vocab}"),
        )
      }
  }
}

///|
fn validate_open_vocab_list(
  value : Json,
  path : String,
  vocab : String,
  issues : Array[Issue],
) -> Unit {
  match as_array(value) {
    None => type_mismatch(path, "string array", value, issues)
    Some(items) => {
      if items.length() == 0 {
        issues.push(issue("empty", path, "vocabulary array must not be empty"))
      }
      for i = 0; i < items.length(); i = i + 1 {
        validate_open_vocab(items[i], index_path(path, i), vocab, issues)
      }
    }
  }
}

///|
fn validate_hashes(value : Json, path : String, issues : Array[Issue]) -> Unit {
  match as_object(value) {
    None => type_mismatch(path, "hash object", value, issues)
    Some(fields) => {
      let mut count = 0
      fields.each(fn(key, item) {
        count += 1
        if !is_open_vocab_value(key) {
          issues.push(
            issue("hash-key", join_path(path, key), "hash algorithm is empty"),
          )
        } else if !vocab_contains("hash-algorithm-ov", key) {
          issues.push(
            issue(
              "hash-key",
              join_path(path, key),
              "hash algorithm is not in hash-algorithm-ov",
            ),
          )
        }
        match as_string(item) {
          None =>
            type_mismatch(join_path(path, key), "hash string", item, issues)
          Some(text) =>
            if text.length() == 0 {
              issues.push(
                issue("empty", join_path(path, key), "hash value is empty"),
              )
            } else if key != "SSDEEP" &&
              key != "TLSH" &&
              !valid_hex_binary(text) {
              issues.push(
                issue(
                  "hash-value",
                  join_path(path, key),
                  "hash value must be hex",
                ),
              )
            }
        }
      })
      if count == 0 {
        issues.push(issue("empty", path, "hashes object must not be empty"))
      }
    }
  }
}

///|
fn validate_object_list(
  value : Json,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match as_array(value) {
    None => type_mismatch(path, "object array", value, issues)
    Some(items) => {
      if items.length() == 0 {
        issues.push(issue("empty", path, "object array must not be empty"))
      }
      for i = 0; i < items.length(); i = i + 1 {
        match as_object(items[i]) {
          None => type_mismatch(index_path(path, i), "object", items[i], issues)
          Some(_) => ()
        }
      }
    }
  }
}

///|
fn validate_external_references(
  value : Json,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match as_array(value) {
    None => type_mismatch(path, "external-reference array", value, issues)
    Some(items) => {
      if items.length() == 0 {
        issues.push(
          issue("empty", path, "external_references must not be empty"),
        )
      }
      for i = 0; i < items.length(); i = i + 1 {
        let item_path = index_path(path, i)
        match as_object(items[i]) {
          None => type_mismatch(item_path, "object", items[i], issues)
          Some(fields) => {
            match object_string(fields, "source_name") {
              None =>
                issues.push(
                  issue(
                    "missing",
                    join_path(item_path, "source_name"),
                    "source_name is required",
                  ),
                )
              Some(name) =>
                if name.length() == 0 {
                  issues.push(
                    issue(
                      "empty",
                      join_path(item_path, "source_name"),
                      "source_name is empty",
                    ),
                  )
                }
            }
            match object_field(fields, "url") {
              None => ()
              Some(url) =>
                validate_shape(url, Url, join_path(item_path, "url"), issues)
            }
            match object_field(fields, "hashes") {
              None => ()
              Some(hashes) =>
                validate_shape(
                  hashes,
                  Hashes,
                  join_path(item_path, "hashes"),
                  issues,
                )
            }
          }
        }
      }
    }
  }
}

///|
fn validate_kill_chain_phases(
  value : Json,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match as_array(value) {
    None => type_mismatch(path, "kill-chain array", value, issues)
    Some(items) => {
      if items.length() == 0 {
        issues.push(issue("empty", path, "kill_chain_phases must not be empty"))
      }
      for i = 0; i < items.length(); i = i + 1 {
        let item_path = index_path(path, i)
        match as_object(items[i]) {
          None => type_mismatch(item_path, "object", items[i], issues)
          Some(fields) => {
            match object_string(fields, "kill_chain_name") {
              None =>
                issues.push(
                  issue(
                    "missing",
                    join_path(item_path, "kill_chain_name"),
                    "kill_chain_name is required",
                  ),
                )
              Some(name) =>
                if name.length() == 0 {
                  issues.push(
                    issue(
                      "empty",
                      join_path(item_path, "kill_chain_name"),
                      "empty",
                    ),
                  )
                }
            }
            match object_string(fields, "phase_name") {
              None =>
                issues.push(
                  issue(
                    "missing",
                    join_path(item_path, "phase_name"),
                    "phase_name is required",
                  ),
                )
              Some(name) =>
                if name.length() == 0 {
                  issues.push(
                    issue("empty", join_path(item_path, "phase_name"), "empty"),
                  )
                }
            }
          }
        }
      }
    }
  }
}

///|
fn validate_granular_markings(
  value : Json,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match as_array(value) {
    None => type_mismatch(path, "granular-marking array", value, issues)
    Some(items) => {
      if items.length() == 0 {
        issues.push(issue("empty", path, "granular_markings must not be empty"))
      }
      for i = 0; i < items.length(); i = i + 1 {
        let item_path = index_path(path, i)
        match as_object(items[i]) {
          None => type_mismatch(item_path, "object", items[i], issues)
          Some(fields) => {
            match object_field(fields, "selectors") {
              None =>
                issues.push(
                  issue(
                    "missing",
                    join_path(item_path, "selectors"),
                    "selectors is required",
                  ),
                )
              Some(selectors) =>
                validate_string_list(
                  selectors,
                  join_path(item_path, "selectors"),
                  issues,
                )
            }
            let has_marking = match object_field(fields, "marking_ref") {
              None => false
              Some(marking) => {
                validate_identifier(
                  marking,
                  join_path(item_path, "marking_ref"),
                  Some("marking-definition"),
                  issues,
                )
                true
              }
            }
            let has_lang = match object_string(fields, "lang") {
              None => false
              Some(_) => true
            }
            if !has_marking && !has_lang {
              issues.push(
                issue(
                  "require-any", item_path, "granular marking needs marking_ref or lang",
                ),
              )
            }
          }
        }
      }
    }
  }
}

///|
fn validate_extensions(
  value : Json,
  path : String,
  issues : Array[Issue],
) -> Unit {
  match as_object(value) {
    None => type_mismatch(path, "extensions object", value, issues)
    Some(fields) => {
      let mut count = 0
      fields.each(fn(key, item) {
        count += 1
        if key.length() == 0 {
          issues.push(issue("empty", path, "extension key is empty"))
        }
        match as_object(item) {
          None => type_mismatch(join_path(path, key), "object", item, issues)
          Some(_) => ()
        }
      })
      if count == 0 {
        issues.push(issue("empty", path, "extensions object must not be empty"))
      }
    }
  }
}

///|
fn ignore_vocab_name(name : String) -> Unit {
  let _values = vocab_values(name)
  ()
}
