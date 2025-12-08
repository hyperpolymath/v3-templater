/**
 * Template caching mechanism (ReScript)
 * LRU (Least Recently Used) cache implementation
 */

open Types

type cacheState = {
  cache: Js.Dict.t<compiledTemplate>,
  mutable accessOrder: array<string>,
  maxSize: int,
}

// Create a new cache
let make = (~maxSize: int=100, ()): cacheState => {
  {
    cache: Js.Dict.empty(),
    accessOrder: [],
    maxSize: maxSize,
  }
}

// Update access order for LRU
let updateAccessOrder = (state: cacheState, key: string): unit => {
  // Remove key if it exists
  let filtered = Js.Array.filter(k => k != key, state.accessOrder)
  // Add key to end (most recently used)
  state.accessOrder = Js.Array.concat([key], filtered)
}

// Get a cached template
let get = (state: cacheState, key: string): option<compiledTemplate> => {
  switch Js.Dict.get(state.cache, key) {
  | Some(template) =>
    updateAccessOrder(state, key)
    Some(template)
  | None => None
  }
}

// Set a template in cache
let set = (state: cacheState, key: string, template: compiledTemplate): unit => {
  let hasKey = switch Js.Dict.get(state.cache, key) {
  | Some(_) => true
  | None => false
  }

  // Check if we need to evict
  let cacheSize = Js.Array.length(Js.Dict.keys(state.cache))
  if cacheSize >= state.maxSize && !hasKey {
    // Evict least recently used (first in access order)
    switch state.accessOrder[0] {
    | Some(lruKey) =>
      Js.Dict.unsafeDeleteKey(state.cache, lruKey)
      state.accessOrder = Js.Array.sliceFrom(1, state.accessOrder)
    | None => ()
    }
  }

  // Set the template
  Js.Dict.set(state.cache, key, template)
  updateAccessOrder(state, key)
}

// Check if cache has a key
let has = (state: cacheState, key: string): bool => {
  switch Js.Dict.get(state.cache, key) {
  | Some(_) => true
  | None => false
  }
}

// Clear the cache
let clear = (state: cacheState): unit => {
  let keys = Js.Dict.keys(state.cache)
  Js.Array.forEach(key => Js.Dict.unsafeDeleteKey(state.cache, key), keys)
  state.accessOrder = []
}

// Get cache size
let size = (state: cacheState): int => {
  Js.Array.length(Js.Dict.keys(state.cache))
}

// Get all keys (for debugging)
let keys = (state: cacheState): array<string> => {
  Js.Dict.keys(state.cache)
}
