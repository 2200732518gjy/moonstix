///|
/// Diagnostic collected while parsing or validating STIX JSON.
pub(all) struct Issue {
  code : String
  path : String
  message : String
} derive(Eq, Debug)

///|
/// Fatal document-level failure. Property problems are reported as `Issue`.
pub(all) enum StixError {
  JsonSyntax(String)
  NotObject
  UnexpectedRoot(String)
  Pattern(String)
} derive(Eq, Debug)

///|
pub fn issue(code : String, path : String, message : String) -> Issue {
  { code, path, message, }
}

///|
pub fn Issue::code_name(self : Issue) -> String {
  self.code
}

///|
pub fn Issue::at(self : Issue) -> String {
  self.path
}

///|
pub fn StixError::message(self : StixError) -> String {
  match self {
    JsonSyntax(detail) => "JSON syntax error: \{detail}"
    NotObject => "STIX document root must be a JSON object"
    UnexpectedRoot(kind) => "unexpected STIX root type \{kind}"
    Pattern(detail) => "STIX pattern error: \{detail}"
  }
}

///|
fn join_path(parent : String, child : String) -> String {
  if parent.length() == 0 {
    child
  } else {
    "\{parent}.\{child}"
  }
}

///|
fn index_path(parent : String, index : Int) -> String {
  if parent.length() == 0 {
    "[\{index}]"
  } else {
    "\{parent}[\{index}]"
  }
}
