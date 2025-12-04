///|
/// Path, Query, Fragment
type LocationTuple = (String, String?, String?)

///|
pub suberror LocationParseError {
  ShouldStartWithSlash
  MoreThanOneQuery
  MoreThanOneFragment
  FragmentBeforeQuery
  EmptyLocation
  InvalidCharacter(Int)
} derive(Eq, Show)

// TODO: Add char check
// Unreserved Characters
// https://datatracker.ietf.org/doc/html/rfc3986#section-2.3
// Unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"
// Reserved Characters
// https://datatracker.ietf.org/doc/html/rfc3986#section-2.2
// Reserved = gen-delims / sub-delims
// gen-delims = ":" / "/" / "?" / "#" / "[" / "]" / "@"
// sub-delims = "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," /
//              ";" / "="

///|
fn parse_location(location : String) -> LocationTuple raise LocationParseError {
  if location.length() == 0 {
    raise LocationParseError::EmptyLocation
  }
  if location.code_unit_at(0) != '/' {
    raise LocationParseError::ShouldStartWithSlash
  }
  // "/"
  if location.length() == 1 {
    return ("/", None, None)
  }
  let mut query_start = -1
  let mut fragment_start = -1
  for index, char in location.iter2() {
    // TODO: Add more checks for valid characters
    if char == ' ' {
      raise LocationParseError::InvalidCharacter(index)
    }
    if char == '?' {
      if query_start != -1 {
        raise LocationParseError::MoreThanOneQuery
      }
      query_start = index
    } else if char == '#' {
      if fragment_start != -1 {
        raise LocationParseError::MoreThanOneFragment
      }
      fragment_start = index
    }
  }
  if query_start != -1 && fragment_start != -1 && fragment_start < query_start {
    raise LocationParseError::FragmentBeforeQuery
  }
  let path = if query_start != -1 {
    location.view(end_offset=query_start).to_string()
  } else if fragment_start != -1 {
    location.view(end_offset=fragment_start).to_string()
  } else {
    location
  }
  let query = if query_start == -1 {
    None
  } else if fragment_start != -1 {
    Some(
      location
      .view(start_offset=query_start + 1, end_offset=fragment_start)
      .to_string(),
    )
  } else {
    Some(location.view(start_offset=query_start + 1).to_string())
  }
  let fragment = if fragment_start == -1 {
    None
  } else {
    Some(location.view(start_offset=fragment_start + 1).to_string())
  }
  (path, query, fragment)
}

///|
test "parse_location/basic_parsing" {
  inspect(
    parse_location("/path?query#fragment"),
    content="(\"/path\", Some(\"query\"), Some(\"fragment\"))",
  )
  inspect(
    parse_location("/path#fragment"),
    content="(\"/path\", None, Some(\"fragment\"))",
  )
  inspect(
    parse_location("/path?query"),
    content="(\"/path\", Some(\"query\"), None)",
  )
  inspect(parse_location("/path"), content="(\"/path\", None, None)")
}

///|
test "parse_location/edge_cases" {
  inspect(parse_location("/?query"), content="(\"/\", Some(\"query\"), None)")
  inspect(
    parse_location("/#fragment"),
    content="(\"/\", None, Some(\"fragment\"))",
  )
  inspect(parse_location("/"), content="(\"/\", None, None)")
}

///|
test "parse_location/invalid_cases" {
  assert_eq(
    try? parse_location("invalid_no_slash"),
    Err(LocationParseError::ShouldStartWithSlash),
  )
  // Invalid character in path
  assert_eq(
    try? parse_location("/path with space"),
    Err(LocationParseError::InvalidCharacter(5)),
  )
  // Cannot have multiple query parameters
  assert_eq(
    try? parse_location("/path?query1?query2"),
    Err(LocationParseError::MoreThanOneQuery),
  )
  // Cannot have multiple fragments
  assert_eq(
    try? parse_location("/path#fragment1#fragment2"),
    Err(LocationParseError::MoreThanOneFragment),
  )
  // Fragment must come after query
  assert_eq(
    try? parse_location("/path#fragment?query"),
    Err(LocationParseError::FragmentBeforeQuery),
  )
}

///|
test "parse_location/empty" {
  assert_eq(try? parse_location(""), Err(LocationParseError::EmptyLocation))
}

///|
test "parse_location/empty_path" {
  inspect(parse_location("/?#"), content="(\"/\", Some(\"\"), Some(\"\"))")
}
