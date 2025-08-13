///|
test "basic router" {
  let router = @sw_router.router([
    ("/test", fn { _path, _query, _fragment => "main" }),
  ])
  let str = router.dispatch("/test")
  assert_eq(str, "main")
}

///|
test "router with query and fragment" {
  let router = @sw_router.router([
    (
      "/hello/foo",
      fn {
        path, query, fragment =>
          "PATH_\{path}__QUERY_\{query}__FRAGMENT_\{fragment}"
      },
    ),
  ])
  let str = router.dispatch("/hello/foo?bar=baz#query")
  assert_eq(
    str,
    (
      #|PATH_{}__QUERY_[("bar", "baz")]__FRAGMENT_Some("query")
    ),
  )
}

///|
test "router with and without trailing slash" {
  let router = @sw_router.router([
    ("/hello/foo", fn { _path, _query, _fragment => "with trailing slash" }),
    ("/hello/foo/", fn { _path, _query, _fragment => "without trailing slash" }),
  ])
  let str = router.dispatch("/hello/foo")
  assert_eq(str, "with trailing slash")
  let str2 = router.dispatch("/hello/foo/")
  assert_eq(str2, "without trailing slash")
}

// TODO: wait for HashSet to be implemented
// test "panic duplicate path parameters" {
//   @sw_router.router!([("/hello/:foo/:foo", fn { _path, _query, _fragment => () })])
//   |> ignore
// }

///|
test "panic two path parameters at the same level" {
  @sw_router.router([
    ("/hello/:foo", fn { _path, _query, _fragment => () }),
    ("/hello/:bar", fn { _path, _query, _fragment => () }),
  ])
  |> ignore
}

///|
test "path parameter" {
  let router = @sw_router.router([
    (
      "/:foo/:bar",
      fn {
        path, _query, _fragment => {
          let foo = path.get("foo").unwrap()
          let bar = path.get("bar").unwrap()
          "FOO_\{foo}__BAR_\{bar}"
        }
      },
    ),
  ])
  let str = router.dispatch("/hello/world")
  assert_eq(str, "FOO_hello__BAR_world")
}
