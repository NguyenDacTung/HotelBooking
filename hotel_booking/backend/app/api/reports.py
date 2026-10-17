import csv
from datetime import date, datetime
from io import StringIO, BytesIO
from typing import Literal
from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session
from app.core.permissions import permission
from app.db.session import get_db
from app.core.config import settings
from app.core.errors import fail
from app.services.reports import revenue, VN

router = APIRouter(prefix='/admin/reports',tags=['Báo cáo TTTP'],dependencies=[Depends(permission('reports.read'))])


@router.get('/revenue')
def report(tu_ngay: date,den_ngay: date,mode: Literal['day','month']='day',db: Session = Depends(get_db)):
    return revenue(db,tu_ngay,den_ngay,mode)


def safe_csv(value):
    value = str(value)
    return "'"+value if value.lstrip().startswith(('=','+','-','@')) else value


@router.get('/revenue/export')
def export(tu_ngay: date,den_ngay: date,format: Literal['csv','pdf']='csv',
           mode: Literal['day','month']='day',db: Session = Depends(get_db)):
    data = revenue(db,tu_ngay,den_ngay,mode)
    headers = ['Kỳ','Thu (VND)','Hoàn (VND)','Thu ròng (VND)','Số đặt phòng']
    rows = [[r['ngay'],r['thu'],r['hoan'],r['thu_rong'],r['so_dat_phong']] for r in data['series']]
    filename = f'TTTP-thuc-thu-{tu_ngay}-{den_ngay}.{format}'
    if format=='csv':
        stream = StringIO(); writer=csv.writer(stream)
        writer.writerow(['TTTP - Báo cáo thực thu',str(tu_ngay),str(den_ngay),'Asia/Ho_Chi_Minh'])
        writer.writerow([data['dinh_nghia']]); writer.writerow(headers)
        for row in rows: writer.writerow([safe_csv(v) if isinstance(v,str) else v for v in row])
        writer.writerow(['Tổng',data['kpi']['thu'],data['kpi']['hoan'],data['kpi']['thu_rong'],data['kpi']['so_dat_phong']])
        raw = stream.getvalue().encode('utf-8-sig'); mime='text/csv; charset=utf-8'
    else:
        from reportlab.pdfgen import canvas
        from reportlab.pdfbase import pdfmetrics
        from reportlab.pdfbase.ttfonts import TTFont
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
        from reportlab.graphics.shapes import Drawing
        from reportlab.graphics.charts.lineplots import LinePlot
        font = settings().report_font_path
        if not font.is_file(): fail(503,'PDF_FONT_MISSING','Chưa cấu hình font tiếng Việt cho PDF')
        pdfmetrics.registerFont(TTFont('TTTP',str(font)))
        style = ParagraphStyle('TTTP',fontName='TTTP',fontSize=10,leading=15)
        stream=BytesIO(); doc=SimpleDocTemplate(stream)
        story=[Paragraph('TTTP — Báo cáo thực thu',ParagraphStyle('title',parent=style,fontSize=18,leading=24)),
            Paragraph(f'Kỳ {tu_ngay} — {den_ngay} | Asia/Ho_Chi_Minh',style),
            Paragraph('Xuất lúc '+datetime.now(VN).strftime('%d/%m/%Y %H:%M'),style),
            Paragraph(data['dinh_nghia'],style),Spacer(1,12)]
        for key,label in [('thu','Thực thu gộp'),('hoan','Hoàn tiền'),('thu_rong','Thu ròng'),('gia_tri_dat','Giá trị đặt xác nhận'),('con_phai_thu','Còn phải thu'),('can_hoan_tien','Cần hoàn')]:
            story.append(Paragraph(f"{label}: {data['kpi'][key]:,} VND",style))
        drawing=Drawing(450,170); chart=LinePlot(); chart.x=45;chart.y=25;chart.width=370;chart.height=120
        chart.data=[[(i,float(r[k])) for i,r in enumerate(data['series'])] for k in ('thu','hoan','thu_rong')]
        from reportlab.lib.colors import HexColor
        for i,color in enumerate(['#237A57','#B42318','#123A52']): chart.lines[i].strokeColor=HexColor(color)
        drawing.add(chart);story.extend([drawing,Paragraph('Trục X: thứ tự kỳ; trục Y: VND. Xanh lá: Thu; đỏ: Hoàn; xanh đậm: Thu ròng.',style)])
        table=Table([headers]+rows+[['Tổng',data['kpi']['thu'],data['kpi']['hoan'],data['kpi']['thu_rong'],data['kpi']['so_dat_phong']]],repeatRows=1)
        table.setStyle(TableStyle([('FONTNAME',(0,0),(-1,-1),'TTTP'),('FONTSIZE',(0,0),(-1,-1),8),('BOTTOMPADDING',(0,0),(-1,-1),7),('LINEBELOW',(0,0),(-1,0),1,HexColor('#123A52'))]))
        story.append(table);doc.build(story);raw=stream.getvalue();mime='application/pdf'
    return Response(raw,media_type=mime,headers={'Content-Disposition':f'attachment; filename="{filename}"'})
