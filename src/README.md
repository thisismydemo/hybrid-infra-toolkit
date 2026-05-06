# Source Layout

This directory is the planned home for reusable implementation code in Hybrid Infrastructure Toolkit.

## Structure

- `deployments/` contains tool-specific deployment implementations
- `platform/` contains shared code, validation, and orchestration used across deployment categories

## Configuration

All deployments in this directory consume configuration from `configs/variables/variables.yml`.

## Status

Directory structure is in place. Implementation has not started. New code should follow the standards in `docs/standards/engineering-standards.md` and the design guidance in `docs/design/`.
