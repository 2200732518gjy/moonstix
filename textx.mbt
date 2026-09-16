///|
fn char_at(text : String, index : Int) -> Char? {
  text.get_char(index)
}

///|
fn slice_to(text : String, start : Int, end : Int) -> String {
  text[start:end].to_owned()
}

///|
fn slice_from(text : String, start : Int) -> String {
  text[start:].to_owned()
}

///|
fn char_eq(text : String, index : Int, expected : Char) -> Bool {
  match char_at(text, index) {
    Some(ch) => ch == expected
    None => false
  }
}

///|
fn is_ascii_id_start(ch : Char) -> Bool {
  ch.is_ascii_lowercase()
}

///|
fn is_ascii_id_continue(ch : Char) -> Bool {
  ch.is_ascii_lowercase() || ch.is_ascii_digit() || ch == '-'
}

///|
fn find_from(text : String, needle : String, start : Int) -> Int? {
  if start < 0 || start >= text.length() {
    return None
  }
  match slice_from(text, start).find(needle) {
    None => None
    Some(idx) => Some(start + idx)
  }
}

///|
fn is_ascii_ident_start(ch : Char) -> Bool {
  ch.is_ascii_alphabetic() || ch == '_'
}

///|
fn is_ascii_ident_continue(ch : Char) -> Bool {
  ch.is_ascii_alphabetic() || ch.is_ascii_digit() || ch == '_' || ch == '-'
}
