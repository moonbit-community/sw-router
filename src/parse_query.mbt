///|
pub suberror QueryParseError {
  InvalidCharacter(Int)
} derive(Eq, Show)

///|
fn parse_query(query : String) -> QueryParamArray raise QueryParseError {
  let params = QueryParamArray::new()
  let mut key_start = 0
  let mut value_start = 0
  let mut parse_state = 0 // 0 = key, 1 = value
  for index, char in query.iter2() {
    if char == '=' {
      if key_start == index {
        raise QueryParseError::InvalidCharacter(index)
      }
      value_start = index + 1
      parse_state = 1
    } else if char == '&' {
      if key_start == index {
        raise QueryParseError::InvalidCharacter(index)
      }
      let key = try {
        query[key_start:if parse_state == 0 { index } else { value_start - 1 }].to_string()
      } catch {
        _ => raise QueryParseError::InvalidCharacter(key_start)
      }
      let value = try {
        query[value_start:index].to_string()
      } catch {
        _ => raise QueryParseError::InvalidCharacter(value_start)
      }
      params.push((key, value))
      key_start = index + 1
      parse_state = 0
    } else if char == ' ' {
      raise QueryParseError::InvalidCharacter(index)
    }
  }
  if key_start < query.length() {
    let key = try {
      query[key_start:if parse_state == 0 { query.length() } else { value_start - 1 }].to_string()
    } catch {
      _ => raise QueryParseError::InvalidCharacter(key_start)
    }
    let value = try {
      query[value_start:query.length()].to_string()
    } catch {
      _ => raise QueryParseError::InvalidCharacter(value_start)
    }
    params.push((key, value))
  }
  return params
}

///|
test "parse_query/basic" {
  inspect(
    parse_query("key1=value1&key2=value2"),
    content="[(\"key1\", \"value1\"), (\"key2\", \"value2\")]",
  )
  inspect(parse_query("single=value"), content="[(\"single\", \"value\")]")
  inspect(parse_query("key="), content="[(\"key\", \"\")]")
}

///|
test "parse_query/duplicate_keys" {
  inspect(
    parse_query("key=value1&key=value2"),
    content="[(\"key\", \"value1\"), (\"key\", \"value2\")]",
  )
  inspect(
    parse_query("key=&key=value"),
    content="[(\"key\", \"\"), (\"key\", \"value\")]",
  )
}

///|
test "panic parse_query/invalid_input" {
  ignore(parse_query("=value")) // Empty key
  ignore(parse_query("key=value& ")) // Space character
  ignore(parse_query("&")) // Empty key
}

///|
test "parse_query/basic_parsing" {
  inspect(
    parse_query("key1=value1&key2=value2"),
    content="[(\"key1\", \"value1\"), (\"key2\", \"value2\")]",
  )
}

///|
test "parse_query/empty_value" {
  inspect(
    parse_query("key1=&key2=value2"),
    content="[(\"key1\", \"\"), (\"key2\", \"value2\")]",
  )
}

///|
test "panic parse_query/invalid_character" {
  ignore(parse_query("key1=value1&key with space=value2"))
}
