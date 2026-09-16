///|
/// Common STIX 2.1 relationship_type values.
pub fn common_relationship_types() -> Array[String] {
  [
    "attributed-to", "authored-by", "based-on", "beacons-to", "characterizes", "communicates-with",
    "compromises", "consists-of", "controls", "delivers", "derived-from", "downloads",
    "drops", "duplicate-of", "dynamic-analysis-of", "exfiltrates-to", "exploits",
    "has", "hosts", "impersonates", "indicates", "located-at", "mitigates", "originates-from",
    "owns", "related-to", "remediates", "static-analysis-of", "targets", "uses",
    "variant-of",
  ]
}

///|
pub fn is_common_relationship_type(name : String) -> Bool {
  common_relationship_types().contains(name) || name.has_prefix("x-")
}

///|
/// Whether a (source type, relationship, target type) triple is in the
/// built-in STIX 2.1 constraint table. `"*"` matches any type.
pub fn relationship_allowed(
  source_type : String,
  rel : String,
  target_type : String,
) -> Bool {
  if rel == "related-to" || rel.has_prefix("x-") {
    return true
  }
  if source_type.has_prefix("x-") || target_type.has_prefix("x-") {
    return true
  }
  let rules = relationship_rules()
  for i = 0; i < rules.length(); i = i + 1 {
    let rule = rules[i]
    if rule.1 == rel &&
      type_matches(rule.0, source_type) &&
      type_matches(rule.2, target_type) {
      return true
    }
  }
  false
}

///|
fn type_matches(expected : String, actual : String) -> Bool {
  if expected == "*" {
    true
  } else if expected == "sco" {
    object_kind_of(actual) == Sco
  } else if expected == "sdo" {
    object_kind_of(actual) == Sdo
  } else {
    expected == actual
  }
}

