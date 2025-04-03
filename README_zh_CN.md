# 🚀 SW Router: 轻量级 MoonBit 路由库

[English](https://github.com/moonbit-community/sw-router/blob/main/README.md) | [简体中文](https://github.com/moonbit-community/sw-router/blob/main/README_zh_CN.md)

[![Build Status](https://img.shields.io/github/actions/workflow/status/moonbit-community/sw-router/check.yaml)](https://github.com/moonbit-community/sw-router/actions)
[![License](https://img.shields.io/github/license/moonbit-community/sw-router)](LICENSE)
[![codecov](https://codecov.io/gh/moonbit-community/sw-router/branch/main/graph/badge.svg)](https://codecov.io/gh/moonbit-community/sw-router)

**SW Router** 是一个轻量级且高效的 MoonBit 路由库。它为您的 MoonBit 项目提供了一种简单的路由处理方式，具有清晰直观的 API。

🚀 **主要特性**

- 🛠️ **简单的 API** - 易学易用
- 🚄 **高性能** - 经过性能优化
- 🎯 **模式匹配** - 支持路由参数
- 🌟 **MoonBit 原生** - 专为 MoonBit 打造

---

## 📥 安装

```
moon add ShellWen/sw-router
```

## **🚀 使用指南**

SW Router 让您能够轻松地在 MoonBit 应用程序中定义和处理路由。

### **🔍 基本用法**

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

## 📚 灵感来源

该项目受现代路由库的启发，旨在为 MoonBit 开发者提供类似的开发体验。

## 📜 许可证

本项目根据 Apache-2.0 许可证获得许可。有关详细信息，请参见 [LICENSE](https://github.com/moonbit-community/sw-router/blob/main/LICENSE)。

## 📢 联系方式 & 支持

- GitHub Issues: [报告问题](https://github.com/moonbit-community/sw-router/issues)

👋 如果你喜欢这个项目，给它一个 ⭐! 祝你编码愉快! 🚀
