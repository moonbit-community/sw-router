///|
pub extend AddRouteError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AddRouteError with Eq::{not_equal, equal}

///|
pub extend AddRouteError with Show::{to_string, output}

///|
pub extend DispatchError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend DispatchError with Eq::{not_equal, equal}

///|
pub extend DispatchError with Show::{to_string, output}

///|
pub extend LocationParseError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend LocationParseError with Eq::{not_equal, equal}

///|
pub extend LocationParseError with Show::{to_string, output}

///|
pub extend QueryParseError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend QueryParseError with Eq::{not_equal, equal}

///|
pub extend QueryParseError with Show::{to_string, output}
