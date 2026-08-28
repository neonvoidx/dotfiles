# Cline Variant Config Surfaces

## Content Paths (shared across all variants)

| Scope | Content | Path |
|---|---|---|
| Project | Rules | `.clinerules/` |
| Project | Workflows | `.clinerules/workflows/` |
| Project | Skills | `.clinerules/skills/` |
| Global | Rules | `~/Documents/Cline/Rules/` |
| Global | Workflows | `~/Documents/Cline/Workflows/` |
| Global | Skills | `~/.cline/skills/` |

All three variants read the same content directories. The Cline core reads `.clinerules/` from the project root regardless of which IDE (or no IDE) hosts it.

## MCP Settings Paths (diverge by variant)

| Variant | macOS | Linux |
|---|---|---|
| VS Code | `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` | `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` |
| IntelliJ | `~/.cline/data/settings/cline_mcp_settings.json` | `~/.cline/data/settings/cline_mcp_settings.json` |
| CLI | `~/.cline/data/settings/cline_mcp_settings.json` | `~/.cline/data/settings/cline_mcp_settings.json` |

IntelliJ and CLI share a path because both run via cline-core standalone mode, which uses `~/.cline/data/` as its storage root. VS Code uses the extension's `globalStorage` convention.

## MCP JSON Format

Identical across all variants:
```json
{
  "mcpServers": {
    "<name>": {
      "command": "...",
      "args": ["..."],
      "env": {"KEY": "VALUE"},
      "alwaysAllow": ["tool1"],
      "disabled": false,
      "timeout": 300,
      "type": "stdio"
    }
  }
}
```

## Cline CLI Limitations (per AICODE docs, 2026-03-18)

- MCP integration explicitly listed as "not currently supported" on the AICODE page — but the underlying cline-core supports it via `~/.cline/data/settings/`
- No GUI for provider config — uses `cline auth` interactive wizard
- `cline config` subcommand exists but is undocumented on AICODE
- Remote SSH: N/A (runs locally)

## Sources

- AICODE Confluence pages (see oca-harness-catalog.md for page IDs)
- GitHub issues cline/cline#7929 and #7249 (confirm `~/.cline/data/` path for JetBrains)
