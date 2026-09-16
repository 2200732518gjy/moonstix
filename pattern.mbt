///|
/// Comparison operator in a STIX observation.
pub(all) enum CompOp {
  Eq
  Ne
  Gt
  Lt
  Ge
  Le
} derive(Eq, Debug)

///|
/// One step of an object path after the type name.
pub(all) enum PathStep {
  Property(String)
  Index(Int)
  AnyIndex
} derive(Eq, Debug)

///|
/// `type:property...` path used by STIX patterning.
pub(all) struct ObjectPath {
  object_type : String
  steps : Array[PathStep]
} derive(Eq, Debug)

///|
/// Constant on the right-hand side of a comparison.
pub(all) enum PatternValue {
  String(String)
  Bool(Bool)
  Number(String)
  Timestamp(String)
  Null
} derive(Eq, Debug)

///|
/// Boolean comparison expression inside `[...]`.
pub(all) enum ComparisonExpr {
  Compare(ObjectPath, CompOp, PatternValue)
  In(ObjectPath, Array[PatternValue])
  Like(ObjectPath, String)
  Matches(ObjectPath, String)
  IsSubset(ObjectPath, String)
  IsSuperset(ObjectPath, String)
  Exists(ObjectPath)
  Not(ComparisonExpr)
  And(ComparisonExpr, ComparisonExpr)
  Or(ComparisonExpr, ComparisonExpr)
} derive(Eq, Debug)

///|
/// Observation expression tree, including qualifiers.
pub(all) enum PatternExpr {
  Observation(ComparisonExpr)
  And(PatternExpr, PatternExpr)
  Or(PatternExpr, PatternExpr)
  FollowedBy(PatternExpr, PatternExpr)
  StartStop(PatternExpr, String, String)
  Within(PatternExpr, String)
  Repeats(PatternExpr, String)
} derive(Eq, Debug)

///|
/// Parse a STIX 2.1 patterning expression.
pub fn parse_pattern(text : String) -> Result[PatternExpr, String] {
  if text.length() == 0 {
    return Err("empty STIX pattern")
  }
  let tokens = match tokenize_pattern(text) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  match parse_followedby(tokens, 0) {
    Err(err) => Err(err)
    Ok(pair) => {
      let expr = pair.0
      let pos = pair.1
      match at(tokens, pos) {
        Eof => Ok(expr)
        other => Err("unexpected \{tok_label(other)} after pattern")
      }
    }
  }
}

///|
fn at(tokens : Array[Tok], pos : Int) -> Tok {
  if pos < 0 || pos >= tokens.length() {
    Eof
  } else {
    tokens[pos]
  }
}

///|
fn parse_followedby(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(PatternExpr, Int), String] {
  let left = match parse_obs_or(tokens, pos) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let mut expr = left.0
  let mut cur = left.1
  while ident_is(at(tokens, cur), "FOLLOWEDBY") {
    let right = match parse_obs_or(tokens, cur + 1) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    expr = FollowedBy(expr, right.0)
    cur = right.1
  }
  Ok((expr, cur))
}

///|
fn parse_obs_or(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(PatternExpr, Int), String] {
  let left = match parse_obs_and(tokens, pos) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let mut expr = left.0
  let mut cur = left.1
  while ident_is(at(tokens, cur), "OR") {
    let right = match parse_obs_and(tokens, cur + 1) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    expr = Or(expr, right.0)
    cur = right.1
  }
  Ok((expr, cur))
}

///|
fn parse_obs_and(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(PatternExpr, Int), String] {
  let left = match parse_obs_qual(tokens, pos) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let mut expr = left.0
  let mut cur = left.1
  while ident_is(at(tokens, cur), "AND") {
    let right = match parse_obs_qual(tokens, cur + 1) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    expr = And(expr, right.0)
    cur = right.1
  }
  Ok((expr, cur))
}

///|
fn parse_obs_qual(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(PatternExpr, Int), String] {
  let primary = match parse_obs_primary(tokens, pos) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let mut expr = primary.0
  let mut cur = primary.1
  while true {
    match parse_qualifier(tokens, cur, expr) {
      None => break
      Some(Err(err)) => return Err(err)
      Some(Ok(next)) => {
        expr = next.0
        cur = next.1
      }
    }
  }
  Ok((expr, cur))
}

///|
fn parse_obs_primary(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(PatternExpr, Int), String] {
  match at(tokens, pos) {
    LBrack => {
      let cmp = match parse_cmp_or(tokens, pos + 1) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      match at(tokens, cmp.1) {
        RBrack => Ok((Observation(cmp.0), cmp.1 + 1))
        other => Err("expected ']' but found \{tok_label(other)}")
      }
    }
    LParen => {
      let inner = match parse_followedby(tokens, pos + 1) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      match at(tokens, inner.1) {
        RParen => Ok((inner.0, inner.1 + 1))
        other => Err("expected ')' but found \{tok_label(other)}")
      }
    }
    other => Err("expected observation but found \{tok_label(other)}")
  }
}

