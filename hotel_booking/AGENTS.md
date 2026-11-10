# TETRA Hotel Contributor Guide

## Architecture and Layout

- The Flutter Android application lives at the repository root alongside `pubspec.yaml`. It uses Provider for state management and a Vietnamese user interface.
- `lib/app/` contains application composition; `lib/core/` contains shared configuration and utilities; `lib/models/` contains data models.
- `lib/screens/` and `lib/widgets/` contain the UI; `lib/providers/` manages state; `lib/repositories/` and `lib/services/` handle data access and service integrations. Follow the existing separation when adding features.
- `backend/` contains FastAPI, SQLAlchemy, Alembic, and PostgreSQL integration. Within `backend/app/`, `api/` contains endpoints, `schemas/` contains request and response schemas, `services/` contains business logic, `models/` contains ORM models, `core/` contains configuration and security, and `db/` contains database connection code.
- `backend/alembic/versions/` contains migrations; `test/` and `backend/tests/` contain Flutter and backend tests.
- Consult `docs/business_rules.md`, `docs/permission_matrix.md`, `docs/api.md`, and `docs/test_cases.md` as relevant to the change. The README includes historical instructions; verify them against the current configuration and source code.

## Change Guidelines

- Preserve the Vietnamese UI, existing structure, and behavior outside the requested scope. Do not expand changes into unrelated features.
- Check Git status before editing and preserve the user's existing changes.
- Change the database schema through new Alembic migrations. Do not modify applied migrations or substitute `create_all` for migrations.
- Do not manually edit generated files, virtual environments, or build artifacts. When regeneration is needed, use the corresponding tool within the requested scope.
- Do not commit, push, or deploy unless requested by the user.

## Data Preservation and Security

- PostgreSQL is the backend database; do not replace it with SQLite.
- Do not reset, delete, TRUNCATE, or downgrade the development database `hotel_booking`. Back up existing data before applying migrations.
- Seeding is an explicit operation and must not run automatically at startup. Preserve existing data, accounts, and passwords; changing `DEMO_PASSWORD` and rerunning the seed does not reset existing account passwords.
- Run integration tests only against `hotel_booking_test`. Preserve the test runner's actual database checks and development data comparison safeguards.
- Do not commit or print `.env` contents, passwords, tokens, service keys, password hashes, or personal information in logs, chat, or documentation. Keep only configuration examples without secrets in `.env.example`.
- Do not commit virtual environments, uploads, private uploads, backups, or build artifacts. Do not record session-specific LAN IP addresses, device IDs, or passwords in general instructions.

## Windows Commands

The following commands use PowerShell. Prepare local configuration before running them; do not overwrite an existing `backend/.env`. Invoke the virtual environment's Python directly to avoid activation or machine-wide ExecutionPolicy changes.

### Flutter - From the Repository Root

```powershell
flutter pub get
flutter analyze
flutter test
```

To run on a physical Android phone, check `flutter devices`, use the backend computer's current LAN IP address, and replace the placeholders:

```powershell
flutter run -d <DEVICE_ID> --debug --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=http://<LAN_IP>:8000
```

The phone and computer must be able to reach each other over the network. Check `/health/db` in the phone's browser before diagnosing application errors. When changing `API_BASE_URL`, stop the old session and run/build again; hot reload does not update this value. Allow the API port through the firewall on a private network only when needed; do not expose the PostgreSQL port to the phone.

### Backend - From `backend/`

Install dependencies into the prepared `.venv` environment:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Apply migrations after checking database configuration and backing up existing data:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade head
```

Start the API for LAN access:

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Check `http://127.0.0.1:8000/health/db` to confirm PostgreSQL connectivity; `/health` checks only server liveness. API documentation is available at `http://127.0.0.1:8000/docs`. A successful health check does not replace migration and business behavior verification.

## Testing and Reporting

- For Flutter changes, run `flutter analyze` and relevant tests; use `flutter test` for changes affecting multiple flows.
- Run PostgreSQL tests through the runner from `backend/` to isolate the subprocess to the test database and compare development data before and after:

```powershell
.\.venv\Scripts\python.exe manage_local.py test-postgres
```

- The runner requires an available `hotel_booking_test` database. `manage_local.py prepare` can create the test database and seed the development database; use it only for intentional data preparation, not as a read-only check.
- For targeted backend testing, use `manage_local.py test-postgres --only tests/<test_file>.py` to retain the runner's safeguards.
- Do not count PostgreSQL tests skipped due to missing configuration as passed. Do not claim physical device or external service verification unless performed.
- For documentation-only changes, check commands, paths, sensitive content, and the diff; running the full test suite or accessing the database is unnecessary.
- Before finishing, review `git status --short` and `git diff` to confirm scope. Inspect new untracked files separately because ordinary `git diff` does not display them. Do not stage changes merely to view a diff.
- Report what changed, which checks ran, their results, and anything that remains unverified.
