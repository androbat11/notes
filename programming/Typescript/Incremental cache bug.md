# TypeScript Incremental Cache

When `incremental: true` is set in `tsconfig.json`, TypeScript writes a `.tsbuildinfo` file after compilation that stores build state to avoid recompiling unchanged files.

## What it stores

- Hashes of each source file's content
- The resolved module dependency graph
- Semantic diagnostics (errors) per file
- Emit output hashes to skip re-emitting unchanged files

## How it works

On each build TypeScript:
1. Hashes all source files
2. Compares against the stored `.tsbuildinfo` snapshot
3. Re-type-checks and re-emits only files that changed or depend on changed files

## Configuration

```json
{
  "compilerOptions": {
    "incremental": true,
    "tsBuildInfoFile": "./.tsbuildinfo"
  }
}
```

## `incremental` vs `composite`

| Option | Use case |
|--------|----------|
| `incremental` | Single project, faster rebuilds |
| `composite` | Multi-project references (`tsc -b`); implies `incremental` |

## Limitations

- Cache is invalidated when `tsconfig.json` options change
- `.tsbuildinfo` can grow large in big projects
- Not shared across machines if absolute paths are embedded
- Independent from bundler caches (webpack, esbuild, etc.)