///|
fn parse_qualifier(
  tokens : Array[Tok],
  pos : Int,
  inner : PatternExpr,
) -> Result[(PatternExpr, Int), String]? {
  if ident_is(at(tokens, pos), "START") {
    let start = match expect_timestamp(tokens, pos + 1) {
      Ok(value) => value
      Err(err) => return Some(Err(err))
    }
    if !ident_is(at(tokens, start.1), "STOP") {
      return Some(Err("expected STOP after START timestamp"))
    }
    let stop = match expect_timestamp(tokens, start.1 + 1) {
      Ok(value) => value
      Err(err) => return Some(Err(err))
    }
    return Some(Ok((StartStop(inner, start.0, stop.0), stop.1)))
  }
  if ident_is(at(tokens, pos), "WITHIN") {
    let number = match expect_number(tokens, pos + 1) {
      Ok(value) => value
      Err(err) => return Some(Err(err))
    }
    if !ident_is(at(tokens, number.1), "SECONDS") {
      return Some(Err("expected SECONDS after WITHIN"))
    }
    return Some(Ok((Within(inner, number.0), number.1 + 1)))
  }
  if ident_is(at(tokens, pos), "REPEATS") {
    let number = match expect_number(tokens, pos + 1) {
      Ok(value) => value
      Err(err) => return Some(Err(err))
    }
    if !ident_is(at(tokens, number.1), "TIMES") {
      return Some(Err("expected TIMES after REPEATS"))
    }
    return Some(Ok((Repeats(inner, number.0), number.1 + 1)))
  }
  None
}

///|
fn parse_cmp_or(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(ComparisonExpr, Int), String] {
  let left = match parse_cmp_and(tokens, pos) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let mut expr = left.0
  let mut cur = left.1
  while ident_is(at(tokens, cur), "OR") {
    let right = match parse_cmp_and(tokens, cur + 1) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    expr = Or(expr, right.0)
    cur = right.1
  }
  Ok((expr, cur))
}

///|
fn parse_cmp_and(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(ComparisonExpr, Int), String] {
  let left = match parse_cmp_not(tokens, pos) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let mut expr = left.0
  let mut cur = left.1
  while ident_is(at(tokens, cur), "AND") {
    let right = match parse_cmp_not(tokens, cur + 1) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    expr = And(expr, right.0)
    cur = right.1
  }
  Ok((expr, cur))
}

///|
fn parse_cmp_not(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(ComparisonExpr, Int), String] {
  if ident_is(at(tokens, pos), "NOT") {
    let inner = match parse_cmp_not(tokens, pos + 1) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    Ok((Not(inner.0), inner.1))
  } else {
    parse_cmp_primary(tokens, pos)
  }
}

///|
fn parse_cmp_primary(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(ComparisonExpr, Int), String] {
  if ident_is(at(tokens, pos), "EXISTS") {
    let path = match parse_object_path(tokens, pos + 1) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    return Ok((Exists(path.0), path.1))
  }
  match at(tokens, pos) {
    LParen => {
      let inner = match parse_cmp_or(tokens, pos + 1) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      match at(tokens, inner.1) {
        RParen => Ok((inner.0, inner.1 + 1))
        other => Err("expected ')' but found \{tok_label(other)}")
      }
    }
    _ => parse_comparison(tokens, pos)
  }
}

///|
fn parse_comparison(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(ComparisonExpr, Int), String] {
  let path = match parse_object_path(tokens, pos) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let tok = at(tokens, path.1)
  if ident_is(tok, "IN") {
    let values = match parse_set(tokens, path.1 + 1) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    return Ok((In(path.0, values.0), values.1))
  }
  if ident_is(tok, "LIKE") {
    let value = match expect_string(tokens, path.1 + 1) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    return Ok((Like(path.0, value.0), value.1))
  }
  if ident_is(tok, "MATCHES") {
    let value = match expect_string(tokens, path.1 + 1) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    return Ok((Matches(path.0, value.0), value.1))
  }
  if ident_is(tok, "ISSUBSET") {
    let value = match expect_string(tokens, path.1 + 1) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    return Ok((IsSubset(path.0, value.0), value.1))
  }
  if ident_is(tok, "ISSUPERSET") {
    let value = match expect_string(tokens, path.1 + 1) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    return Ok((IsSuperset(path.0, value.0), value.1))
  }
  let op = match tok {
    Eq => CompOp::Eq
    Ne => CompOp::Ne
    Gt => CompOp::Gt
    Lt => CompOp::Lt
    Ge => CompOp::Ge
    Le => CompOp::Le
    other =>
      return Err("expected comparison operator but found \{tok_label(other)}")
  }
  let value = match parse_value(tokens, path.1 + 1) {
    Ok(item) => item
    Err(err) => return Err(err)
  }
  Ok((Compare(path.0, op, value.0), value.1))
}

