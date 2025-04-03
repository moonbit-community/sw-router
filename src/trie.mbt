///|
priv struct TrieNode[A] {
  handler : Handler[A]? // root node has no handler
  children : @hashmap.T[String, TrieNode[A]]
  mut variable_child : (String, TrieNode[A])?
}

///|
fn TrieNode::create_root[A]() -> TrieNode[A] {
  TrieNode::{ handler: None, children: @hashmap.new(), variable_child: None }
}

///|
fn TrieNode::create_with_handler[A](handler : Handler[A]) -> TrieNode[A] {
  TrieNode::{
    handler: Some(handler),
    children: @hashmap.new(),
    variable_child: None,
  }
}
