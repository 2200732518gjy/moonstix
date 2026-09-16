///|
/// Parsed RFC 3339 timestamp used by STIX 2.1 datetime properties.
pub(all) struct Timestamp {
  year : Int
  month : Int
  day : Int
  hour : Int
  minute : Int
  second : Int
  fraction : String
  offset_minutes : Int
  text : String
} derive(Eq, Debug)

///|
pub fn parse_timestamp(text : String) -> Result[Timestamp, String] {
  if text.length() < 19 {
    return Err("timestamp is too short")
  }
  if !char_eq(text, 4, '-') || !char_eq(text, 7, '-') {
    return Err("timestamp date must use YYYY-MM-DD")
  }
  if !char_eq(text, 10, 'T') {
    return Err("timestamp must separate date and time with 'T'")
  }
  if !char_eq(text, 13, ':') || !char_eq(text, 16, ':') {
    return Err("timestamp time must use HH:MM:SS")
  }
  let year = match parse_digits(text, 0, 4) {
    Some(value) => value
    None => return Err("invalid year")
  }
  let month = match parse_digits(text, 5, 2) {
    Some(value) => value
    None => return Err("invalid month")
  }
  let day = match parse_digits(text, 8, 2) {
    Some(value) => value
    None => return Err("invalid day")
  }
  let hour = match parse_digits(text, 11, 2) {
    Some(value) => value
    None => return Err("invalid hour")
  }
  let minute = match parse_digits(text, 14, 2) {
    Some(value) => value
    None => return Err("invalid minute")
  }
  let second = match parse_digits(text, 17, 2) {
    Some(value) => value
    None => return Err("invalid second")
  }
  if month < 1 || month > 12 {
    return Err("month out of range")
  }
  if day < 1 || day > days_in_month(year, month) {
    return Err("day out of range")
  }
  if hour > 23 || minute > 59 || second > 59 {
    return Err("time out of range")
  }
  let mut pos = 19
  let mut fraction = ""
  if char_eq(text, pos, '.') {
    pos += 1
    let start = pos
    while pos < text.length() {
      match char_at(text, pos) {
        Some(ch) => if ch.is_ascii_digit() { pos += 1 } else { break }
        None => break
      }
    }
    if pos == start {
      return Err("timestamp fraction has no digits")
    }
    fraction = slice_to(text, start, pos)
  }
  let offset_minutes = match parse_timezone(text, pos) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  Ok({ year, month, day, hour, minute, second, fraction, offset_minutes, text, })
}

///|
fn parse_digits(text : String, start : Int, width : Int) -> Int? {
  if start + width > text.length() {
    return None
  }
  let mut value = 0
  for i = 0; i < width; i = i + 1 {
    match char_at(text, start + i) {
      Some(ch) => {
        if !ch.is_ascii_digit() {
          return None
        }
        value = value * 10 + (ch.to_int() - 48)
      }
      None => return None
    }
  }
  Some(value)
}

///|
fn days_in_month(year : Int, month : Int) -> Int {
  match month {
    1 | 3 | 5 | 7 | 8 | 10 | 12 => 31
    4 | 6 | 9 | 11 => 30
    2 => if is_leap_year(year) { 29 } else { 28 }
    _ => 0
  }
}

///|
fn is_leap_year(year : Int) -> Bool {
  year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)
}

///|
fn parse_timezone(text : String, start : Int) -> Result[Int, String] {
  match char_at(text, start) {
    None => Err("timestamp is missing a timezone")
    Some('Z') =>
      if start + 1 != text.length() {
        Err("timestamp has trailing characters after Z")
      } else {
        Ok(0)
      }
    Some(sign) => {
      if sign != '+' && sign != '-' {
        return Err("timestamp timezone must be Z or an offset")
      }
      if start + 6 != text.length() || !char_eq(text, start + 3, ':') {
        return Err("timestamp offset must be HH:MM")
      }
      let hour = match parse_digits(text, start + 1, 2) {
        Some(value) => value
        None => return Err("invalid offset hour")
      }
      let minute = match parse_digits(text, start + 4, 2) {
        Some(value) => value
        None => return Err("invalid offset minute")
      }
      if hour > 23 || minute > 59 {
        return Err("offset out of range")
      }
      let total = hour * 60 + minute
      if sign == '-' {
        Ok(0 - total)
      } else {
        Ok(total)
      }
    }
  }
}

///|
pub fn timestamp_is_rfc3339(text : String) -> Bool {
  match parse_timestamp(text) {
    Ok(_) => true
    Err(_) => false
  }
}