///|
fn parse_object_path(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(ObjectPath, Int), String] {
  let type_name = match expect_ident(tokens, pos) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  match at(tokens, type_name.1) {
    Colon => ()
    other =>
      return Err("expected ':' in object path but found \{tok_label(other)}")
  }
  let first = match parse_property_name(tokens, type_name.1 + 1) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let steps : Array[PathStep] = [Property(first.0)]
  let mut cur = first.1
  while true {
    match at(tokens, cur) {
      Dot => {
        let name = match parse_property_name(tokens, cur + 1) {
          Ok(value) => value
          Err(err) => return Err(err)
        }
        steps.push(Property(name.0))
        cur = name.1
      }
      LBrack =>
        match at(tokens, cur + 1) {
          Star =>
            match at(tokens, cur + 2) {
              RBrack => {
                steps.push(AnyIndex)
                cur = cur + 3
              }
              other =>
                return Err(
                  "expected ']' after '*' but found \{tok_label(other)}",
                )
            }
          Number(text) =>
            match at(tokens, cur + 2) {
              RBrack => {
                steps.push(Index(parse_index_number(text)))
                cur = cur + 3
              }
              other =>
                return Err(
                  "expected ']' after index but found \{tok_label(other)}",
                )
            }
          other =>
            return Err("expected index or '*' but found \{tok_label(other)}")
        }
      _ => break
    }
  }
  Ok(({ object_type: type_name.0, steps, }, cur))
}

///|
fn parse_property_name(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(String, Int), String] {
  match at(tokens, pos) {
    Ident(text) => Ok((text, pos + 1))
    String(text) => Ok((text, pos + 1))
    other => Err("expected property name but found \{tok_label(other)}")
  }
}

///|
fn parse_set(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(Array[PatternValue], Int), String] {
  match at(tokens, pos) {
    LParen => ()
    other =>
      return Err("expected '(' to start a set but found \{tok_label(other)}")
  }
  let values : Array[PatternValue] = []
  let mut cur = pos + 1
  if (match at(tokens, cur) {
      RParen => true
      _ => false
    }) {
    return Err("set literal cannot be empty")
  }
  while true {
    let item = match parse_value(tokens, cur) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    values.push(item.0)
    cur = item.1
    match at(tokens, cur) {
      Comma => cur += 1
      RParen => return Ok((values, cur + 1))
      other =>
        return Err("expected ',' or ')' in set but found \{tok_label(other)}")
    }
  }
  Err("unterminated set literal")
}

///|
fn parse_value(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(PatternValue, Int), String] {
  match at(tokens, pos) {
    String(text) => Ok((String(text), pos + 1))
    Number(text) => Ok((Number(text), pos + 1))
    Timestamp(text) => Ok((Timestamp(text), pos + 1))
    Ident("true") => Ok((Bool(true), pos + 1))
    Ident("false") => Ok((Bool(false), pos + 1))
    Ident("null") => Ok((Null, pos + 1))
    other => Err("expected constant but found \{tok_label(other)}")
  }
}

///|
fn expect_ident(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(String, Int), String] {
  match at(tokens, pos) {
    Ident(text) => Ok((text, pos + 1))
    other => Err("expected identifier but found \{tok_label(other)}")
  }
}

///|
fn expect_string(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(String, Int), String] {
  match at(tokens, pos) {
    String(text) => Ok((text, pos + 1))
    other => Err("expected string but found \{tok_label(other)}")
  }
}

///|
fn expect_number(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(String, Int), String] {
  match at(tokens, pos) {
    Number(text) => Ok((text, pos + 1))
    other => Err("expected number but found \{tok_label(other)}")
  }
}

///|
fn expect_timestamp(
  tokens : Array[Tok],
  pos : Int,
) -> Result[(String, Int), String] {
  match at(tokens, pos) {
    Timestamp(text) => Ok((text, pos + 1))
    other => Err("expected t'timestamp' but found \{tok_label(other)}")
  }
}

///|
fn parse_index_number(text : String) -> Int {
  let mut value = 0
  for i = 0; i < text.length(); i = i + 1 {
    match char_at(text, i) {
      Some(ch) =>
        if ch.is_ascii_digit() {
          value = value * 10 + (ch.to_int() - 48)
        }
      None => ()
    }
  }
  value
}

///|
pub fn pattern_object_types(expr : PatternExpr) -> Array[String] {
  let names : Array[String] = []
  collect_pattern_types(expr, names)
  names
}

