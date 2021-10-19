#!/usr/bin/python
from collections import defaultdict
import math
import sys
import os
import re

def svg_header():
    header = """
<!-- <?xml version="1.0" encoding="UTF-8" standalone="yes"?> -->
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
<svg height="700" width="1500" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<defs>
<linearGradient id="del" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" stop-color="rgb(230,178,175)"/>
<stop offset="50%" stop-color="rgb(230,178,175)"/>
<stop offset="100%" stop-color="rgb(230,178,175)"/>
</linearGradient>
</defs>
<defs>
<linearGradient id="dup" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" stop-color="rgb(166,216,217)"/>
<stop offset="50%" stop-color="rgb(166,216,217)"/>
<stop offset="100%" stop-color="rgb(166,216,217)"/>
</linearGradient>
</defs>
<defs>
<linearGradient id="white" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" stop-color="white"/>
<stop offset="50%" stop-color="white"/>
<stop offset="100%" stop-color="white"/>
</linearGradient>
</defs>
<defs>
<linearGradient id="black" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" stop-color="rgb(105,100,205)"/>
<stop offset="50%" stop-color="rgb(105,100,205)"/>
<stop offset="100%" stop-color="rgb(105,100,205)"/>
</linearGradient>
</defs>
<defs>
<linearGradient id="gray" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" stop-color="rgb(105,100,205)"/>
<stop offset="50%" stop-color="rgb(105,100,205)"/>
<stop offset="100%" stop-color="rgb(105,100,205)"/>
</linearGradient>
</defs>
<defs>
<linearGradient id="silver" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" stop-color="rgb(105,100,205)"/>
<stop offset="50%" stop-color="rgb(105,100,205)"/>
<stop offset="100%" stop-color="rgb(105,100,205)"/>
</linearGradient>
</defs>
<defs>
<linearGradient id="red" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" stop-color="rgb(105,100,205)"/>
<stop offset="50%" stop-color="rgb(105,100,205)"/>
<stop offset="100%" stop-color="rgb(105,100,205)"/>
</linearGradient>
</defs>
<defs>
<linearGradient id="blue" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" stop-color="rgb(105,100,205)"/>
<stop offset="50%" stop-color="rgb(105,100,205)"/>
<stop offset="100%" stop-color="rgb(105,100,205)"/>
</linearGradient>
</defs>
<defs>
<linearGradient id="darkgray" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" stop-color="rgb(105,100,205)"/>
<stop offset="50%" stop-color="rgb(105,100,205)"/>
<stop offset="100%" stop-color="rgb(105,100,205)"/>
</linearGradient>
</defs>
<defs>
<linearGradient id="pink" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" stop-color="rgb(240,240,240)"/>
<stop offset="50%" stop-color="rgb(240,240,240)"/>
<stop offset="100%" stop-color="rgb(240,240,240)"/>
</linearGradient>
</defs>
    """
    return(header)

def def_colors():
    colors = {"gneg":"white", 
            "gpos25":"silver", 
            "gpos50":"gray", 
            "gpos75":"darkgray", 
            "gpos100":"black", 
            "acen":"red", 
            "stalk":"pink", 
            "gvar":"blue",
            'del':'del',
            'dup':'dup'
            }
    return(colors)

def read_cytoband(cyto):
    cyto_dict = dict()
    with open(cyto, 'rt') as fh:
        for line in fh:
            lines = line.strip().split('\t')
            if len(lines) != 5:
                continue
            cyto_dict.setdefault(lines[0], dict()).setdefault(int(lines[1]),  {'end':int(lines[2]), 'color':lines[4], 'band':lines[3]})
    return(cyto_dict)

