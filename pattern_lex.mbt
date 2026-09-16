///|
/// Tokens produced by the STIX patterning lexer.
pub(all) enum Tok {
  Eof
  Ident(String)
  String(String)
  Number(String)
  Timestamp(String)
  LBrack
  RBrack
  LParen
  RParen
  Colon
  Dot
  Star
  Comma
  Eq
  Ne
  Gt
  Lt
  Ge
  Le
} derive(Eq, Debug)

///|
fn tok_label(tok : Tok) -> String {
  match tok {
    Eof => "end of pattern"
    Ident(text) => "identifier \{text}"
    String(_) => "string"
    Number(text) => "number \{text}"
    Timestamp(_) => "timestamp literal"
    LBrack => "["
    RBrack => "]"
    LParen => "("
    RParen => ")"
    Colon => ":"
    Dot => "."
    Star => "*"
    Comma => ","
    Eq => "="
    Ne => "!="
    Gt => ">"
    Lt => "<"
    Ge => ">="
    Le => "<="
  }
}

///|
fn tokenize_pattern(text : String) -> Result[Array[Tok], String] {
  let tokens : Array[Tok] = []
  let mut i = 0
  while i < text.length() {
    match char_at(text, i) {
      None => break
      Some(ch) =>
        if ch.is_ascii_whitespace() {
          i += 1
        } else if ch == '[' {
          tokens.push(LBrack)
          i += 1
        } else if ch == ']' {
          tokens.push(RBrack)
          i += 1
        } else if ch == '(' {
          tokens.push(LParen)
          i += 1
        } else if ch == ')' {
          tokens.push(RParen)
          i += 1
        } else if ch == ':' {
          tokens.push(Colon)
          i += 1
        } else if ch == '.' {
          tokens.push(Dot)
          i += 1
        } else if ch == '*' {
          tokens.push(Star)
          i += 1
        } else if ch == ',' {
          tokens.push(Comma)
          i += 1
        } else if ch == '=' {
          tokens.push(Eq)
          i += 1
        } else if ch == '!' {
          if char_eq(text, i + 1, '=') {
            tokens.push(Ne)
            i += 2
          } else {
            return Err("unexpected '!' in pattern")
          }
        } else if ch == '>' {
          if char_eq(text, i + 1, '=') {
            tokens.push(Ge)
            i += 2
          } else {
            tokens.push(Gt)
            i += 1
          }
        } else if ch == '<' {
          if char_eq(text, i + 1, '=') {
            tokens.push(Le)
            i += 2
          } else {
            tokens.push(Lt)
            i += 1
          }
        } else if ch == '\'' {
          match read_quoted(text, i) {
            Err(err) => return Err(err)
            Ok(pair) => {
              tokens.push(String(pair.0))
              i = pair.1
            }
          }
        } else if ch == 't' && char_eq(text, i + 1, '\'') {
          match read_quoted(text, i + 1) {
            Err(err) => return Err(err)
            Ok(pair) => {
              tokens.push(Timestamp(pair.0))
              i = pair.1
            }
          }
        } else if ch == '-' || ch.is_ascii_digit() {
          match read_number(text, i) {
            Err(err) => return Err(err)
            Ok(pair) => {
              tokens.push(Number(pair.0))
              i = pair.1
            }
          }
        } else if is_ascii_ident_start(ch) {
          let start = i
          i += 1
          while i < text.length() {
            match char_at(text, i) {
              Some(next) =>
                if is_ascii_ident_continue(next) {
                  i += 1
                } else {
                  break
                }
              None => break
            }
          }
          tokens.push(Ident(slice_to(text, start, i)))
        } else {
          return Err("unexpected character in STIX pattern")
        }
    }
  }
  tokens.push(Eof)
  Ok(tokens)
}

///|
fn read_quoted(text : String, start : Int) -> Result[(String, Int), String] {
  if !char_eq(text, start, '\'') {
    return Err("expected string literal")
  }
  let mut i = start + 1
  let mut out = ""
  while i < text.length() {
    match char_at(text, i) {
      None => return Err("unterminated string literal")
      Some('\\') =>
        match char_at(text, i + 1) {
          None => return Err("unterminated escape in string")
          Some('\'') => {
            out = "\{out}'"
            i += 2
          }
          Some('\\') => {
            out = "\{out}\\"
            i += 2
          }
          Some('n') => {
            out = "\{out}\n"
            i += 2
          }
          Some('t') => {
            out = "\{out}\t"
            i += 2
          }
          Some('r') => {
            out = "\{out}\r"
            i += 2
          }
          Some(_) => return Err("unsupported string escape")
        }
      Some('\'') => return Ok((out, i + 1))
      Some(ch) => {
        out = "\{out}\{ch}"
        i += 1
      }
    }
  }
  Err("unterminated string literal")
}

///|
fn read_number(text : String, start : Int) -> Result[(String, Int), String] {
  let mut i = start
  if char_eq(text, i, '-') {
    i += 1
  }
  let digits_start = i
  while i < text.length() {
    match char_at(text, i) {
      Some(ch) => if ch.is_ascii_digit() { i += 1 } else { break }
      None => break
    }
  }
  if i == digits_start {
    return Err("invalid number in pattern")
  }
  if char_eq(text, i, '.') {
    i += 1
    let frac = i
    while i < text.length() {
      match char_at(text, i) {
        Some(ch) => if ch.is_ascii_digit() { i += 1 } else { break }
        None => break
      }
    }
    if i == frac {
      return Err("invalid fractional number in pattern")
    }
  }
  Ok((slice_to(text, start, i), i))
}

///|
fn ident_is(tok : Tok, name : String) -> Bool {
  match tok {
    Ident(text) => text == name
    _ => false
  }
}