///|
fn collect_pattern_types(expr : PatternExpr, names : Array[String]) -> Unit {
  match expr {
    Observation(cmp) => collect_cmp_types(cmp, names)
    And(left, right) => {
      collect_pattern_types(left, names)
      collect_pattern_types(right, names)
    }
    Or(left, right) => {
      collect_pattern_types(left, names)
      collect_pattern_types(right, names)
    }
    FollowedBy(left, right) => {
      collect_pattern_types(left, names)
      collect_pattern_types(right, names)
    }
    StartStop(inner, _, _) => collect_pattern_types(inner, names)
    Within(inner, _) => collect_pattern_types(inner, names)
    Repeats(inner, _) => collect_pattern_types(inner, names)
  }
}

///|
fn collect_cmp_types(expr : ComparisonExpr, names : Array[String]) -> Unit {
  match expr {
    Compare(path, _, _) => push_unique(names, path.object_type)
    In(path, _) => push_unique(names, path.object_type)
    Like(path, _) => push_unique(names, path.object_type)
    Matches(path, _) => push_unique(names, path.object_type)
    IsSubset(path, _) => push_unique(names, path.object_type)
    IsSuperset(path, _) => push_unique(names, path.object_type)
    Exists(path) => push_unique(names, path.object_type)
    Not(inner) => collect_cmp_types(inner, names)
    And(left, right) => {
      collect_cmp_types(left, names)
      collect_cmp_types(right, names)
    }
    Or(left, right) => {
      collect_cmp_types(left, names)
      collect_cmp_types(right, names)
    }
  }
}

///|
fn push_unique(names : Array[String], name : String) -> Unit {
  if !names.contains(name) {
    names.push(name)
  }
}

///|
pub fn validate_pattern_paths(expr : PatternExpr) -> Array[Issue] {
  let issues : Array[Issue] = []
  check_pattern_paths(expr, issues)
  issues
}

///|
fn check_pattern_paths(expr : PatternExpr, issues : Array[Issue]) -> Unit {
  match expr {
    Observation(cmp) => check_cmp_paths(cmp, issues)
    And(left, right) => {
      check_pattern_paths(left, issues)
      check_pattern_paths(right, issues)
    }
    Or(left, right) => {
      check_pattern_paths(left, issues)
      check_pattern_paths(right, issues)
    }
    FollowedBy(left, right) => {
      check_pattern_paths(left, issues)
      check_pattern_paths(right, issues)
    }
    StartStop(inner, start, stop) => {
      if !timestamp_is_rfc3339(start) {
        issues.push(
          issue("pattern-timestamp", "", "START timestamp is not RFC 3339"),
        )
      }
      if !timestamp_is_rfc3339(stop) {
        issues.push(
          issue("pattern-timestamp", "", "STOP timestamp is not RFC 3339"),
        )
      }
      check_pattern_paths(inner, issues)
    }
    Within(inner, _) => check_pattern_paths(inner, issues)
    Repeats(inner, _) => check_pattern_paths(inner, issues)
  }
}

///|
fn check_cmp_paths(expr : ComparisonExpr, issues : Array[Issue]) -> Unit {
  match expr {
    Compare(path, _, _) => check_object_path(path, issues)
    In(path, _) => check_object_path(path, issues)
    Like(path, _) => check_object_path(path, issues)
    Matches(path, _) => check_object_path(path, issues)
    IsSubset(path, _) => check_object_path(path, issues)
    IsSuperset(path, _) => check_object_path(path, issues)
    Exists(path) => check_object_path(path, issues)
    Not(inner) => check_cmp_paths(inner, issues)
    And(left, right) => {
      check_cmp_paths(left, issues)
      check_cmp_paths(right, issues)
    }
    Or(left, right) => {
      check_cmp_paths(left, issues)
      check_cmp_paths(right, issues)
    }
  }
}

///|
fn check_object_path(path : ObjectPath, issues : Array[Issue]) -> Unit {
  if path.steps.length() == 0 {
    issues.push(
      issue("pattern-path", path.object_type, "object path has no property"),
    )
    return
  }
  match lookup_type_spec(path.object_type) {
    None =>
      if !path.object_type.has_prefix("x-") {
        issues.push(
          issue(
            "pattern-type",
            path.object_type,
            "unknown STIX type in pattern path",
          ),
        )
      }
    Some(spec) =>
      match path.steps[0] {
        Property(name) =>
          match field_by_name(spec, name) {
            None =>
              issues.push(
                issue(
                  "pattern-property",
                  "\{path.object_type}:\{name}",
                  "property is not in the \{path.object_type} table",
                ),
              )
            Some(_) => ()
          }
        Index(_) | AnyIndex =>
          issues.push(
            issue(
              "pattern-path",
              path.object_type,
              "object path must start with a property",
            ),
          )
      }
  }
}