def generate_chr_svg(cyto_dict, title, number=24, cnv=None):
    colors = def_colors()
    chroms = ("chr1", "chr2","chr3", "chr4","chr5", "chr6","chr7", "chr8","chr9", "chr10","chr11", "chr12","chr13", "chr14","chr15", "chr16","chr17", "chr18","chr19", "chr20","chr21", "chr22","chrX", "chrY")
    chroms = chroms[0:number]
    startx = 60
    width = 16
    starty = 600
    fold = 2
    newsvg = ""
    xinr = 60
    x = startx
    cnvinr = 25
    newsvg = '<rect fill="white" height="700" stroke="rgb(255, 255, 255)" stroke-width="5" width="1500" x="0" y="0" />\n'
    for chri in chroms:
        maxi = cyto_dict[chri][max(cyto_dict[chri].keys())]['end']
        y = starty
        acen = [[], []]
        stalk = []
        for newy in sorted(cyto_dict[chri].keys(), reverse=True):
            height =(cyto_dict[chri][newy]['end'] - newy)/1000000.0 * fold
            if cyto_dict[chri][newy]['color'] == 'acen':
                if cyto_dict[chri][newy]['band'].startswith('p'):
                    acen[0] = [y-height, y]
                    newsvg += '<rect fill="url(#{})" fill-opacity="1" height="{}" stroke="url(#{})" stroke-opacity="0" stroke-width="0" width="{}" x="{}" y="{}" />\n'.format(colors[cyto_dict[chri][newy]['color']], height, colors[cyto_dict[chri][newy]['color']], width * 1/2, x + width*1/4, y - height)
                else:
                    acen[1] = [y-height, y]
                    newsvg += '<rect fill="url(#{})" fill-opacity="1" height="{}" stroke="url(#{})" stroke-opacity="0" stroke-width="0" width="{}" x="{}" y="{}" />\n'.format(colors[cyto_dict[chri][newy]['color']], height, colors[cyto_dict[chri][newy]['color']], width * 1/2, x + width*1/4, y - height)
            else:
                if cyto_dict[chri][newy]['color'] == 'stalk':
                    stalk = [y - height, y]
                else:
                    newsvg += '<rect fill="url(#{})" fill-opacity="1" height="{}" stroke="url(#{})" stroke-opacity="0" stroke-width="0" width="{}" x="{}" y="{}" />\n'.format(colors[cyto_dict[chri][newy]['color']],
                        height, colors[cyto_dict[chri][newy]['color']], width, x, y - height
                        )
                if cyto_dict[chri][newy]['color'] == 'gvar':
                    gvar_line = int((height+4)/2)
                    jiojio = math.pi/2.5
                    gvar_line_height = (height+4)/gvar_line
                    for ik in range(gvar_line):
                        newsvg += '<line x1="{}" y1="{}" x2="{}" y2="{}" stroke="white" stroke-width="1" />'.format(
                            x, y - height -4  + ik*gvar_line_height, x+width, y-height -4+width/math.tan(jiojio) + ik*gvar_line_height
                         )
                    
            y = y - height
        if cnv and chri in cnv:
            for cnvy in sorted(cnv[chri].keys(), reverse=True):
                cnvendy = cnv[chri][cnvy]['end']/1000000.0 * fold
                cnvstarty = cnvy / 1000000.0 * fold                
                fully = maxi / 1000000.0 * fold
                cnvstarty = starty - fully + cnvstarty
                cnvendy = starty - fully + cnvendy
                newsvg += '<rect fill="url(#{})" fill-opacity="1" height="{}" stroke="url(#{})" stroke-opacity="0" stroke-width="0" width="{}" x="{}" y="{}" />\n'.format(colors[cnv[chri][cnvy]['color']], cnvendy - cnvstarty, colors[cnv[chri][cnvy]['color']], width, x +  cnvinr, cnvstarty)
        #draw stalk
        if len(stalk) == 2:
            newsvg += '<rect fill="url(#{})" fill-opacity="1" height="{}" stroke-opacity="0" stroke-width="1" width="{}" x="{}" y="{}" />\n'.format(colors['stalk'], stalk[1]-stalk[0], width, x, stalk[0])
        #draw karyotype outline
        arc = 12
        arc_height = 6
        acen_height = acen[1][1] - acen[0][0]
        acen_line =  int(acen_height/2)
        acen_line_height = acen_height/acen_line
        acen_line_svg = ''
        for ik in range(acen_line):
            acen_line_svg += '<line x1="{}" y1="{}" x2="{}" y2="{}" stroke="white" stroke-width="1" />'.format(
                x+width*1/4, acen[0][0]+ik*acen_line_height, x+width*3/4, acen[0][0]+ik*acen_line_height
            )
        acen_line_svg += '<line x1="{}" y1="{}" x2="{}" y2="{}" stroke="white" stroke-width="1" />'.format(
             x+width*1/4, acen[1][1], x+width*3/4, acen[1][1]
         )

        newsvg += acen_line_svg
        #<path class="cls-2" d="M19.89,211.72v-5.64a12.58,12.58,0,0,0,4.47-4.8,12.29,12.29,0,0,0,1.44-5.79V14.9A12.51,12.51,0,0,0,13.32,2.43h0A12.5,12.5,0,0,0,.85,14.9V195.49a12.35,12.35,0,0,0,1.42,5.77,12.67,12.67,0,0,0,4.6,4.9v5.56"/>
        acensvg1 = '<path d="M{},{}l{},{}A{},{},{},{},{},{},{}V{}a{},{},{},{},{},{},{}h{}A{},{},{},{},{},{},{}V{}a{},{},{},{},{},{},{}v{}" fill="white"  fill-opacity="0" stroke="rgb(105,100,205)" stroke-width="1"/>'.format(
            x + width*3/4, acen[1][0],
            0, -(acen[1][0] - acen[0][0]),
            arc, arc,0, 0, 0, (x + width), acen[0][0] - arc_height,
            y + arc_height,
            arc, arc, 0, 0, 0, -width*1/2, -arc_height,
            0,
            arc, arc, 0, 0, 0, x, y + arc_height,
            acen[0][0] - arc_height,
            arc, arc, 0, 0, 0, width*1/4, arc_height,
            acen[1][1] - acen[0][0]
        )
        acensvg2 = '<path d="M{},{}l{},{}A{},{},{},{},{},{},{}V{}a{},{},{},{},{},{},{}h{}A{},{},{},{},{},{},{}V{}a{},{},{},{},{},{},{}v{}" fill="white"  fill-opacity="0" stroke="rgb(105,100,205)" stroke-width="1"/>'.format(
            x + width*1/4, acen[0][0],
            0, acen[1][1] - acen[0][0],
            arc, arc,0, 0, 0, x, acen[1][1] + arc_height,
            starty - arc_height,
            arc, arc, 0, 0, 0, width*1/2, arc_height,
            0,
            arc, arc, 0, 0, 0, x+width, starty - arc_height,
            acen[1][1] + arc_height,
            arc, arc, 0, 0, 0, -width*1/4, -arc_height,
            acen[0][0] - acen[1][1]
        )
        #ignore middle left 
        acensvg_mid_left = '<path d="M{},{}a{},{},{},{},{},{},{}L{},{}A{},{},{},{},{},{},{}L{},{}" fill="white" stroke-width="0" />\n'.format(
            x, acen[0][0]-arc_height,
            arc, arc, 0, 0, 0, width*1/4,  arc_height,
            x + width*1/4, acen[1][1],
            arc, arc, 0, 0, 0, x, acen[1][1] + arc_height,
            x, acen[0][0]
        )
        #ignore middle right
        acensvg_mid_right = '<path d="M{},{}a{},{},{},{},{},{},{}L{},{}A{},{},{},{},{},{},{}L{},{}" fill="white" stroke-width="0" />\n'.format(
            x + width, acen[0][0]-arc_height,
            arc, arc, 0, 0, 1, -width*1/4,  arc_height,
            x + width*3/4, acen[1][1],
            arc, arc, 0, 0, 1, x + width , acen[1][1] + arc_height,
            x +width, acen[0][0]
        )
        #ignore top left
        acensvg_ignore1 = '<path d="M{},{}a{},{},{},{},{},{},{}v-5L{},{}" fill="white" stroke-width="0" />\n'.format(
            x, y+arc_height,
            arc, arc, 0, 0, 1, width*1/2,  -arc_height,
            x, y-5
        )
        #ignore top right
        acensvg_ignore2 = '<path d="M{},{}a{},{},{},{},{},{},{}v-5L{},{}" fill="white" stroke-width="0" />\n'.format(
            x+width*1/2, y,
            arc, arc, 0, 0, 1, width*1/2,  arc_height,
            x+width, y-5
        )
        #ignore bottom left
        acensvg_ignore3 = '<path d="M{},{}a{},{},{},{},{},{},{}L{},{}" fill="white" stroke-width="0" />\n'.format(
            x, starty-arc_height,
            arc, arc, 0, 0, 0, width*1/2,  arc_height,
            x, starty
        )
        #ignore bottom right
        acensvg_ignore4 = '<path d="M{},{}a{},{},{},{},{},{},{}L{},{}" fill="white" stroke-width="0" />\n'.format(
            x+width*1/2, starty,
            arc, arc, 0, 0, 0, width*1/2,  -arc_height,
            x+width, starty
        )
        

        newsvg += acensvg_mid_left
        newsvg += acensvg_mid_right
        newsvg += acensvg_ignore1
        newsvg += acensvg_ignore2
        newsvg += acensvg_ignore3
        newsvg += acensvg_ignore4
        newsvg += acensvg1
        newsvg += acensvg2
        #draw cnv karyotype outline
        xx = x + cnvinr
        #ignore middle left 
        acensvg_mid_left = '<path d="M{},{}a{},{},{},{},{},{},{}L{},{}A{},{},{},{},{},{},{}L{},{}" fill="white" stroke-width="0" />\n'.format(
            xx, acen[0][0]-arc_height,
            arc, arc, 0, 0, 0, width*1/4,  arc_height,
            xx + width*1/4, acen[1][1],
            arc, arc, 0, 0, 0, xx, acen[1][1] + arc_height,
            xx, acen[0][0]
        )
        #ignore middle right
        acensvg_mid_right = '<path d="M{},{}a{},{},{},{},{},{},{}L{},{}A{},{},{},{},{},{},{}L{},{}" fill="white" stroke-width="0" />\n'.format(
            xx + width, acen[0][0]-arc_height,
            arc, arc, 0, 0, 1, -width*1/4,  arc_height,
            xx + width*3/4, acen[1][1],
            arc, arc, 0, 0, 1, xx + width , acen[1][1] + arc_height,
            xx +width, acen[0][0]
        )
        #ignore top left
        acensvg_ignore1 = '<path d="M{},{}a{},{},{},{},{},{},{}L{},{}" fill="white" stroke-width="0" />\n'.format(
            xx, y+arc_height,
            arc, arc, 0, 0, 1, width*1/2,  -arc_height,
            xx, y-5
        )
        #ignore top right
        acensvg_ignore2 = '<path d="M{},{}a{},{},{},{},{},{},{}L{},{}" fill="white" stroke-width="0" />\n'.format(
            xx+width*1/2, y,
            arc, arc, 0, 0, 1, width*1/2,  arc_height,
            xx+width, y-5
        )
        #ignore bottom left
        acensvg_ignore3 = '<path d="M{},{}a{},{},{},{},{},{},{}L{},{}" fill="white" stroke-width="0" />\n'.format(
            xx, starty-arc_height,
            arc, arc, 0, 0, 0, width*1/2,  arc_height,
            xx, starty
        )
        #ignore bottom right
        acensvg_ignore4 = '<path d="M{},{}a{},{},{},{},{},{},{}L{},{}" fill="white" stroke-width="0" />\n'.format(
            xx+width*1/2, starty,
            arc, arc, 0, 0, 0, width*1/2,  -arc_height,
            xx+width, starty
        )
        acensvg1 = '<path d="M{},{}l{},{}A{},{},{},{},{},{},{}V{}a{},{},{},{},{},{},{}h{}A{},{},{},{},{},{},{}V{}a{},{},{},{},{},{},{}v{}" fill="white"  fill-opacity="0" stroke="rgb(105,100,205)" stroke-width="1"/>'.format(
            xx + width*3/4, acen[1][0],
            0, -(acen[1][0] - acen[0][0]),
            arc, arc,0, 0, 0, (xx + width), acen[0][0] - arc_height,
            y + arc_height,
            arc, arc, 0, 0, 0, -width*1/2, -arc_height,
            0,
            arc, arc, 0, 0, 0, xx, y + arc_height,
            acen[0][0] - arc_height,
            arc, arc, 0, 0, 0, width*1/4, arc_height,
            acen[1][1] - acen[0][0]
        )
        acensvg2 = '<path d="M{},{}l{},{}A{},{},{},{},{},{},{}V{}a{},{},{},{},{},{},{}h{}A{},{},{},{},{},{},{}V{}a{},{},{},{},{},{},{}v{}" fill="white"  fill-opacity="0" stroke="rgb(105,100,205)" stroke-width="1"/>'.format(
            xx + width*1/4, acen[0][0],
            0, acen[1][1] - acen[0][0],
            arc, arc,0, 0, 0, xx, acen[1][1] + arc_height,
            starty - arc_height,
            arc, arc, 0, 0, 0, width*1/2, arc_height,
            0,
            arc, arc, 0, 0, 0, xx+width, starty - arc_height,
            acen[1][1] + arc_height,
            arc, arc, 0, 0, 0, -width*1/4, -arc_height,
            acen[0][0] - acen[1][1]
        )
        
        newsvg += acensvg_mid_left
        newsvg += acensvg_mid_right
        newsvg += acensvg_ignore1
        newsvg += acensvg_ignore2
        newsvg += acensvg_ignore3
        newsvg += acensvg_ignore4
        newsvg += acensvg1
        newsvg += acensvg2


        newsvg += '<line fill="gray" stroke="gray" stroke-width="1" x1="{}" x2="{}" y1="{}" y2="{}" />'.format(x, x + width + cnvinr, starty+10, starty+10)
        newsvg += '<text x="{}" y="{}"  text-anchor="middle"> <tspan dx="0" dy="0" fill="black" font-family="lucida grande" font-size="20">{}</tspan></text> '.format(x + (cnvinr+width)/2.0, starty+30, re.sub("chr", "", chri))
        x = x + xinr
    newsvg += '<rect fill="url(#{})" fill-opacity="1" height="{}" stroke="url(#{})" stroke-opacity="0" stroke-width="0" width="{}" x="{}" y="{}" />\n'.format(colors['del'], width, colors['del'], width, x - 3*xinr, 100 )
    newsvg += '<text x="{}" y="{}"  text-anchor="right"> <tspan dx="0" dy="0" fill="black" font-family="lucida grande" font-size="20">{}</tspan></text> '.format( x - 3 * xinr + 2* width, 100 +width, "Deletion")

    newsvg += '<text x="{}" y="{}" text-anchor="center"> <tspan dx="0" dy="0" fill="black" font-family="lucida grande" font-size="25">{}</tspan></text> '.format( 600, 100, title)

    newsvg += '<rect fill="url(#{})" fill-opacity="1" height="{}" stroke="url(#{})" stroke-opacity="0" stroke-width="0" width="{}" x="{}" y="{}" />\n'.format(colors['dup'], width, colors['dup'], width, x - 3*xinr, 100 + 2* width)
    newsvg += '<text x="{}" y="{}"  text-anchor="right"> <tspan dx="0" dy="0" fill="black" font-family="lucida grande" font-size="20">{}</tspan></text> '.format( x - 3 * xinr + 2* width, 100 + 2* width + width, "Duplication")
    newsvg += "</svg>"
    return(newsvg)

