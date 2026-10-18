"""Create the Vietnamese feature catalogue as a dependency-free Word document."""
from __future__ import annotations

import re
from pathlib import Path
from xml.etree import ElementTree as ET
from xml.sax.saxutils import escape
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs/TETRA_DANH_MUC_CHUC_NANG_2026-10-18.md'
OUTPUT = ROOT / 'artifacts/TETRA_DANH_MUC_CHUC_NANG_VA_LUONG_NGHIEP_VU_2026-10-18.docx'
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'


def xml(body: str) -> str:
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + body


def run(text: str, bold: bool = False, size: int | None = None) -> str:
    props = ('<w:b/>' if bold else '') + (f'<w:sz w:val="{size}"/>' if size else '')
    return f'<w:r><w:rPr>{props}</w:rPr><w:t xml:space="preserve">{escape(text)}</w:t></w:r>'


def paragraph(text: str, style: str = 'Normal', *, page_break: bool = False,
              cell: bool = False, bold: bool = False) -> str:
    props = f'<w:pStyle w:val="{style}"/>'
    if page_break:
        props += '<w:pageBreakBefore/>'
    if cell:
        props += '<w:spacing w:before="30" w:after="45" w:line="240" w:lineRule="auto"/>'
    text = text.replace('`', '')
    return f'<w:p><w:pPr>{props}</w:pPr>{run(text, bold, 20 if cell else None)}</w:p>'


def table(rows: list[list[str]]) -> str:
    cols = len(rows[0])
    if cols == 2:
        widths = [2600, 7260]
    else:
        widths = [1400, 2900, 5560]
    assert cols == len(widths)
    props = ('<w:tblPr><w:tblW w:w="9860" w:type="dxa"/>'
             '<w:tblLayout w:type="fixed"/><w:tblBorders>'
             '<w:top w:val="single" w:sz="5" w:color="D7E0E7"/>'
             '<w:left w:val="single" w:sz="5" w:color="D7E0E7"/>'
             '<w:bottom w:val="single" w:sz="5" w:color="D7E0E7"/>'
             '<w:right w:val="single" w:sz="5" w:color="D7E0E7"/>'
             '<w:insideH w:val="single" w:sz="4" w:color="D7E0E7"/>'
             '<w:insideV w:val="single" w:sz="4" w:color="D7E0E7"/>'
             '</w:tblBorders><w:tblCellMar>'
             '<w:top w:w="65" w:type="dxa"/><w:left w:w="95" w:type="dxa"/>'
             '<w:bottom w:w="65" w:type="dxa"/><w:right w:w="95" w:type="dxa"/>'
             '</w:tblCellMar></w:tblPr>')
    grid = '<w:tblGrid>' + ''.join(f'<w:gridCol w:w="{v}"/>' for v in widths) + '</w:tblGrid>'
    result = []
    for index, row in enumerate(rows):
        assert len(row) == cols, row
        cells = []
        for width, text in zip(widths, row):
            shade = 'E3EBF0' if index == 0 else ('F4F7FA' if index % 2 == 0 else 'FFFFFF')
            tc = (f'<w:tcPr><w:tcW w:w="{width}" w:type="dxa"/>'
                  f'<w:shd w:fill="{shade}"/><w:vAlign w:val="top"/></w:tcPr>')
            cells.append('<w:tc>' + tc + paragraph(text, cell=True, bold=index == 0) + '</w:tc>')
        row_props = '<w:cantSplit/>' + ('<w:tblHeader/>' if index == 0 else '')
        result.append(f'<w:tr><w:trPr>{row_props}</w:trPr>{"".join(cells)}</w:tr>')
    return '<w:tbl>' + props + grid + ''.join(result) + '</w:tbl>' + paragraph('', 'Spacer')


