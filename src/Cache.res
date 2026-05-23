// SPDX-License-Identifier: MPL-2.0
/**
 * Template caching mechanism (ReScript)
 * LRU (Least Recently Used) cache implementation
 */

open Types

type cacheState = {
  cache: Dict.t<compiledTemplate>,
  mutable accessOrder: array<string>,
  maxSize: int,
}

// Create a new cache
let make = (~maxSize: int=100, ()): cacheState => {
  {
    cache: Dict.empty(),
    accessOrder: [],
    maxSize: maxSize,
  }
}

// Update access order for LRU
let updateAccessOrder = (state: cacheState, key: string): unit => {
  // Remove key if it exists
  let filtered = state.accessOrder->Array.filter(k => k != key)
  // Add key to end (most recently used)
  state.accessOrder = Array.concat(filtered, [key])
}

// Get a cached template
let get = (state: cacheState, key: string): option<compiledTemplate> => {
  switch Dict.get(state.cache, key) {
  | Some(template) =>
    updateAccessOrder(state, key)
    Some(template)
  | None => None
  }
}

// Set a template in cache
let set = (state: cacheState, key: string, template: compiledTemplate): unit => {
  let hasKey = switch Dict.get(state.cache, key) {
  | Some(_) => true
  | None => false
  }

  // Check if we need to evict
  let cacheSize = Array.length(Dict.keys(state.cache))
  if cacheSize >= state.maxSize && !hasKey {
    // Evict least recently used (first in access order)
    switch state.accessOrder[0] {
    | Some(lruKey) =>
      Dict.unsafeDeleteKey(state.cache, lruKey)
      state.accessOrder = Array.sliceFrom(state.accessOrder, 1)
    | None => ()
    }
  }

  // Set the template
  Dict.set(state.cache, key, template)
  updateAccessOrder(state, key)
}

// Check if cache has a key
let has = (state: cacheState, key: string): bool => {
  switch Dict.get(state.cache, key) {
  | Some(_) => true
  | None => false
  }
}

// Clear the cache
let clear = (state: cacheState): unit => {
  let keys = Dict.keys(state.cache)
  keys->Array.forEach(key => Dict.unsafeDeleteKey(state.cache, key))
  state.accessOrder = []
}

// Get cache size
let size = (state: cacheState): int => {
  Array.length(Dict.keys(state.cache))
}

// Get all keys (for debugging)
let keys = (state: cacheState): array<string> => {
  Dict.keys(state.cache)
}
