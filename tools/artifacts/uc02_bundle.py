#!/usr/bin/env python3
"""
UC02 artifact bundler.

Reads the cloud-specific UC02 discovery outputs and emits a stable, cross-cloud
"artifact bundle" (normalized inventory + summary + scorecard + diagram).

This is intentionally conservative: it summarizes counts and key identifiers,
and keeps cloud-specific details in "extensions".
"""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Optional


SCHEMA_VERSION = "1.0"


def utc_now_rfc3339() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def read_json(p: Path) -> Dict[str, Any]:
    return json.loads(p.read_text(encoding="utf-8"))


def write_json(p: Path, obj: Any) -> None:
    p.write_text(json.dumps(obj, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_text(p: Path, s: str) -> None:
    p.write_text(s.rstrip() + "\n", encoding="utf-8")


def env_git_sha() -> str:
    return (
        os.environ.get("GITHUB_SHA")
        or os.environ.get("TOOLKIT_GIT_SHA")
        or "unknown"
    )


@dataclass
class Bundle:
    normalized_inventory: Dict[str, Any]
    summary_md: str
    scorecard_md: str
    diagram_mmd: str
    metadata: Dict[str, Any]


def safe_len(v: Any) -> int:
    return len(v) if isinstance(v, list) else 0


def normalize_aws(raw: Dict[str, Any]) -> Bundle:
    generated_at = raw.get("meta", {}).get("generated_at") or utc_now_rfc3339()
    region = raw.get("meta", {}).get("region", "")

    account_id = raw.get("identity", {}).get("account_id", "")
    account_alias = raw.get("identity", {}).get("account_alias", "")
    caller_arn = raw.get("identity", {}).get("caller", {}).get("Arn", "")

    role_name = raw.get("iam", {}).get("discovery_role_name", "")
    attached = raw.get("iam", {}).get("attached_policies", []) or raw.get("iam", {}).get("attached_policies", {}).get("AttachedPolicies", [])
    attached_policy_count = safe_len(attached)

    vpcs = raw.get("network", {}).get("vpcs", [])
    subnets = raw.get("network", {}).get("subnets", [])
    sgs = raw.get("network", {}).get("security_groups", [])
    eips = raw.get("network", {}).get("elastic_ips", [])
    nats = raw.get("network", {}).get("nat_gateways", [])
    vpc_endpoints = raw.get("network", {}).get("vpc_endpoints", [])

    ec2 = raw.get("compute", {}).get("ec2_instances", [])
    lbs = raw.get("compute", {}).get("load_balancers_v2", [])

    normalized = {
        "schema_version": SCHEMA_VERSION,
        "meta": {
            "generated_at": generated_at,
            "toolkit_git_sha": env_git_sha(),
        },
        "scope": {
            "cloud": "aws",
            "region": region,
            "account_id": account_id,
        },
        "counts": {
            "network": {
                "vpcs": safe_len(vpcs),
                "subnets": safe_len(subnets),
                "security_groups": safe_len(sgs),
                "public_ips": safe_len(eips),
                "nat_gateways": safe_len(nats),
                "vpc_endpoints": safe_len(vpc_endpoints),
            },
            "compute": {
                "instances": safe_len(ec2),
                "load_balancers": safe_len(lbs),
            },
            "iam": {
                "discovery_role_name": role_name,
                "attached_policies": attached_policy_count,
            },
        },
        "extensions": {
            "account_alias": account_alias,
            "caller_arn": caller_arn,
        },
    }

    summary = "\n".join(
        [
            "# UC02 Inventory Bundle (AWS)",
            "",
            f"- Generated: `{generated_at}`",
            f"- Account: `{account_id}`" + (f" (alias: `{account_alias}`)" if account_alias else ""),
            f"- Region: `{region}`",
            f"- Toolkit Git SHA: `{env_git_sha()}`",
            "",
            "## Totals",
            f"- Network: VPCs **{safe_len(vpcs)}**, Subnets **{safe_len(subnets)}**, SGs **{safe_len(sgs)}**, Public IPs **{safe_len(eips)}**, NAT Gateways **{safe_len(nats)}**, VPC Endpoints **{safe_len(vpc_endpoints)}**",
            f"- Compute: EC2 Instances **{safe_len(ec2)}**, Load Balancers (v2) **{safe_len(lbs)}**",
            f"- IAM: Discovery Role `{role_name}`, Attached Policies **{attached_policy_count}**",
            "",
            "## Files",
            "- `metadata.json`: bundle metadata",
            "- `inventory.json`: normalized inventory (stable schema)",
            "- `SCORECARD.md`: best-effort findings",
            "- `diagram.mmd`: Mermaid diagram",
            "",
        ]
    )

    # Minimal best-effort checks from the discovery payload.
    trust_doc = (
        raw.get("iam", {})
        .get("role", {})
        .get("Role", {})
        .get("AssumeRolePolicyDocument", {})
    )
    trust_str = json.dumps(trust_doc, sort_keys=True)
    has_actions_oidc = "token.actions.githubusercontent.com" in trust_str
    sub_wildcard = '"sub"' in trust_str and "*" in trust_str

    findings = []
    if not has_actions_oidc:
        findings.append("- `HIGH`: OIDC trust for `token.actions.githubusercontent.com` not detected in role trust policy (or role not readable).")
    if sub_wildcard:
        findings.append("- `MEDIUM`: OIDC subject conditions appear to include wildcard matching. Tighten `sub` patterns to repo/ref/environment as appropriate.")
    if safe_len(eips) > 0:
        findings.append("- `LOW`: Public IPs detected. Confirm they are intentional and governed (ingress controls, logging, ownership).")

    if not findings:
        findings.append("- `INFO`: No findings from the current lightweight checks.")

    scorecard = "\n".join(
        [
            "# UC02 Scorecard (AWS)",
            "",
            "This is a lightweight, best-effort scorecard derived from discovery outputs. Treat as hints, not an audit.",
            "",
            "## Findings",
            *findings,
            "",
        ]
    )

    diagram = "\n".join(
        [
            "flowchart LR",
            f'  A["AWS Account\\n{account_id}"]',
            f'  N["Network\\nVPCs: {safe_len(vpcs)}\\nSubnets: {safe_len(subnets)}\\nPublic IPs: {safe_len(eips)}"]',
            f'  C["Compute\\nEC2: {safe_len(ec2)}\\nELBv2: {safe_len(lbs)}"]',
            f'  I["IAM\\nRole: {role_name}"]',
            "  A --> N",
            "  A --> C",
            "  A --> I",
            "",
        ]
    )

    metadata = {
        "artifact_version": SCHEMA_VERSION,
        "generated_at": generated_at,
        "toolkit_git_sha": env_git_sha(),
        "cloud": "aws",
        "scope": {"account_id": account_id, "region": region},
    }
    return Bundle(normalized, summary, scorecard, diagram, metadata)


def normalize_azure(raw: Dict[str, Any]) -> Bundle:
    meta = raw.get("meta", {})
    generated_at = meta.get("generated_at") or utc_now_rfc3339()

    subscription_id = meta.get("subscription_id", "")
    subscription_name = meta.get("subscription_name", "")
    tenant_id = meta.get("tenant_id", "")
    user = meta.get("user", "")

    rgs = raw.get("resource_groups", [])
    resources = raw.get("resources", [])
    vnets = raw.get("network", {}).get("vnets", [])
    public_ips = raw.get("network", {}).get("public_ips", [])
    nsgs = raw.get("network", {}).get("nsgs", [])
    vms = raw.get("compute", {}).get("virtual_machines", [])
    sas = raw.get("storage", {}).get("accounts", [])
    kvs = raw.get("security", {}).get("key_vaults", [])

    normalized = {
        "schema_version": SCHEMA_VERSION,
        "meta": {"generated_at": generated_at, "toolkit_git_sha": env_git_sha()},
        "scope": {
            "cloud": "azure",
            "subscription_id": subscription_id,
            "tenant_id": tenant_id,
            "regions": [loc.get("name") for loc in (raw.get("locations") or []) if isinstance(loc, dict) and loc.get("name")],
        },
        "counts": {
            "network": {
                "vnets": safe_len(vnets),
                "public_ips": safe_len(public_ips),
                "nsgs": safe_len(nsgs),
            },
            "compute": {"virtual_machines": safe_len(vms)},
            "iam": {},
        },
        "extensions": {
            "subscription_name": subscription_name,
            "caller": user,
            "resource_groups": safe_len(rgs),
            "resources": safe_len(resources),
            "storage_accounts": safe_len(sas),
            "key_vaults": safe_len(kvs),
        },
    }

    summary = "\n".join(
        [
            "# UC02 Inventory Bundle (Azure)",
            "",
            f"- Generated: `{generated_at}`",
            f"- Subscription: `{subscription_name}` (`{subscription_id}`)",
            f"- Tenant: `{tenant_id}`",
            f"- Caller: `{user}`",
            f"- Toolkit Git SHA: `{env_git_sha()}`",
            "",
            "## Totals",
            f"- Resource Groups: **{safe_len(rgs)}**, Resources: **{safe_len(resources)}**",
            f"- Network: VNets **{safe_len(vnets)}**, Public IPs **{safe_len(public_ips)}**, NSGs **{safe_len(nsgs)}**",
            f"- Compute: Virtual Machines **{safe_len(vms)}**",
            f"- Storage/Security: Storage Accounts **{safe_len(sas)}**, Key Vaults **{safe_len(kvs)}**",
            "",
            "## Files",
            "- `metadata.json`: bundle metadata",
            "- `inventory.json`: normalized inventory (stable schema)",
            "- `SCORECARD.md`: best-effort findings",
            "- `diagram.mmd`: Mermaid diagram",
            "",
        ]
    )

    findings = []
    if safe_len(public_ips) > 0:
        findings.append("- `LOW`: Public IPs detected. Confirm exposure is intentional (NSGs, WAF, logging).")
    if safe_len(kvs) == 0:
        findings.append("- `INFO`: No Key Vaults detected in the subscription (may be expected).")
    if not findings:
        findings.append("- `INFO`: No findings from the current lightweight checks.")

    scorecard = "\n".join(
        [
            "# UC02 Scorecard (Azure)",
            "",
            "This is a lightweight, best-effort scorecard derived from discovery outputs. Treat as hints, not an audit.",
            "",
            "## Findings",
            *findings,
            "",
        ]
    )

    diagram = "\n".join(
        [
            "flowchart LR",
            f'  A["Azure Subscription\\n{subscription_name}\\n{subscription_id}"]',
            f'  N["Network\\nVNets: {safe_len(vnets)}\\nPublic IPs: {safe_len(public_ips)}"]',
            f'  C["Compute\\nVMs: {safe_len(vms)}"]',
            '  S["Storage/Security\\nStorage Accounts / Key Vaults"]',
            "  A --> N",
            "  A --> C",
            "  A --> S",
            "",
        ]
    )

    metadata = {
        "artifact_version": SCHEMA_VERSION,
        "generated_at": generated_at,
        "toolkit_git_sha": env_git_sha(),
        "cloud": "azure",
        "scope": {"subscription_id": subscription_id, "tenant_id": tenant_id},
    }
    return Bundle(normalized, summary, scorecard, diagram, metadata)


def normalize_gcp(raw: Dict[str, Any]) -> Bundle:
    meta = raw.get("meta", {})
    generated_at = meta.get("generated_at") or utc_now_rfc3339()

    project_id = meta.get("project_id", "")
    region = meta.get("region", "")

    sas = raw.get("iam", {}).get("service_accounts", [])
    vpcs = raw.get("network", {}).get("vpcs", [])
    subnets = raw.get("network", {}).get("subnets", [])
    fw = raw.get("network", {}).get("firewall_rules", [])
    instances = raw.get("compute", {}).get("instances", [])

    normalized = {
        "schema_version": SCHEMA_VERSION,
        "meta": {"generated_at": generated_at, "toolkit_git_sha": env_git_sha()},
        "scope": {"cloud": "gcp", "project_id": project_id, "region": region},
        "counts": {
            "network": {
                "vpcs": safe_len(vpcs),
                "subnets": safe_len(subnets),
                "firewall_rules": safe_len(fw),
            },
            "compute": {"instances": safe_len(instances)},
            "iam": {"service_accounts": safe_len(sas)},
        },
        "extensions": {},
    }

    summary = "\n".join(
        [
            "# UC02 Inventory Bundle (GCP)",
            "",
            f"- Generated: `{generated_at}`",
            f"- Project: `{project_id}`",
            f"- Region: `{region}`",
            f"- Toolkit Git SHA: `{env_git_sha()}`",
            "",
            "## Totals",
            f"- IAM: Service Accounts **{safe_len(sas)}**",
            f"- Network: VPCs **{safe_len(vpcs)}**, Subnets **{safe_len(subnets)}**, Firewall Rules **{safe_len(fw)}**",
            f"- Compute: Instances **{safe_len(instances)}**",
            "",
            "## Files",
            "- `metadata.json`: bundle metadata",
            "- `inventory.json`: normalized inventory (stable schema)",
            "- `SCORECARD.md`: best-effort findings",
            "- `diagram.mmd`: Mermaid diagram",
            "",
        ]
    )

    findings = []
    if safe_len(fw) == 0:
        findings.append("- `INFO`: No firewall rules detected (may be expected in minimal projects).")
    if not findings:
        findings.append("- `INFO`: No findings from the current lightweight checks.")

    scorecard = "\n".join(
        [
            "# UC02 Scorecard (GCP)",
            "",
            "This is a lightweight, best-effort scorecard derived from discovery outputs. Treat as hints, not an audit.",
            "",
            "## Findings",
            *findings,
            "",
        ]
    )

    diagram = "\n".join(
        [
            "flowchart LR",
            f'  P["GCP Project\\n{project_id}"]',
            f'  N["Network\\nVPCs: {safe_len(vpcs)}\\nSubnets: {safe_len(subnets)}"]',
            f'  C["Compute\\nInstances: {safe_len(instances)}"]',
            f'  I["IAM\\nService Accounts: {safe_len(sas)}"]',
            "  P --> N",
            "  P --> C",
            "  P --> I",
            "",
        ]
    )

    metadata = {
        "artifact_version": SCHEMA_VERSION,
        "generated_at": generated_at,
        "toolkit_git_sha": env_git_sha(),
        "cloud": "gcp",
        "scope": {"project_id": project_id, "region": region},
    }
    return Bundle(normalized, summary, scorecard, diagram, metadata)


def bundle_for_cloud(cloud: str, raw: Dict[str, Any]) -> Bundle:
    cloud = cloud.lower().strip()
    if cloud == "aws":
        return normalize_aws(raw)
    if cloud == "azure":
        return normalize_azure(raw)
    if cloud == "gcp":
        return normalize_gcp(raw)
    raise SystemExit(f"Unsupported cloud: {cloud}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cloud", required=True, choices=["aws", "azure", "gcp"])
    ap.add_argument("--raw-inventory", required=True, help="Path to UC02 raw inventory.json")
    ap.add_argument("--out-dir", default="out/artifacts", help="Output folder for the artifact bundle")
    args = ap.parse_args()

    raw_inventory_path = Path(args.raw_inventory).resolve()
    out_dir = Path(args.out_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    raw = read_json(raw_inventory_path)
    bundle = bundle_for_cloud(args.cloud, raw)

    write_json(out_dir / "metadata.json", bundle.metadata)
    write_json(out_dir / "inventory.json", bundle.normalized_inventory)
    write_text(out_dir / "SUMMARY.md", bundle.summary_md)
    write_text(out_dir / "SCORECARD.md", bundle.scorecard_md)
    write_text(out_dir / "diagram.mmd", bundle.diagram_mmd)

    print(f"Wrote bundle: {out_dir}")


if __name__ == "__main__":
    main()