def build(source: Path = SOURCE, output: Path = OUTPUT, *, catalogue: bool = True) -> None:
    lines = source.read_text(encoding='utf8').splitlines()
    body: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        if line.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                row = [v.strip() for v in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r':?-+:?', v) for v in row):
                    rows.append(row)
                i += 1
            body.append(table(rows))
            continue
        if i == 0:
            body.append(paragraph(line.lstrip('# '), 'Title'))
        elif line.startswith('# '):
            body.append(paragraph(line[2:], 'Heading1', page_break=True))
        elif line.startswith('## '):
            title = line[3:]
            body.append(paragraph(title, 'Subtitle' if i == 1 else 'Heading2',
                                  page_break=title == 'Mục lục'))
        elif line.startswith('### '):
            body.append(paragraph(line[4:], 'Heading3'))
        elif line.startswith('- '):
            body.append(paragraph('• ' + line[2:], 'ListParagraph'))
        elif re.match(r'^\d+\. ', line):
            body.append(paragraph(line, 'ListParagraph'))
        elif line.startswith('`'):
            body.append(paragraph(line, 'Code'))
        else:
            body.append(paragraph(line))
        i += 1

    section = ('<w:sectPr><w:headerReference w:type="default" r:id="rIdHeader"/>'
               '<w:footerReference w:type="default" r:id="rIdFooter"/>'
               '<w:pgSz w:w="11906" w:h="16838"/>'
               '<w:pgMar w:top="1000" w:right="1023" w:bottom="1000" w:left="1023" '
               'w:header="440" w:footer="440" w:gutter="0"/></w:sectPr>')
    document = xml(f'<w:document xmlns:w="{W}" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
                   f'<w:body>{"".join(body)}{section}</w:body></w:document>')
    styles = xml(f'''<w:styles xmlns:w="{W}">
<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/><w:sz w:val="22"/><w:color w:val="243746"/><w:lang w:val="vi-VN"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="110" w:line="264" w:lineRule="auto"/><w:widowControl/></w:pPr></w:pPrDefault></w:docDefaults>
<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style>
<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:before="1800" w:after="300"/><w:keepNext/></w:pPr><w:rPr><w:b/><w:color w:val="123A52"/><w:sz w:val="56"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:basedOn w:val="Normal"/><w:pPr><w:keepNext/><w:spacing w:after="400"/></w:pPr><w:rPr><w:color w:val="936D30"/><w:sz w:val="32"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:pPr><w:keepNext/><w:keepLines/><w:spacing w:before="80" w:after="220"/><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:b/><w:color w:val="123A52"/><w:sz w:val="34"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:pPr><w:keepNext/><w:keepLines/><w:spacing w:before="240" w:after="130"/><w:outlineLvl w:val="1"/></w:pPr><w:rPr><w:b/><w:color w:val="123A52"/><w:sz w:val="27"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading3"><w:name w:val="heading 3"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:pPr><w:keepNext/><w:keepLines/><w:spacing w:before="230" w:after="100"/><w:outlineLvl w:val="2"/></w:pPr><w:rPr><w:b/><w:color w:val="123A52"/><w:sz w:val="24"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="ListParagraph"><w:name w:val="List Paragraph"/><w:basedOn w:val="Normal"/><w:pPr><w:ind w:left="240"/><w:spacing w:after="90"/></w:pPr></w:style>
<w:style w:type="paragraph" w:styleId="Code"><w:name w:val="Code"/><w:basedOn w:val="Normal"/><w:pPr><w:shd w:fill="F1F4F7"/><w:spacing w:before="100" w:after="140"/></w:pPr><w:rPr><w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:sz w:val="19"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Spacer"><w:name w:val="Spacer"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="60" w:line="60" w:lineRule="exact"/></w:pPr><w:rPr><w:sz w:val="4"/></w:rPr></w:style>
</w:styles>''')
    relns = 'http://schemas.openxmlformats.org/package/2006/relationships'
    officens = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
    rels = xml(f'<Relationships xmlns="{relns}">' + ''.join(
        f'<Relationship Id="{rid}" Type="{officens}/{kind}" Target="{target}"/>'
        for rid, kind, target in [('rIdStyles', 'styles', 'styles.xml'),
                                  ('rIdHeader', 'header', 'header1.xml'),
                                  ('rIdFooter', 'footer', 'footer1.xml')]) + '</Relationships>')
    rootrels = xml(f'<Relationships xmlns="{relns}"><Relationship Id="rIdDoc" Type="{officens}/officeDocument" Target="word/document.xml"/>'
                   '<Relationship Id="rIdCore" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/></Relationships>')
    ctns = 'http://schemas.openxmlformats.org/package/2006/content-types'
    types = xml(f'<Types xmlns="{ctns}"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
                '<Default Extension="xml" ContentType="application/xml"/>' + ''.join(
                    f'<Override PartName="/{part}" ContentType="{kind}"/>' for part, kind in [
                        ('word/document.xml', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml'),
                        ('word/styles.xml', 'application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml'),
                        ('word/header1.xml', 'application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml'),
                        ('word/footer1.xml', 'application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml'),
                        ('docProps/core.xml', 'application/vnd.openxmlformats-package.core-properties+xml')]) + '</Types>')
    header = xml(f'<w:hdr xmlns:w="{W}"><w:p><w:pPr><w:spacing w:after="0"/><w:pBdr><w:bottom w:val="single" w:sz="6" w:color="B58A45"/></w:pBdr></w:pPr>{run("TETRA HOTEL  •  DANH MỤC CHỨC NĂNG & NGHIỆP VỤ", size=17)}</w:p></w:hdr>')
    footer = xml(f'<w:ftr xmlns:w="{W}"><w:p><w:pPr><w:jc w:val="right"/></w:pPr>{run("Chốt ngày 18/10/2026  |  Trang ", size=17)}<w:fldSimple w:instr="PAGE">{run("1", size=17)}</w:fldSimple></w:p></w:ftr>')
    core = xml('<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
               'xmlns:dc="http://purl.org/dc/elements/1.1/">'
               '<dc:title>TETRA Hotel — Danh mục chức năng và luồng nghiệp vụ — 18/10/2026</dc:title>'
               '<dc:creator>TETRA Hotel</dc:creator><dc:description>Chức năng cũ/mới, hướng dẫn thao tác, phần chưa sẵn sàng và đề xuất.</dc:description></cp:coreProperties>')
    parts = {'[Content_Types].xml': types, '_rels/.rels': rootrels,
             'word/document.xml': document, 'word/styles.xml': styles,
             'word/_rels/document.xml.rels': rels, 'word/header1.xml': header,
             'word/footer1.xml': footer, 'docProps/core.xml': core}
    if not catalogue:
        header = header.replace('DANH MỤC CHỨC NĂNG &amp; NGHIỆP VỤ', 'KỊCH BẢN QUAY BÁO CÁO TIẾN ĐỘ')
        core = core.replace('Danh mục chức năng và luồng nghiệp vụ', 'Kịch bản quay báo cáo tiến độ')
        core = core.replace('Chức năng cũ/mới, hướng dẫn thao tác, phần chưa sẵn sàng và đề xuất.',
                            'Thao tác quay báo cáo tiến độ và kết quả chạy thử trên điện thoại.')
        parts['word/header1.xml'] = header
        parts['docProps/core.xml'] = core
    output.parent.mkdir(exist_ok=True)
    with ZipFile(output, 'w', ZIP_DEFLATED) as archive:
        for name, content in parts.items():
            ET.fromstring(content)  # Validate every generated XML part before packaging.
            archive.writestr(name, content.encode('utf8'))
    with ZipFile(output) as archive:
        assert archive.testzip() is None
        tree = ET.fromstring(archive.read('word/document.xml'))
        texts = [n.text or '' for n in tree.iter(f'{{{W}}}t')]
        all_text = '\n'.join(texts)
        for prefix, count in ([('CU', 37), ('MOI', 60), ('CHO', 15), ('KT', 8), ('DX', 19)] if catalogue else []):
            for number in range(1, count + 1):
                assert re.search(r'\b' + prefix + f'{number:02}' + r'\b', all_text), (prefix, number)
        flows = [t for t in texts if re.match(r'^L\d{2}\. ', t)]
        if catalogue: assert len(flows) == 35, len(flows)
        assert '\ufffd' not in all_text
        assert 'TETRA' in all_text
    print(f'Created: {output.relative_to(ROOT)}')
    print(f'Word package: {output.stat().st_size:,} bytes; {len(list(tree.iter(f"{{{W}}}tbl")))} tables. XML/ZIP validated.')


if __name__ == '__main__':
    build()
