# Deployment Categories

This directory separates deployment implementations by toolchain.

Planned categories:

- `bicep`
- `terraform`
- `powershell-azurecli`
- `dsc`
- `ansible`
- `arm`

Design rule:

Every category should map to the same platform concepts and environment model instead of inventing its own resource and topology semantics.
