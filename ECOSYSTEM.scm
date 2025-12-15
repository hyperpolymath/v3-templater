;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;; ECOSYSTEM.scm — v3-templater

(ecosystem
  (version "1.0.0")
  (name "v3-templater")
  (type "project")
  (purpose "A modern, secure, and high-performance templating engine built with ReScript and Deno. Zero TypeScript, zero Node.js.")

  (position-in-ecosystem
    "Part of hyperpolymath ecosystem. Follows RSR guidelines.")

  (related-projects
    (project (name "rhodium-standard-repositories")
             (url "https://github.com/hyperpolymath/rhodium-standard-repositories")
             (relationship "standard")))

  (what-this-is "A modern, secure, and high-performance templating engine built with ReScript and Deno. Zero TypeScript, zero Node.js.")
  (what-this-is-not "- NOT exempt from RSR compliance"))