///|
fn relationship_rules() -> Array[(String, String, String)] {
  [
    ("attack-pattern", "delivers", "malware"),
    ("attack-pattern", "targets", "identity"),
    ("attack-pattern", "targets", "location"),
    ("attack-pattern", "targets", "vulnerability"),
    ("attack-pattern", "uses", "malware"),
    ("attack-pattern", "uses", "tool"),
    ("campaign", "attributed-to", "intrusion-set"),
    ("campaign", "attributed-to", "threat-actor"),
    ("campaign", "compromises", "infrastructure"),
    ("campaign", "originates-from", "location"),
    ("campaign", "targets", "identity"),
    ("campaign", "targets", "location"),
    ("campaign", "targets", "vulnerability"),
    ("campaign", "uses", "attack-pattern"),
    ("campaign", "uses", "infrastructure"),
    ("campaign", "uses", "malware"),
    ("campaign", "uses", "tool"),
    ("course-of-action", "investigates", "indicator"),
    ("course-of-action", "mitigates", "attack-pattern"),
    ("course-of-action", "mitigates", "indicator"),
    ("course-of-action", "mitigates", "malware"),
    ("course-of-action", "mitigates", "tool"),
    ("course-of-action", "mitigates", "vulnerability"),
    ("course-of-action", "remediates", "malware"),
    ("course-of-action", "remediates", "vulnerability"),
    ("domain-name", "resolves-to", "domain-name"),
    ("domain-name", "resolves-to", "ipv4-addr"),
    ("domain-name", "resolves-to", "ipv6-addr"),
    ("identity", "located-at", "location"),
    ("indicator", "based-on", "observed-data"),
    ("indicator", "indicates", "attack-pattern"),
    ("indicator", "indicates", "campaign"),
    ("indicator", "indicates", "infrastructure"),
    ("indicator", "indicates", "intrusion-set"),
    ("indicator", "indicates", "malware"),
    ("indicator", "indicates", "threat-actor"),
    ("indicator", "indicates", "tool"),
    ("infrastructure", "communicates-with", "infrastructure"),
    ("infrastructure", "communicates-with", "ipv4-addr"),
    ("infrastructure", "communicates-with", "ipv6-addr"),
    ("infrastructure", "communicates-with", "domain-name"),
    ("infrastructure", "communicates-with", "url"),
    ("infrastructure", "consists-of", "infrastructure"),
    ("infrastructure", "consists-of", "observed-data"),
    ("infrastructure", "consists-of", "sco"),
    ("infrastructure", "controls", "infrastructure"),
    ("infrastructure", "controls", "malware"),
    ("infrastructure", "delivers", "malware"),
    ("infrastructure", "has", "vulnerability"),
    ("infrastructure", "hosts", "tool"),
    ("infrastructure", "hosts", "malware"),
    ("infrastructure", "located-at", "location"),
    ("infrastructure", "uses", "infrastructure"),
    ("intrusion-set", "attributed-to", "threat-actor"),
    ("intrusion-set", "compromises", "infrastructure"),
    ("intrusion-set", "hosts", "infrastructure"),
    ("intrusion-set", "originates-from", "location"),
    ("intrusion-set", "owns", "infrastructure"),
    ("intrusion-set", "targets", "identity"),
    ("intrusion-set", "targets", "location"),
    ("intrusion-set", "targets", "vulnerability"),
    ("intrusion-set", "uses", "attack-pattern"),
    ("intrusion-set", "uses", "infrastructure"),
    ("intrusion-set", "uses", "malware"),
    ("intrusion-set", "uses", "tool"),
    ("ipv4-addr", "belongs-to", "autonomous-system"),
    ("ipv4-addr", "resolves-to", "mac-addr"),
    ("ipv6-addr", "belongs-to", "autonomous-system"),
    ("ipv6-addr", "resolves-to", "mac-addr"),
    ("malware", "authored-by", "threat-actor"),
    ("malware", "beacons-to", "infrastructure"),
    ("malware", "communicates-with", "ipv4-addr"),
    ("malware", "communicates-with", "ipv6-addr"),
    ("malware", "communicates-with", "domain-name"),
    ("malware", "communicates-with", "url"),
    ("malware", "controls", "malware"),
    ("malware", "downloads", "malware"),
    ("malware", "downloads", "tool"),
    ("malware", "drops", "malware"),
    ("malware", "drops", "tool"),
    ("malware", "exploits", "vulnerability"),
    ("malware", "originates-from", "location"),
    ("malware", "targets", "identity"),
    ("malware", "targets", "infrastructure"),
    ("malware", "targets", "location"),
    ("malware", "targets", "vulnerability"),
    ("malware", "uses", "attack-pattern"),
    ("malware", "uses", "malware"),
    ("malware", "uses", "tool"),
    ("malware", "variant-of", "malware"),
    ("malware-analysis", "characterizes", "malware"),
    ("malware-analysis", "analysis-of", "malware"),
    ("malware-analysis", "static-analysis-of", "malware"),
    ("malware-analysis", "dynamic-analysis-of", "malware"),
    ("note", "related-to", "*"),
    ("observed-data", "duplicate-of", "observed-data"),
    ("opinion", "related-to", "*"),
    ("report", "related-to", "*"),
    ("threat-actor", "attributed-to", "identity"),
    ("threat-actor", "compromises", "infrastructure"),
    ("threat-actor", "hosts", "infrastructure"),
    ("threat-actor", "impersonates", "identity"),
    ("threat-actor", "located-at", "location"),
    ("threat-actor", "owns", "infrastructure"),
    ("threat-actor", "targets", "identity"),
    ("threat-actor", "targets", "location"),
    ("threat-actor", "targets", "vulnerability"),
    ("threat-actor", "uses", "attack-pattern"),
    ("threat-actor", "uses", "infrastructure"),
    ("threat-actor", "uses", "malware"),
    ("threat-actor", "uses", "tool"),
    ("tool", "delivers", "malware"),
    ("tool", "drops", "malware"),
    ("tool", "has", "vulnerability"),
    ("tool", "targets", "identity"),
    ("tool", "targets", "infrastructure"),
    ("tool", "targets", "location"),
    ("tool", "targets", "vulnerability"),
    ("tool", "uses", "infrastructure"),
    ("vulnerability", "related-to", "*"),
  ]
}
