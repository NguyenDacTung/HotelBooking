"""Build the action-only progress recording script as a Word document."""
from build_feature_catalog import ROOT, build

if __name__ == '__main__':
    build(ROOT/'docs/KICH_BAN_QUAY_TIEN_DO_TETRA.md',
          ROOT/'artifacts/TETRA_KICH_BAN_QUAY_TIEN_DO.docx', catalogue=False)
