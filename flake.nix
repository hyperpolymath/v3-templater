{
  description = "v3-templater - Modern, secure, high-performance templating engine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        nodejs = pkgs.nodejs_20;

        buildInputs = with pkgs; [
          nodejs
          just
          git
        ];

        devDependencies = with pkgs; [
          # Development tools
          nodePackages.typescript
          nodePackages.eslint
          nodePackages.prettier

          # Testing
          nodePackages.jest

          # Utilities
          jq
          ripgrep
        ];

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = buildInputs ++ devDependencies;

          shellHook = ''
            echo "🚀 v3-templater development environment"
            echo ""
            echo "Node.js version: $(node --version)"
            echo "npm version: $(npm --version)"
            echo ""
            echo "Quick start:"
            echo "  npm install    - Install dependencies"
            echo "  npm run build  - Build the project"
            echo "  npm test       - Run tests"
            echo "  just --list    - Show all tasks"
            echo ""
            echo "📊 RSR Compliance: SILVER level (target: GOLD)"
            echo "🔒 TPCF Perimeter: 3 (Community Sandbox)"
            echo ""
          '';
        };

        # Package
        packages.default = pkgs.buildNpmPackage {
          pname = "v3-templater";
          version = "1.0.0";

          src = ./.;

          npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          # To update: nix-prefetch-url --unpack https://github.com/Hyperpolymath/v3-templater/archive/main.tar.gz

          buildInputs = [ nodejs ];

          buildPhase = ''
            npm run build
          '';

          installPhase = ''
            mkdir -p $out/bin $out/lib
            cp -r dist/* $out/lib/
            cp package.json $out/lib/

            # Create wrapper script for CLI
            cat > $out/bin/v3t << EOF
            #!/usr/bin/env node
            require('$out/lib/cli.js');
            EOF
            chmod +x $out/bin/v3t
          '';

          checkPhase = ''
            npm test
          '';

          meta = with pkgs.lib; {
            description = "Modern, secure, high-performance templating engine";
            homepage = "https://github.com/Hyperpolymath/v3-templater";
            license = [ licenses.mit ];
            maintainers = [ ];
            platforms = platforms.all;
          };
        };

        # Apps
        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/v3t";
        };

        # Checks (run with: nix flake check)
        checks = {
          build = self.packages.${system}.default;

          # RSR compliance check
          rsr-compliance = pkgs.runCommand "rsr-compliance-check" {
            buildInputs = [ pkgs.just ];
          } ''
            cd ${./.}
            just rsr-check > $out
          '';
        };

        # Formatters
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
