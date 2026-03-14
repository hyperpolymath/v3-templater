;; SPDX-License-Identifier: PMPL-1.0-or-later
;; ECOSYSTEM.scm - Ecosystem position for v3-templater
;; Media-Type: application/vnd.ecosystem+scm

(ecosystem
  (version "1.0")
  (name "v3-templater")
  (type "library")
  (purpose "Secure, high-performance templating engine built with ReScript and Deno")

  (position-in-ecosystem
    (category "developer-tools")
    (subcategory "templating")
    (unique-value "Type-safe templating with ReScript compilation and Deno runtime"))

  (related-projects
    ((name . "preference-injector")
     (relationship . "sibling-standard")
     (nature . "Configuration injection, complementary to template rendering")))

  (what-this-is
    "A modern templating engine supporting Mustache/Handlebars/EJS syntax with auto-escaping, filter chains, template inheritance, and LRU caching.")

  (what-this-is-not
    "Not a full frontend framework. Not a static site generator. Not a replacement for React/Vue rendering."))
