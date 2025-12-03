///|
/// Array of query parameters from the URL
/// Represents URL query parameters as key-value pairs
/// (e.g. `[("foo", "bar"), ("foo", "baz")]` for `/foo?foo=bar&foo=baz`)
/// Uses array instead of map because query parameters can have duplicate keys.
type QueryParamArray = Array[(String, String)]

///|
/// Map of path parameters extracted from the URL
/// Contains named parameters captured from URL path patterns
/// (e.g. `{ "foo": "bar" }` when `/:foo/hello_world` matches `/bar/hello_world`)
type PathParamMap = Map[String, String]

///|
/// URL fragment identifier
/// Represents the part of a URL after the hash symbol
/// (e.g. `bar` in `/foo#bar`)
type Fragment = String

///|
/// Route handler function type
/// Takes path parameters, query parameters, and fragment as input
type Handler[A] = (PathParamMap, QueryParamArray, Fragment?) -> A

///|
/// Route configuration type
/// Pairs a path pattern string with a handler function that processes
/// the extracted path parameters, query parameters, and fragment
type RouteConfig[A] = (String, Handler[A])

///|
/// Router implementation
/// Manages a collection of route configurations and handles dispatching
/// requests to the appropriate handler based on the provided location
struct Router[A] {
  root : TrieNode[A]
  // make sure no duplicate path parameters
  registered_param_hashes : Set[Int]
}

///|
/// Creates a new router instance
/// Takes an array of route configurations and initializes the router
/// Each configuration consists of a path pattern and its handler function
/// Returns error if any route configuration is invalid
pub fn[A] router(
  configs : Array[RouteConfig[A]],
) -> Router[A] raise AddRouteError {
  let router = Router::{
    root: TrieNode::create_root(),
    registered_param_hashes: Set::new(),
  }
  router.add_routes(configs)
  router
}

///|
/// Error types that may occur when adding routes
/// ParseLocationError - Invalid location format in route pattern
/// AlreadyExists - Route pattern conflicts with existing route
/// PathParamAlreadyExists - Path parameter name is already used
/// RouteShouldNotHaveQuery - Route pattern should not contain query string
/// RouteShouldNotHaveFragment - Route pattern should not contain fragment
pub suberror AddRouteError {
  ParseLocationError(LocationParseError)
  AlreadyExists(String)
  PathParamAlreadyExists(String)
  RouteShouldNotHaveQuery(String)
  RouteShouldNotHaveFragment(String)
} derive(Eq, Show)

///|
/// Adds a single route to the router
/// Takes a path pattern and its handler function
/// Path pattern must not contain query string or fragment
/// Returns error if the route is invalid or conflicts with existing routes 
pub fn[A] Router::add_route(
  self : Router[A],
  path : String,
  handler : Handler[A],
) -> Unit raise AddRouteError {
  // check if path is valid by parse_location
  let (path, query, fragment) = parse_location(path) catch {
    e => raise AddRouteError::ParseLocationError(e)
  }
  match query {
    Some(_) => raise AddRouteError::RouteShouldNotHaveQuery(path)
    None => ()
  }
  match fragment {
    Some(_) => raise AddRouteError::RouteShouldNotHaveFragment(path)
    None => ()
  }
  let mut node = self.root
  let mut last_index = 0
  let mut is_dynamic = false
  fn insert_path_segment(
    start : Int,
    end : Int,
    is_dynamic : Bool,
  ) -> TrieNode[A] raise AddRouteError {
    let segment = path[start:end].to_string() catch {
      _ => abort("String slice failed")
    }
    if is_dynamic {
      let segment = segment[1:].to_string() // remove ':'
       catch {
        _ => abort("String slice failed")
      }
      match node.variable_child {
        Some(_) => raise AddRouteError::AlreadyExists(path)
        None => ()
      }
      if self.registered_param_hashes.contains(segment.hash()) {
        raise AddRouteError::PathParamAlreadyExists(segment)
      }
      self.registered_param_hashes.add(segment.hash())
      let new_node = TrieNode::create_with_handler(handler)
      node.variable_child = Some((segment, new_node))
      new_node
    } else if node.children.contains(segment) {
      node.children.get(segment).unwrap()
    } else {
      let new_node = TrieNode::create_with_handler(handler)
      node.children[segment] = new_node
      new_node
    }
  }

  for index, c in path.iter2() {
    if c == '/' {
      node = insert_path_segment(last_index, index, is_dynamic)
      last_index = index + 1
    }
    if index > 0 && c == ':' && path.code_unit_at(index - 1) == 47 {
      is_dynamic = true
    }
  }
  if last_index <= path.length() {
    node = insert_path_segment(last_index, path.length(), is_dynamic)
  }

  // TODO: check is already exists
}

///|
/// Adds multiple routes to the router
/// Takes an array of route configurations
/// Returns error if any route is invalid or conflicts with existing routes
pub fn[A] Router::add_routes(
  self : Router[A],
  routes : Array[RouteConfig[A]],
) -> Unit raise AddRouteError {
  for route in routes {
    self.add_route(route.0, route.1)
  }
}

///|
/// Error types that may occur during route dispatch
/// InvalidLocation - Failed to parse the request location
/// InvalidQuery - Failed to parse query parameters
/// RouteNotMatched - No matching route found for the location
pub suberror DispatchError {
  InvalidLocation(LocationParseError)
  InvalidQuery(QueryParseError)
  RouteNotMatched(String)
} derive(Eq, Show)

///|
/// Internal helper function to match a path against registered routes
/// Returns the matched route node and extracted path parameters
/// Returns None if no matching route is found
fn[A] Router::match_route_with_params(
  self : Router[A],
  path : String,
) -> (TrieNode[A], PathParamMap)? {
  let mut node = self.root
  let path_params = PathParamMap::new()
  let mut last_index = 0
  fn push_segment(start : Int, end : Int) -> TrieNode[A]? {
    let segment = path[start:end].to_string() catch {
      _ => abort("String slice failed")
    }
    if node.children.contains(segment) {
      Some(node.children.get(segment).unwrap())
    } else {
      match node.variable_child {
        None => return None
        Some(_) => {
          let (var_segment, var_node) = node.variable_child.unwrap()
          path_params[var_segment] = path[last_index:end].to_string() catch {
            _ => abort("String slice failed")
          }
          Some(var_node)
        }
      }
    }
  }

  for index, c in path.iter2() {
    if c == '/' {
      if last_index <= index {
        node = match push_segment(last_index, index) {
          Some(n) => n
          None => return None
        }
      }
      last_index = index + 1
    }
  }
  if last_index <= path.length() {
    node = match push_segment(last_index, path.length()) {
      Some(n) => n
      None => return None
    }
  }
  match node.handler {
    None => return None
    Some(_) => Some((node, path_params))
  }
}

///|
/// Dispatches a location to the appropriate handler
/// Parses the provided location string, matches it against registered routes,
/// and invokes the corresponding handler with extracted parameters
pub fn[A] Router::dispatch(
  self : Router[A],
  location : String,
) -> A raise DispatchError {
  let (path, query, fragment) = (try? parse_location(location))
    .map_err(fn(e) { DispatchError::InvalidLocation(e) })
    .unwrap_or_error()
  let query_params = match query {
    Some(q) =>
      (try? parse_query(q))
      .map_err(fn(e) { DispatchError::InvalidQuery(e) })
      .unwrap_or_error()
    None => []
  }
  let (node, path_params) = match self.match_route_with_params(path) {
    Some(n) => n
    None => raise DispatchError::RouteNotMatched(path)
  }
  let handler = node.handler.unwrap()
  return handler(path_params, query_params, fragment)
}