def read_cnv(cnvfile):
    #ID      chrom   loc.start       loc.end num.mark        seg.mean        r.BinNums       e.BinNums       r.len   cytoband.region mosaic.per      loc.per all.per cnv.info        mosaic.avg      Ann.Info
    #X2P191106002.01 chrX    3060001 154480000       273     -0.9980 6975    7131    137000000       p22.33-q28      100     0.978   0.978   -X      100     Aneuploid
    header = dict()
    header_flag = 1
    cnv = dict()
    with open(cnvfile, 'rt') as fh:
        for line in fh:
            lines = line.strip().split("\t")
            if header_flag and lines[0] == 'ID':
                header_flag = 0
                for ix in range(len(lines)):
                    header[lines[ix]] = ix
                continue
            color = 'del'
            if float(lines[header['seg.mean']]) > 0:
                color = 'dup'
            cnv.setdefault(lines[header['chrom']], dict()).setdefault(int(lines[header['loc.start']]),  {'end':int(lines[header['loc.end']]), 'color':color})
    return(cnv)


if __name__ == "__main__":
    print(svg_header())
    cnv =  read_cnv(sys.argv[2])
    title =  sys.argv[3]
    number =  int(sys.argv[4])
    print(generate_chr_svg(read_cytoband(sys.argv[1]), title, number, cnv))
