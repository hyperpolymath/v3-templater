;; v3-templater - Guix Package Definition
;; Run: guix shell -D -f guix.scm

(use-modules (guix packages)
             (guix gexp)
             (guix git-download)
             (guix build-system node)
             ((guix licenses) #:prefix license:)
             (gnu packages base))

(define-public v3_templater
  (package
    (name "v3-templater")
    (version "0.1.0")
    (source (local-file "." "v3-templater-checkout"
                        #:recursive? #t
                        #:select? (git-predicate ".")))
    (build-system node-build-system)
    (synopsis "ReScript application")
    (description "ReScript application - part of the RSR ecosystem.")
    (home-page "https://github.com/hyperpolymath/v3-templater")
    (license license:agpl3+)))

;; Return package for guix shell
v3_templater
