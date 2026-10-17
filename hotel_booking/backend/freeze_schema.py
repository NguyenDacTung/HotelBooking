"""Development tool: freeze initial SQL before publishing migration 0001."""
from pathlib import Path
from sqlalchemy.schema import CreateTable, CreateIndex
from sqlalchemy.dialects import postgresql
from app.db.session import Base
import app.models  # noqa

sql = ['CREATE EXTENSION IF NOT EXISTS btree_gist;']
for table in Base.metadata.sorted_tables:
    sql.append(str(CreateTable(table).compile(dialect=postgresql.dialect())) + ';')
    for index in sorted(table.indexes, key=lambda x: x.name):
        sql.append(str(CreateIndex(index).compile(dialect=postgresql.dialect())) + ';')
sql.append('''
CREATE FUNCTION verify_account_profile() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE account_id uuid; kind varchar; customers integer; employees integer;
BEGIN
  IF TG_OP = 'DELETE' THEN account_id := OLD.id; ELSE account_id := NEW.id; END IF;
  SELECT loai_tai_khoan INTO kind FROM tai_khoan WHERE id = account_id;
  IF NOT FOUND THEN RETURN NULL; END IF;
  SELECT count(*) INTO customers FROM khach_hang WHERE id = account_id;
  SELECT count(*) INTO employees FROM nhan_vien WHERE id = account_id;
  IF NOT ((kind = 'KHACH_HANG' AND customers = 1 AND employees = 0)
       OR (kind = 'NHAN_VIEN' AND customers = 0 AND employees = 1)) THEN
    RAISE EXCEPTION 'Account must have exactly one matching profile' USING ERRCODE = '23514';
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.id IS DISTINCT FROM NEW.id THEN
    SELECT loai_tai_khoan INTO kind FROM tai_khoan WHERE id = OLD.id;
    IF FOUND THEN
      SELECT count(*) INTO customers FROM khach_hang WHERE id = OLD.id;
      SELECT count(*) INTO employees FROM nhan_vien WHERE id = OLD.id;
      IF NOT ((kind = 'KHACH_HANG' AND customers = 1 AND employees = 0)
           OR (kind = 'NHAN_VIEN' AND customers = 0 AND employees = 1)) THEN
        RAISE EXCEPTION 'Old account lost its matching profile' USING ERRCODE = '23514';
      END IF;
    END IF;
  END IF;
  RETURN NULL;
END $$;
''')
for table in ('tai_khoan', 'khach_hang', 'nhan_vien'):
    sql.append(f'''CREATE CONSTRAINT TRIGGER ck_profile_{table}
AFTER INSERT OR UPDATE OR DELETE ON {table}
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION verify_account_profile();''')
Path('alembic/versions/0001_schema.sql').write_text('\n\n'.join(sql), encoding='utf-8')
