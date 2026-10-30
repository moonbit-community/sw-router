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
  InvalidCharacter(Int32)
} derive(Eq, Debug)

///|
pub impl Show for LocationParseError with fn output(self, logger) {
  match self {
    ShouldStartWithSlash => logger.write_string("ShouldStartWithSlash")
    MoreThanOneQuery => logger.write_string("MoreThanOneQuery")
    MoreThanOneFragment => logger.write_string("MoreThanOneFragment")
    FragmentBeforeQuery => logger.write_string("FragmentBeforeQuery")
    EmptyLocation => logger.write_string("EmptyLocation")
    InvalidCharacter(index) => {
      logger.write_string("InvalidCharacter(")
      logger.write_object(index)
      logger.write_string(")")
    }
  }
}

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
    location.clamped_view(end=query_start).to_owned()
  } else if fragment_start != -1 {
    location.clamped_view(end=fragment_start).to_owned()
  } else {
    location
  }
  let query = if query_start == -1 {
    None
  } else if fragment_start != -1 {
    Some(
      location
      .clamped_view(start=query_start + 1, end=fragment_start)
      .to_owned(),
    )
  } else {
    Some(location.clamped_view(start=query_start + 1).to_owned())
  }
  let fragment = if fragment_start == -1 {
    None
  } else {
    Some(location.clamped_view(start=fragment_start + 1).to_owned())
  }
  (path, query, fragment)
}

///|
test "parse_location/basic_parsing" {
  @debug.debug_inspect(
    parse_location("/path?query#fragment"),
    content="(\"/path\", Some(\"query\"), Some(\"fragment\"))",
  )
  @debug.debug_inspect(
    parse_location("/path#fragment"),
    content="(\"/path\", None, Some(\"fragment\"))",
  )
  @debug.debug_inspect(
    parse_location("/path?query"),
    content="(\"/path\", Some(\"query\"), None)",
  )
  @debug.debug_inspect(
    parse_location("/path"),
    content="(\"/path\", None, None)",
  )
}

///|
test "parse_location/edge_cases" {
  @debug.debug_inspect(
    parse_location("/?query"),
    content="(\"/\", Some(\"query\"), None)",
  )
  @debug.debug_inspect(
    parse_location("/#fragment"),
    content="(\"/\", None, Some(\"fragment\"))",
  )
  @debug.debug_inspect(parse_location("/"), content="(\"/\", None, None)")
}

///|
test "parse_location/invalid_cases" {
  @debug.assert_eq(
    Ok(parse_location("invalid_no_slash")) catch {
      e => Err(e)
    },
    Err(LocationParseError::ShouldStartWithSlash),
  )
  // Invalid character in path
  @debug.assert_eq(
    Ok(parse_location("/path with space")) catch {
      e => Err(e)
    },
    Err(LocationParseError::InvalidCharacter(5)),
  )
  // Cannot have multiple query parameters
  @debug.assert_eq(
    Ok(parse_location("/path?query1?query2")) catch {
      e => Err(e)
    },
    Err(LocationParseError::MoreThanOneQuery),
  )
  // Cannot have multiple fragments
  @debug.assert_eq(
    Ok(parse_location("/path#fragment1#fragment2")) catch {
      e => Err(e)
    },
    Err(LocationParseError::MoreThanOneFragment),
  )
  // Fragment must come after query
  @debug.assert_eq(
    Ok(parse_location("/path#fragment?query")) catch {
      e => Err(e)
    },
    Err(LocationParseError::FragmentBeforeQuery),
  )
}

///|
test "parse_location/empty" {
  @debug.assert_eq(
    Ok(parse_location("")) catch {
      e => Err(e)
    },
    Err(LocationParseError::EmptyLocation),
  )
}

///|
test "parse_location/empty_path" {
  @debug.debug_inspect(
    parse_location("/?#"),
    content="(\"/\", Some(\"\"), Some(\"\"))",
  )
}
