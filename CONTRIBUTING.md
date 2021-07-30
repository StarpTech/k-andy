# Contribution Guide

This guide describes necessary tools and processes to contribute to this project.

## Development Setup

### Required tools

The following tools are necessary for working with this repository:

- [terraform](https://www.terraform.io) (for obvious reasons)
- [pre-commit](https://pre-commit.com/#install) (to run linter/docs)
  - this requires a python installation
- [terraform-docs](https://terraform-docs.io/user-guide/installation/) (to create the inputs/outputs table)

### pre-commit

Before you commit, run `pre-commit run -a`.

You can also do that automatically before each commit with `pre-commit install`.

