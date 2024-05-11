{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    zig.url = "github:mitchellh/zig-overlay";
  };

  outputs = { self, nixpkgs, zig }: {
    devShells.x86_64-linux.default = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      zigCompiler = zig.packages.x86_64-linux."0.11.0";
      llvm = pkgs.llvmPackages_7;
    in pkgs.mkShell {
      buildInputs = [
        pkgs.bash
        llvm.clang
        llvm.llvm
        llvm.lld
        llvm.lldb
        pkgs.just
        zigCompiler
      ];
    };
  };
}
