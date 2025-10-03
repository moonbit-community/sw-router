///|
priv struct TrieNode[A] {
  handler : Handler[A]? // root node has no handler
  children : @hashmap.HashMap[String, TrieNode[A]]
  mut variable_child : (String, TrieNode[A])?
}

///|
fn[A] TrieNode::create_root() -> TrieNode[A] {
  TrieNode::{ handler: None, children: @hashmap.new(), variable_child: None }
}

///|
fn[A] TrieNode::create_with_handler(handler : Handler[A]) -> TrieNode[A] {
  TrieNode::{
    handler: Some(handler),
    children: @hashmap.new(),
    variable_child: None,
  }
}
