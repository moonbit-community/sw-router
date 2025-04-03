# 🚀 SW Router: A Lightweight MoonBit Router Library

[English](https://github.com/moonbit-community/sw-router/blob/main/README.md) | [简体中文](https://github.com/moonbit-community/sw-router/blob/main/README_zh_CN.md)

[![Build Status](https://img.shields.io/github/actions/workflow/status/moonbit-community/sw-router/check.yaml)](https://github.com/moonbit-community/sw-router/actions)
[![License](https://img.shields.io/github/license/moonbit-community/sw-router)](LICENSE)
[![codecov](https://codecov.io/gh/moonbit-community/sw-router/branch/main/graph/badge.svg)](https://codecov.io/gh/moonbit-community/sw-router)

**SW Router** is a lightweight and efficient routing library for MoonBit applications. It provides a simple way to handle routing in your MoonBit projects with a clean and intuitive API.

🚀 **Key Features**

- 🛠️ **Simple API** - Easy to learn and use
- 🚄 **Fast Performance** - Optimized for speed
- 🎯 **Pattern Matching** - Support for route parameters
- 🌟 **MoonBit Native** - Built specifically for MoonBit

---

## 📥 Installation

```
moon add ShellWen/sw-router
```

## **🚀 Usage Guide**

SW Router makes it simple to define and handle routes in your MoonBit applications.

### **🔍 Basic Usage**

```moonbit
fn main {
  let router = @sw_router.router?([
    ("/test", fn { _path, _query, _fragment => "main" }),
    (
      "/:foo/:bar",
      fn {
        path, query, fragment => {
          let foo = path.get("foo").unwrap()
          let bar = path.get("bar").unwrap()
          let flat_query = query.map(fn { (k, v) => k + "=" + v }).join("&")
          let fragment = fragment.or("")
          "FOO_\{foo}__BAR_\{bar}__QUERY_\{flat_query}__FRAGMENT_\{fragment}"
        }
      },
    ),
  ]).unwrap()
  let str = router.dispatch!("/test")
  assert_eq!(str, "main")
  let str = router.dispatch!("/hello/world?param=value&a=b#fragment")
  assert_eq!(str, "FOO_hello__BAR_world__QUERY_param=value&a=b__FRAGMENT_fragment")
}
```

## 📚 Inspiration

This project is inspired by modern routing libraries and aims to provide a similar experience for MoonBit developers.

## 📜 License

This project is licensed under the Apache-2.0 License. See [LICENSE](https://github.com/moonbit-community/sw-router/blob/main/LICENSE) for details.

## 📢 Contact & Support

- GitHub Issues: [Report an issue](https://github.com/moonbit-community/sw-router/issues)

👋 If you like this project, give it a ⭐! Happy coding! 🚀
