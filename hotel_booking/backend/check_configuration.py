"""Audit local integration configuration without changing data or contacting providers."""
import argparse
import json
import os
from pathlib import Path

from pydantic import ValidationError
from app.core.config import Settings
from app.services.configuration import audit, load_client


def main():
    root = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--client-config', type=Path, default=root.parent / 'config/flutter.local.json')
    parser.add_argument('--client-only', action='store_true', help='Validate a client JSON file without loading backend settings.')
    parser.add_argument('--require', nargs='+', choices=['google', 'facebook', 'recovery', 'push', 'momo', 'vnpay', 'media_upload', 'pdf_report', 'online_refund'])
    args = parser.parse_args()
    # Resolve caller-supplied paths before changing the working directory.
    client_path = args.client_config.resolve()
    client = {}
    if client_path.is_file():
        try:
            client = load_client(client_path)
        except (OSError, ValueError):
            print('Client configuration is invalid. Use only the keys/types in config/flutter.example.json. Values withheld.')
            return 2
    elif args.client_only:
        print('Client configuration file not found.')
        return 2
    if args.client_only:
        firebase = ['FIREBASE_API_KEY', 'FIREBASE_APP_ID', 'FIREBASE_MESSAGING_SENDER_ID', 'FIREBASE_PROJECT_ID']
        if any(client.get(key) for key in firebase) and not all(client.get(key) for key in firebase):
            print('Firebase client configuration is incomplete: provide all four FIREBASE_* fields.')
            return 2
        if client.get('FACEBOOK_ENABLED') and not all(client.get(key) for key in ['TTTP_FACEBOOK_APP_ID', 'TTTP_FACEBOOK_CLIENT_TOKEN']):
            print('Facebook is enabled but its public Android settings are missing.')
            return 2
        print('Client configuration structure is valid; provider connectivity is not verified.')
        return 0
    os.chdir(root)
    try:
        report = audit(Settings(), client)
    except (ValidationError, OSError, ValueError):
        print('Backend configuration is invalid. Check backend/.env; values withheld.')
        return 2
    print(json.dumps({'features': report, 'live_provider_tests_performed': False}, indent=2))
    return 1 if args.require and any(not report[name]['ready'] for name in args.require) else 0


if __name__ == '__main__':
    raise SystemExit(main())
