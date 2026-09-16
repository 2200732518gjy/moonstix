///|
pub fn valid_ipv4(text : String) -> Bool {
  let parts = split_once_slash(text)
  if !valid_dotted_ipv4(parts.0) {
    return false
  }
  match parts.1 {
    None => true
    Some(prefix) => valid_int_range(prefix, 0, 32)
  }
}

///|
pub fn valid_ipv6(text : String) -> Bool {
  let parts = split_once_slash(text)
  if !valid_raw_ipv6(parts.0) {
    return false
  }
  match parts.1 {
    None => true
    Some(prefix) => valid_int_range(prefix, 0, 128)
  }
}

///|
pub fn valid_mac(text : String) -> Bool {
  if text.length() != 17 {
    return false
  }
  for i = 0; i < 17; i = i + 1 {
    match char_at(text, i) {
      None => return false
      Some(ch) =>
        if i % 3 == 2 {
          if ch != ':' && ch != '-' {
            return false
          }
        } else if !ch.is_ascii_hexdigit() {
          return false
        }
    }
  }
  true
}

///|
pub fn valid_email(text : String) -> Bool {
  match text.find("@") {
    None => false
    Some(idx) =>
      if idx == 0 || idx == text.length() - 1 {
        false
      } else {
        match find_from(text, ".", idx + 1) {
          None => false
          Some(dot) => dot > idx + 1 && dot < text.length() - 1
        }
      }
  }
}

///|
pub fn valid_url(text : String) -> Bool {
  match text.find("://") {
    None => false
    Some(idx) => idx >= 2 && idx + 3 < text.length()
  }
}

///|
pub fn valid_hex_binary(text : String) -> Bool {
  if text.length() == 0 || text.length() % 2 != 0 {
    return false
  }
  for i = 0; i < text.length(); i = i + 1 {
    match char_at(text, i) {
      Some(ch) => if !ch.is_ascii_hexdigit() { return false }
      None => return false
    }
  }
  true
}

///|
fn split_once_slash(text : String) -> (String, String?) {
  match text.find("/") {
    None => (text, None)
    Some(idx) => (slice_to(text, 0, idx), Some(slice_from(text, idx + 1)))
  }
}

///|
fn valid_dotted_ipv4(text : String) -> Bool {
  let mut start = 0
  let mut seen = 0
  for i = 0; i <= text.length(); i = i + 1 {
    if i == text.length() || char_eq(text, i, '.') {
      if i == start {
        return false
      }
      let part = slice_to(text, start, i)
      if !valid_int_range(part, 0, 255) {
        return false
      }
      seen += 1
      start = i + 1
    }
  }
  seen == 4
}

///|
fn valid_raw_ipv6(text : String) -> Bool {
  if text.length() == 0 {
    return false
  }
  match text.find("::") {
    None =>
      match ipv6_group_count(text) {
        Some(count) => count == 8
        None => false
      }
    Some(idx) =>
      match find_from(text, "::", idx + 2) {
        Some(_) => false
        None => {
          let left = slice_to(text, 0, idx)
          let right = slice_from(text, idx + 2)
          match (ipv6_group_count(left), ipv6_group_count(right)) {
            (Some(left_count), Some(right_count)) =>
              left_count + right_count <= 7
            _ => false
          }
        }
      }
  }
}

///|
fn ipv6_group_count(text : String) -> Int? {
  if text.length() == 0 {
    return Some(0)
  }
  let mut start = 0
  let mut count = 0
  for i = 0; i <= text.length(); i = i + 1 {
    if i == text.length() || char_eq(text, i, ':') {
      if i == start {
        return None
      }
      let part = slice_to(text, start, i)
      if part.length() == 0 || part.length() > 4 {
        return None
      }
      for p = 0; p < part.length(); p = p + 1 {
        match char_at(part, p) {
          Some(ch) => if !ch.is_ascii_hexdigit() { return None }
          None => return None
        }
      }
      count += 1
      start = i + 1
    }
  }
  Some(count)
}

///|
fn valid_int_range(text : String, min : Int, max : Int) -> Bool {
  if text.length() == 0 {
    return false
  }
  let mut value = 0
  for i = 0; i < text.length(); i = i + 1 {
    match char_at(text, i) {
      Some(ch) => {
        if !ch.is_ascii_digit() {
          return false
        }
        value = value * 10 + (ch.to_int() - 48)
        if value > max {
          return false
        }
      }
      None => return false
    }
  }
  value >= min && value <= max
}
