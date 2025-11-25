#!/usr/bin/env python3
"""
Script to post Datadog alert definitions to Slack as formatted messages
This is useful for sharing alert configurations with your team
"""

import json
import requests
import argparse
import sys
from typing import Dict, List, Any


class SlackAlertPoster:
    """Posts alert definitions to Slack"""
    
    def __init__(self, webhook_url: str = None, token: str = None, channel: str = None):
        self.webhook_url = webhook_url
        self.token = token
        self.channel = channel
        
        if not webhook_url and not token:
            raise ValueError("Either webhook_url or token must be provided")
        
        if token and not channel:
            raise ValueError("Channel is required when using token")
    
    def format_alert_block(self, alert: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Format alert as Slack Block Kit message"""
        
        # Priority emoji mapping
        priority_emoji = {
            "P1": "🔴",
            "P2": "🟠",
            "P3": "🟡"
        }
        
        # Alert type emoji mapping
        alert_type_emoji = {
            "metric alert": "📊",
            "log alert": "📝",
            "anomaly alert": "🔍"
        }
        
        priority = alert.get("priority", "P3")
        alert_type = alert.get("type", "metric alert")
        
        blocks = [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"{priority_emoji.get(priority, '⚪')} {alert['name']}",
                    "emoji": True
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": f"*Type:*\n{alert_type_emoji.get(alert_type, '📌')} {alert_type}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Priority:*\n{priority}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Critical Threshold:*\n{alert.get('thresholds', {}).get('critical', 'N/A')}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Warning Threshold:*\n{alert.get('thresholds', {}).get('warning', 'N/A')}"
                    }
                ]
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Description:*\n{alert.get('description', 'No description')}"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Query:*\n```{alert['query'][:500]}{'...' if len(alert['query']) > 500 else ''}```"
                }
            }
        ]
        
        # Add tags
        if alert.get('tags'):
            tags_text = " • ".join([f"`{tag}`" for tag in alert['tags'][:5]])
            blocks.append({
                "type": "context",
                "elements": [
                    {
                        "type": "mrkdwn",
                        "text": f"Tags: {tags_text}"
                    }
                ]
            })
        
        # Add divider
        blocks.append({"type": "divider"})
        
        return blocks
    
    def format_summary_block(self, alerts: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Format summary of all alerts"""
        
        # Count by priority
        priority_counts = {"P1": 0, "P2": 0, "P3": 0}
        for alert in alerts:
            priority = alert.get("priority", "P3")
            priority_counts[priority] = priority_counts.get(priority, 0) + 1
        
        # Count by type
        type_counts = {}
        for alert in alerts:
            alert_type = alert.get("type", "unknown")
            type_counts[alert_type] = type_counts.get(alert_type, 0) + 1
        
        blocks = [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": "🚨 Datadog Alert Configurations",
                    "emoji": True
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Total Alerts:* {len(alerts)}\n\n*By Priority:*\n🔴 P1 (Critical): {priority_counts['P1']}\n🟠 P2 (High): {priority_counts['P2']}\n🟡 P3 (Warning): {priority_counts['P3']}"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "*By Type:*\n" + "\n".join([f"• {type_name}: {count}" for type_name, count in type_counts.items()])
                }
            },
            {
                "type": "divider"
            }
        ]
        
        return blocks
    
    def post_to_slack(self, blocks: List[Dict[str, Any]], text: str = "Alert Configuration") -> Dict[str, Any]:
        """Post message to Slack"""
        
        if self.webhook_url:
            # Use Webhook URL method
            payload = {
                "text": text,
                "blocks": blocks
            }
            
            try:
                response = requests.post(self.webhook_url, json=payload)
                response.raise_for_status()
                return {"success": True, "status_code": response.status_code}
            except requests.exceptions.RequestException as e:
                return {"success": False, "error": str(e)}
        
        elif self.token:
            # Use OAuth Token method (chat.postMessage API)
            payload = {
                "channel": self.channel,
                "text": text,
                "blocks": blocks
            }
            
            headers = {
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json"
            }
            
            try:
                response = requests.post(
                    "https://slack.com/api/chat.postMessage",
                    headers=headers,
                    json=payload
                )
                response.raise_for_status()
                data = response.json()
                
                if data.get("ok"):
                    return {"success": True, "status_code": response.status_code}
                else:
                    return {"success": False, "error": data.get("error", "Unknown error")}
            except requests.exceptions.RequestException as e:
                return {"success": False, "error": str(e)}
    
    def post_alerts(self, alerts_file: str, summary_only: bool = False) -> Dict[str, Any]:
        """Post all alerts to Slack"""
        
        # Load alerts
        try:
            with open(alerts_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except Exception as e:
            return {"success": False, "error": f"Failed to load alerts file: {e}"}
        
        alerts = data.get("alerts", [])
        results = {
            "total": len(alerts),
            "posted": 0,
            "failed": 0
        }
        
        # Post summary
        print(f"\nPosting summary to Slack...")
        summary_blocks = self.format_summary_block(alerts)
        result = self.post_to_slack(summary_blocks, "Datadog Alert Configurations Summary")
        
        if result["success"]:
            print(f"✓ Summary posted successfully")
            results["posted"] += 1
        else:
            print(f"✗ Failed to post summary: {result.get('error')}")
            results["failed"] += 1
        
        if summary_only:
            return results
        
        # Post individual alerts
        print(f"\nPosting {len(alerts)} individual alerts to Slack...\n")
        
        for idx, alert in enumerate(alerts, 1):
            alert_name = alert.get("name", f"Alert {idx}")
            print(f"[{idx}/{len(alerts)}] Posting: {alert_name}")
            
            blocks = self.format_alert_block(alert)
            result = self.post_to_slack(blocks, alert_name)
            
            if result["success"]:
                print(f"  ✓ Posted successfully")
                results["posted"] += 1
            else:
                print(f"  ✗ Failed: {result.get('error')}")
                results["failed"] += 1
            
            # Rate limiting - don't spam Slack
            import time
            time.sleep(1)
        
        return results


def select_alerts_interactive(alerts: List[Dict[str, Any]]) -> List[int]:
    """Interactive alert selection"""
    
    print(f"\n{'='*80}")
    print("AVAILABLE ALERTS")
    print(f"{'='*80}\n")
    
    for idx, alert in enumerate(alerts, 1):
        priority_emoji = {"P1": "🔴", "P2": "🟠", "P3": "🟡"}.get(alert.get("priority", "P3"), "⚪")
        print(f"[{idx}] {priority_emoji} {alert['name']}")
        print(f"    Type: {alert['type']} | Priority: {alert.get('priority', 'N/A')}")
        print()
    
    print(f"{'='*80}\n")
    print("Enter alert numbers to post (comma-separated), 'all' for all alerts, or 'q' to quit")
    print("Examples: 1,3,5  or  1-3  or  all")
    
    while True:
        user_input = input("\nYour selection: ").strip().lower()
        
        if user_input == 'q':
            print("Cancelled.")
            sys.exit(0)
        
        if user_input == 'all':
            return list(range(1, len(alerts) + 1))
        
        try:
            selected = []
            parts = user_input.split(',')
            
            for part in parts:
                part = part.strip()
                if '-' in part:
                    # Handle range (e.g., 1-3)
                    start, end = part.split('-')
                    selected.extend(range(int(start), int(end) + 1))
                else:
                    # Handle single number
                    selected.append(int(part))
            
            # Validate selections
            if all(1 <= num <= len(alerts) for num in selected):
                return sorted(set(selected))  # Remove duplicates and sort
            else:
                print(f"❌ Invalid selection. Please enter numbers between 1 and {len(alerts)}")
        except ValueError:
            print("❌ Invalid format. Use comma-separated numbers (e.g., 1,3,5) or ranges (e.g., 1-3)")


def main():
    parser = argparse.ArgumentParser(
        description="Post Datadog alert configurations to Slack",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Using Webhook URL
  python post_alerts_to_slack.py --webhook-url YOUR_WEBHOOK --interactive
  python post_alerts_to_slack.py --webhook-url YOUR_WEBHOOK --alerts 1,3,5
  
  # Using OAuth Token
  python post_alerts_to_slack.py --token YOUR_TOKEN --channel #alerts --interactive
  python post_alerts_to_slack.py --token YOUR_TOKEN --channel C1234567890 --alerts 1,9
  
  # Post specific alerts by index (1-based)
  python post_alerts_to_slack.py --webhook-url YOUR_WEBHOOK --alerts 1,3,5
  
  # Post range of alerts
  python post_alerts_to_slack.py --token YOUR_TOKEN --channel #alerts --alerts 1-3
  
  # Post summary only
  python post_alerts_to_slack.py --webhook-url YOUR_WEBHOOK --summary-only
  
  # Use environment variables
  export SLACK_TOKEN=xoxb-your-token
  export SLACK_CHANNEL=#alerts
  python post_alerts_to_slack.py --interactive
  
  # Or with webhook
  export SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK
  python post_alerts_to_slack.py --alerts 1,9

How to get Slack credentials:
  Webhook URL:
    1. Go to https://api.slack.com/apps
    2. Create app → Incoming Webhooks → Add to channel
  
  OAuth Token:
    1. Go to https://api.slack.com/apps
    2. Create app → OAuth & Permissions
    3. Add scopes: chat:write, chat:write.public
    4. Install to workspace → Copy Bot User OAuth Token
        """
    )
    
    parser.add_argument(
        "--webhook-url",
        help="Slack Webhook URL (or set SLACK_WEBHOOK_URL env var)",
        default=None
    )
    parser.add_argument(
        "--token",
        help="Slack OAuth Token (or set SLACK_TOKEN env var)",
        default=None
    )
    parser.add_argument(
        "--channel",
        help="Slack channel ID or name (required with --token, e.g., C1234567890 or #alerts)",
        default=None
    )
    parser.add_argument(
        "--file",
        help="Path to alerts JSON file (default: datadog-alerts.json)",
        default="datadog-alerts.json"
    )
    parser.add_argument(
        "--summary-only",
        help="Post only summary, not individual alerts",
        action="store_true"
    )
    parser.add_argument(
        "--interactive",
        "-i",
        help="Interactive mode - select alerts to post",
        action="store_true"
    )
    parser.add_argument(
        "--alerts",
        "-a",
        help="Specific alert indices to post (e.g., 1,3,5 or 1-3)",
        default=None
    )
    parser.add_argument(
        "--list",
        "-l",
        help="List all alerts and exit",
        action="store_true"
    )
    
    args = parser.parse_args()
    
    # Load alerts first for list/interactive modes
    try:
        with open(args.file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error: Failed to load alerts file: {e}")
        sys.exit(1)
    
    alerts = data.get("alerts", [])
    
    # List mode - just show alerts and exit
    if args.list:
        print(f"\n{'='*80}")
        print(f"ALERTS IN {args.file}")
        print(f"{'='*80}\n")
        
        for idx, alert in enumerate(alerts, 1):
            priority_emoji = {"P1": "🔴", "P2": "🟠", "P3": "🟡"}.get(alert.get("priority", "P3"), "⚪")
            print(f"[{idx}] {priority_emoji} {alert['name']}")
            print(f"    Type: {alert['type']}")
            print(f"    Priority: {alert.get('priority', 'N/A')}")
            print(f"    Description: {alert.get('description', 'N/A')[:80]}...")
            print()
        
        print(f"Total: {len(alerts)} alerts\n")
        sys.exit(0)
    
    # Get Slack credentials
    import os
    webhook_url = args.webhook_url or os.environ.get("SLACK_WEBHOOK_URL")
    token = args.token or os.environ.get("SLACK_TOKEN")
    channel = args.channel or os.environ.get("SLACK_CHANNEL")
    
    # Validate credentials
    if not webhook_url and not token:
        print("Error: Either Slack webhook URL or token is required")
        print("\nOption 1 - Webhook URL:")
        print("  --webhook-url YOUR_WEBHOOK")
        print("  or set SLACK_WEBHOOK_URL environment variable")
        print("\nOption 2 - OAuth Token:")
        print("  --token YOUR_TOKEN --channel #your-channel")
        print("  or set SLACK_TOKEN and SLACK_CHANNEL environment variables")
        print("\nTo get credentials:")
        print("  Webhook: https://api.slack.com/apps → Incoming Webhooks")
        print("  Token: https://api.slack.com/apps → OAuth & Permissions")
        sys.exit(1)
    
    if token and not channel:
        print("Error: Channel is required when using token")
        print("Provide via --channel #your-channel or set SLACK_CHANNEL environment variable")
        sys.exit(1)
    
    # Determine which alerts to post
    selected_indices = None
    
    if args.interactive:
        # Interactive mode
        selected_indices = select_alerts_interactive(alerts)
    elif args.alerts:
        # Command-line specified alerts
        try:
            selected = []
            parts = args.alerts.split(',')
            
            for part in parts:
                part = part.strip()
                if '-' in part:
                    # Handle range (e.g., 1-3)
                    start, end = part.split('-')
                    selected.extend(range(int(start), int(end) + 1))
                else:
                    # Handle single number
                    selected.append(int(part))
            
            # Validate selections
            if all(1 <= num <= len(alerts) for num in selected):
                selected_indices = sorted(set(selected))
            else:
                print(f"Error: Invalid alert index. Please use numbers between 1 and {len(alerts)}")
                sys.exit(1)
        except ValueError:
            print("Error: Invalid format. Use comma-separated numbers (e.g., 1,3,5) or ranges (e.g., 1-3)")
            sys.exit(1)
    
    # Create poster
    poster = SlackAlertPoster(webhook_url=webhook_url, token=token, channel=channel)
    
    print(f"\n{'='*80}")
    print("POSTING ALERTS TO SLACK")
    print(f"{'='*80}")
    
    # Post based on mode
    if selected_indices:
        # Post only selected alerts
        results = {
            "total": len(selected_indices),
            "posted": 0,
            "failed": 0
        }
        
        print(f"\nPosting {len(selected_indices)} selected alert(s) to Slack...\n")
        
        for idx in selected_indices:
            alert = alerts[idx - 1]  # Convert to 0-based index
            alert_name = alert.get("name", f"Alert {idx}")
            print(f"[{idx}] Posting: {alert_name}")
            
            blocks = poster.format_alert_block(alert)
            result = poster.post_to_slack(blocks, alert_name)
            
            if result["success"]:
                print(f"  ✓ Posted successfully")
                results["posted"] += 1
            else:
                print(f"  ✗ Failed: {result.get('error')}")
                results["failed"] += 1
            
            # Rate limiting
            import time
            time.sleep(1)
    else:
        # Post all or summary only (original behavior)
        results = poster.post_alerts(args.file, args.summary_only)
    
    # Print summary
    print(f"\n{'='*80}")
    print("POSTING SUMMARY")
    print(f"{'='*80}")
    print(f"Total alerts: {results['total']}")
    print(f"Successfully posted: {results['posted']}")
    print(f"Failed: {results['failed']}")
    print(f"{'='*80}\n")
    
    if results["posted"] > 0:
        print("✓ Alerts posted to Slack successfully!")
    
    sys.exit(0 if results["failed"] == 0 else 1)


if __name__ == "__main__":
    main()
