#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "httpx>=0.27",
# ]
# ///
"""bws → Infisical Cloud secret import script.

Usage (dry-run):
    INFISICAL_CLIENT_ID=... INFISICAL_CLIENT_SECRET=... \\
      uv run claude/skills/infisical-cli/scripts/import-from-bws.py \\
      --memo memo.json --dry-run

See claude/skills/infisical-cli/SKILL.md for the full migration plan.
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import httpx

DEFAULT_API_URL = "https://app.infisical.com"
HTTP_TIMEOUT = 30.0
MASK = "****"

log = logging.getLogger("import-from-bws")


@dataclass
class BwsProject:
    id: str
    name: str


@dataclass
class BwsSecret:
    key: str
    value: str
    note: str
    project_ids: list[str]


@dataclass
class InfisicalWorkspace:
    id: str
    name: str


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Import secrets from a bws memo.json export into Infisical Cloud.",
    )
    p.add_argument("--memo", required=True, type=Path, help="Path to memo.json")
    p.add_argument("--dry-run", action="store_true", help="Plan only, do not write")
    p.add_argument("--env", default="prod", help="Infisical environment slug")
    p.add_argument(
        "--workspace-id",
        default=None,
        help="Force a single Infisical workspace id (skip name matching)",
    )
    p.add_argument(
        "--only-project",
        action="append",
        default=[],
        help="Limit to bws project name(s); repeatable",
    )
    p.add_argument(
        "--allow-update",
        action="store_true",
        help="PATCH existing keys instead of skipping",
    )
    p.add_argument(
        "--api-url",
        default=os.environ.get("INFISICAL_API_URL", DEFAULT_API_URL),
        help="Infisical API base URL",
    )
    p.add_argument("--verbose", "-v", action="store_true", help="Verbose logging")
    return p.parse_args(argv)


def load_memo(path: Path) -> tuple[list[BwsProject], list[BwsSecret]]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    projects = [BwsProject(id=p["id"], name=p["name"]) for p in raw.get("projects", [])]
    secrets = [
        BwsSecret(
            key=s["key"],
            value=s["value"],
            note=s.get("note", "") or "",
            project_ids=list(s.get("projectIds", [])),
        )
        for s in raw.get("secrets", [])
    ]
    return projects, secrets


def infisical_login(client: httpx.Client, api_url: str, client_id: str, client_secret: str) -> str:
    url = f"{api_url.rstrip('/')}/api/v1/auth/universal-auth/login"
    resp = client.post(url, json={"clientId": client_id, "clientSecret": client_secret})
    if resp.status_code >= 400:
        raise RuntimeError(
            f"Infisical login failed: HTTP {resp.status_code} {resp.text[:200]}"
        )
    token = resp.json().get("accessToken")
    if not token:
        raise RuntimeError("Infisical login response missing accessToken")
    return token


def list_workspaces(client: httpx.Client, api_url: str, token: str) -> list[InfisicalWorkspace]:
    url = f"{api_url.rstrip('/')}/api/v1/workspace"
    resp = client.get(url, headers={"Authorization": f"Bearer {token}"})
    if resp.status_code >= 400:
        raise RuntimeError(
            f"Failed to list workspaces: HTTP {resp.status_code} {resp.text[:200]}"
        )
    body = resp.json()
    items = body.get("workspaces") or body.get("data") or []
    out: list[InfisicalWorkspace] = []
    for w in items:
        wid = w.get("id") or w.get("_id")
        name = w.get("name")
        if wid and name:
            out.append(InfisicalWorkspace(id=wid, name=name))
    return out


def upsert_secret(
    client: httpx.Client,
    api_url: str,
    token: str,
    workspace_id: str,
    environment: str,
    key: str,
    value: str,
    comment: str,
    allow_update: bool,
) -> str:
    """Return one of: created / updated / skipped / failed."""
    headers = {"Authorization": f"Bearer {token}"}
    base = f"{api_url.rstrip('/')}/api/v3/secrets/raw/{key}"
    body: dict[str, Any] = {
        "workspaceId": workspace_id,
        "environment": environment,
        "secretValue": value,
        "type": "shared",
    }
    if comment:
        body["secretComment"] = comment

    resp = client.post(base, json=body, headers=headers)
    if resp.status_code in (200, 201):
        return "created"

    text = resp.text or ""
    already_exists = (
        resp.status_code in (400, 409)
        and ("already exist" in text.lower() or "duplicate" in text.lower())
    )
    if already_exists:
        if not allow_update:
            log.warning("skip existing key=%s ws=%s", key, workspace_id)
            return "skipped"
        patch_body = {
            "workspaceId": workspace_id,
            "environment": environment,
            "secretValue": value,
            "type": "shared",
        }
        if comment:
            patch_body["secretComment"] = comment
        patch = client.patch(base, json=patch_body, headers=headers)
        if patch.status_code in (200, 201):
            return "updated"
        log.error(
            "update failed key=%s ws=%s status=%s body=%s",
            key, workspace_id, patch.status_code, patch.text[:200],
        )
        return "failed"

    log.error(
        "create failed key=%s ws=%s status=%s body=%s",
        key, workspace_id, resp.status_code, text[:200],
    )
    return "failed"


def build_workspace_map(
    bws_projects: list[BwsProject],
    infisical_workspaces: list[InfisicalWorkspace],
    only_projects: list[str],
    forced_workspace_id: str | None,
) -> dict[str, InfisicalWorkspace]:
    """Map bws project id -> Infisical workspace."""
    if forced_workspace_id:
        forced = next((w for w in infisical_workspaces if w.id == forced_workspace_id), None)
        if not forced:
            raise RuntimeError(f"--workspace-id={forced_workspace_id} not found in Infisical")
        return {p.id: forced for p in bws_projects if (not only_projects or p.name in only_projects)}

    by_name = {w.name: w for w in infisical_workspaces}
    mapping: dict[str, InfisicalWorkspace] = {}
    missing: list[str] = []
    for p in bws_projects:
        if only_projects and p.name not in only_projects:
            continue
        ws = by_name.get(p.name)
        if not ws:
            missing.append(p.name)
            continue
        mapping[p.id] = ws
    if missing:
        raise RuntimeError(
            "Infisical workspace not found for bws project(s): "
            + ", ".join(missing)
            + " (use --only-project to skip them)"
        )
    return mapping


def print_table(rows: list[tuple[str, str, str, str]]) -> None:
    headers = ("Infisical Project", "Environment", "Secret Key", "Action")
    widths = [len(h) for h in headers]
    for r in rows:
        for i, cell in enumerate(r):
            widths[i] = max(widths[i], len(cell))
    fmt = " | ".join(f"{{:<{w}}}" for w in widths)
    print(fmt.format(*headers))
    print("-+-".join("-" * w for w in widths))
    for r in rows:
        print(fmt.format(*r))


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    logging.basicConfig(
        level=logging.INFO if args.verbose else logging.WARNING,
        format="%(levelname)s %(message)s",
    )

    if not args.memo.exists():
        print(f"memo file not found: {args.memo}", file=sys.stderr)
        return 2

    bws_projects, bws_secrets = load_memo(args.memo)
    if not bws_projects:
        print("memo.json has no projects", file=sys.stderr)
        return 2

    client_id = os.environ.get("INFISICAL_CLIENT_ID")
    client_secret = os.environ.get("INFISICAL_CLIENT_SECRET")
    if not client_id or not client_secret:
        print(
            "INFISICAL_CLIENT_ID / INFISICAL_CLIENT_SECRET must be set in env",
            file=sys.stderr,
        )
        return 2

    with httpx.Client(timeout=HTTP_TIMEOUT) as client:
        token = infisical_login(client, args.api_url, client_id, client_secret)
        log.info("logged in to %s", args.api_url)

        workspaces = list_workspaces(client, args.api_url, token)
        ws_map = build_workspace_map(
            bws_projects, workspaces, args.only_project, args.workspace_id
        )

        print("# Project mapping (bws → Infisical)")
        print_table(
            [
                (ws_map[p.id].name, args.env, "(workspace)", f"id={ws_map[p.id].id}")
                for p in bws_projects
                if p.id in ws_map
            ]
        )
        print()

        rows: list[tuple[str, str, str, str]] = []
        results = {"created": 0, "updated": 0, "skipped": 0, "failed": 0}

        for sec in bws_secrets:
            for pid in sec.project_ids:
                ws = ws_map.get(pid)
                if not ws:
                    continue
                if args.dry_run:
                    rows.append((ws.name, args.env, sec.key, f"create ({MASK})"))
                    results["created"] += 1
                    continue
                outcome = upsert_secret(
                    client,
                    args.api_url,
                    token,
                    workspace_id=ws.id,
                    environment=args.env,
                    key=sec.key,
                    value=sec.value,
                    comment=sec.note,
                    allow_update=args.allow_update,
                )
                results[outcome] += 1
                rows.append((ws.name, args.env, sec.key, outcome))

        if args.dry_run:
            print("# Plan (dry-run)")
        else:
            print("# Result")
        print_table(rows)
        print()
        total = sum(results.values())
        print(
            f"total={total} create={results['created']} "
            f"update={results['updated']} skip={results['skipped']} "
            f"fail={results['failed']}"
        )

    if results["failed"] > 0:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
