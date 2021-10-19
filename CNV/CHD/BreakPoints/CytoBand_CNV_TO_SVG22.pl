#!/usr/bin/perl -w
use strict;
use SVG;

open(CB,$ARGV[0]); ##cytoband
open(RS,$ARGV[1]); ##cnv results
my $id=$ARGV[2]; ##sample id

my %chr_end=();
while(<CB>)
{
 my @tmp=split /\t/,$_;
 my $chr=$tmp[0];
 my $end=$tmp[2];
 $chr_end{$chr}=$end;
}
close(CB);

my $gender="";
my %cnv=();
while(<RS>)
{
 chomp($_);
 if($_=~/^ID/) {next;}
 else{
 my @tmp=split /\t/,$_;
 if($tmp[8]<(1000*1000) && ($_=~/Decipher_Syndrome/i || ($_=~/DECIPHER/i && $_=~/pathogenic/i) || ($_=~/ISCA/i && $_=~/pathogenic/i))) {
 my $cnvcolor="";
 my $RR=2*(2**($tmp[5]));
 if($RR>=2.2) {$cnvcolor="purple";}
 elsif($RR<=1.8) {$cnvcolor="green";}
 my $start=$tmp[2];
 my $end=$tmp[3];
 if($end>$chr_end{$tmp[1]}) {$end=$chr_end{$tmp[1]};}
 $cnv{$tmp[1]}{$start}{$end}=$cnvcolor;
 print $_."\t".$cnvcolor."\n";
 }
 elsif($tmp[8]>=(1000*1000)){
 my $cnvcolor="";
 my $RR=2*(2**($tmp[5]));
 if($RR>=2.2) {$cnvcolor="purple";}
 elsif($RR<=1.8) {$cnvcolor="green";}
 my $start=$tmp[2];
 my $end=$tmp[3];
 if($end>$chr_end{$tmp[1]}) {$end=$chr_end{$tmp[1]};}
 $cnv{$tmp[1]}{$start}{$end}=$cnvcolor;
 print $_."\t".$cnvcolor."\n";
 }
 }
}
close(RS);

my %info=();
my %color=();
my @chr=();
if(exists $cnv{"chrY"})
{@chr=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrX","chrY");}
elsif(exists $cnv{"chrX"})
{@chr=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrX");}
else{
{@chr=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22");}
}

my %gcolor=();
$gcolor{"gneg"}="white"; $gcolor{"gpos25"}="silver"; $gcolor{"gpos50"}="gray"; $gcolor{"gpos75"}="darkgray";
$gcolor{"gpos100"}="black"; $gcolor{"acen"}="red"; $gcolor{"stalk"}="pink"; $gcolor{"gvar"}="blue";

my $gvar="";
open(CB,$ARGV[0]); ##cytoband
while(<CB>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 my $start=$tmp[1]+1;
 my $end=$tmp[2];
 if($tmp[3]=~/^p/){
 if(exists $info{$tmp[0]}{"p1"}){
  if($info{$tmp[0]}{"p1"}>=$start) {$info{$tmp[0]}{"p1"}=$start;}
 }
 else{
 $info{$tmp[0]}{"p1"}=$start;
 }
 if(exists $info{$tmp[0]}{"p2"}){
  if($info{$tmp[0]}{"p2"}<=$end) {$info{$tmp[0]}{"p2"}=$end;}
 }
 else{
 $info{$tmp[0]}{"p2"}=$end;
 }
 }
 elsif($tmp[3]=~/^q/){
 if(exists $info{$tmp[0]}{"q1"}){
  if($info{$tmp[0]}{"q1"}>=$start) {$info{$tmp[0]}{"q1"}=$start;}
 }
 else{
 $info{$tmp[0]}{"q1"}=$start;
 }
 if(exists $info{$tmp[0]}{"q2"}){
  if($info{$tmp[0]}{"q2"}<=$end) {$info{$tmp[0]}{"q2"}=$end;}
 }
 else{
 $info{$tmp[0]}{"q2"}=$end;
 }
 }
 if($tmp[0] eq "chrY" && $tmp[$#tmp] eq "gvar"){
 $gvar=$_;
 print $gvar."\n";
 }
 $color{$tmp[0]}{$start}{$end}=$gcolor{$tmp[4]};
}
close(CB);

my $max=$info{"chr1"}{"q2"};

my %scolor = 
	(
		'fig_bg'  =>'rgb(255, 255, 255)', 
		'name'   =>'rgb(0, 0, 0  )', 
		'fill'   =>'rgb(20, 95, 235)',
	); # Í¼ÖÐ¸÷ÔªËØµÄÏà¹ØÑÕÉ«

#my ($top_margin, $bottom_margin, $left_margin, $right_margin) = (100, 100, 50, 50); # Í¼µÄÒ³±ß¿Õ°×
my ($top_margin, $bottom_margin, $left_margin, $right_margin) = (100, 50, 50, 20); # Í¼µÄÒ³±ß¿Õ°×
my $width=3000+$left_margin+$right_margin;
my $height=1500+$top_margin+$bottom_margin;
my $svg= SVG->new(width=>$width,height=>$height);

my ($font_family, $font_size_chr, $font_size_mark, $font_size_title) = ("ArialNarrow", 40, 18, 18); # ×ÖÌåºÍ×ÖºÅ

#$svg->rect('x'=>0, 'y'=>0, 'width'=>$width, 'height'=>$height, 'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'fig_bg'},'stroke-width'=>20);
$svg->rect('x'=>0, 'y'=>0, 'width'=>$width, 'height'=>$height, 'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'fig_bg'},'stroke-width'=>5);

for(my $i=0;$i<=$#chr;$i++)
{
 my $label=$chr[$i]; #$label=~s/^chr//;
 if($i<=11)
 {
 my $wd=100;
 my $hg=700*$info{$chr[$i]}{"q2"}/$max;
 my $nx=50+250*$i;
 my $ny=100+700-$hg;
 my $hg1=700*($info{$chr[$i]}{"p2"})/$max;
 my $hg2=700*($info{$chr[$i]}{"q2"}-$info{$chr[$i]}{"p2"})/$max;
 #$svg->rect('x'=>$nx,'y'=>$ny,'rx'=>35,'ry'=>35, 'width'=>$wd, 'height'=>$hg1, 'stroke-width'=>5,'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'name'},'fill-opacity'=>0, 'stroke-opacity'=>1);
 #$ny=100+700-$hg+$hg1;
 #$svg->rect('x'=>$nx,'y'=>$ny,'rx'=>35,'ry'=>35, 'width'=>$wd, 'height'=>$hg2, 'stroke-width'=>5,'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'name'},'fill-opacity'=>0, 'stroke-opacity'=>1);
 
 for my $k1 (sort {$a <=> $b} keys %{$color{$chr[$i]}})
 {
  for my $k2 (sort {$a <=> $b} keys %{$color{$chr[$i]}{$k1}})
  {
   my $hg3=700*$k1/$max;
   my $hg4=700*$k2/$max-$hg3;
   $ny=100+700-$hg+$hg3;
   $svg->rect('x'=>$nx,'y'=>$ny, 'width'=>$wd, 'height'=>$hg4, 'stroke-width'=>0,'fill'=>$color{$chr[$i]}{$k1}{$k2}, 'stroke'=>$color{$chr[$i]}{$k1}{$k2},'fill-opacity'=>1, 'stroke-opacity'=>0);
  }
 }
 
##Ô²½ÇÌîÉ«
 my $mnx=50+250*$i;
 my $mny=100+700-$hg+35;
 my $anx=$mnx+35;
 my $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*$i+100-35;
 $mny=100+700-$hg;
 $anx=$mnx+35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*$i+35;
 $mny=100+700-$hg+$hg1;
 $anx=$mnx-35;
 $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*$i+100;
 $mny=100+700-$hg+$hg1-35;
 $anx=$mnx-35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*$i;
 $mny=100+700-$hg+35+$hg1;
 $anx=$mnx+35;
 $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*$i+100-35;
 $mny=100+700-$hg+$hg1;
 $anx=$mnx+35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*$i+35;
 $mny=100+700-$hg+$hg;
 $anx=$mnx-35;
 $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*$i+100;
 $mny=100+700-$hg+$hg-35;
 $anx=$mnx-35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
##Ô²½ÇÌîÉ«
 
 $nx=50+250*$i;
 $ny=100+700-$hg;
 $svg->rect('x'=>$nx,'y'=>$ny,'rx'=>35,'ry'=>35, 'width'=>$wd, 'height'=>$hg1, 'stroke-width'=>2,'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'name'},'fill-opacity'=>0, 'stroke-opacity'=>1);
 $ny=100+700-$hg+$hg1;
 $svg->rect('x'=>$nx,'y'=>$ny,'rx'=>35,'ry'=>35, 'width'=>$wd, 'height'=>$hg2, 'stroke-width'=>2,'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'name'},'fill-opacity'=>0, 'stroke-opacity'=>1);
 $ny=100+700-$hg;
 #$svg->rect('x'=>$nx,'y'=>$ny,'width'=>$wd, 'height'=>$hg, 'stroke-width'=>1,'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'name'},'fill-opacity'=>0, 'stroke-opacity'=>1,'fill-rule'=>'nonzero');
 
 if(exists $cnv{$label})
 {
 foreach my $k1 (sort {$a <=> $b} keys %{$cnv{$label}})
 {
  foreach my $k2 (sort {$a <=> $b} keys %{$cnv{$label}{$k1}})
   {
      my $wd1=100;
      my $hg11=700*$k1/$max;
      my $hg21=700*($k2-$k1+1)/$max;
      my $nx1=50+250*$i+110;
      my $ny1=100+700-$hg+$hg11;
      $svg->rect('x'=>$nx1,'y'=>$ny1,'width'=>$wd1, 'height'=>$hg21, 'stroke-width'=>0,'fill'=>$cnv{$label}{$k1}{$k2}, 'stroke'=>$cnv{$label}{$k1}{$k2},'fill-opacity'=>1, 'stroke-opacity'=>1);
   }
 }
 }
 
##Ô²½ÇÌîÉ«
 $mnx=50+250*$i+110;
 $mny=100+700-$hg+35;
 $anx=$mnx+35;
 $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*$i+100-35+110;
 $mny=100+700-$hg;
 $anx=$mnx+35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*$i+35+110;
 $mny=100+700-$hg+$hg1;
 $anx=$mnx-35;
 $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*$i+100+110;
 $mny=100+700-$hg+$hg1-35;
 $anx=$mnx-35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*$i+110;
 $mny=100+700-$hg+35+$hg1;
 $anx=$mnx+35;
 $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*$i+100-35+110;
 $mny=100+700-$hg+$hg1;
 $anx=$mnx+35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*$i+35+110;
 $mny=100+700-$hg+$hg;
 $anx=$mnx-35;
 $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*$i+100+110;
 $mny=100+700-$hg+$hg-35;
 $anx=$mnx-35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
##Ô²½ÇÌîÉ«

 $nx=50+250*$i+110;
 $ny=100+700-$hg;
 $svg->rect('x'=>$nx,'y'=>$ny,'rx'=>35,'ry'=>35, 'width'=>$wd, 'height'=>$hg1, 'stroke-width'=>2,'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'name'},'fill-opacity'=>0, 'stroke-opacity'=>1);
 $ny=100+700-$hg+$hg1;
 $svg->rect('x'=>$nx,'y'=>$ny,'rx'=>35,'ry'=>35, 'width'=>$wd, 'height'=>$hg2, 'stroke-width'=>2,'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'name'},'fill-opacity'=>0, 'stroke-opacity'=>1);
 
 $nx=50+250*$i;
 $ny=815;
 $svg->line('x1'=>$nx, 'y1'=>$ny, 'x2'=>$nx+210, 'y2'=>$ny, 'fill'=>'black', 'stroke'=>'black', 'stroke-width'=>3);
 
 my $lc=length($label);
 if($lc==1) {$nx=50+250*$i+95;}
 else {$nx=50+250*$i+85;}
 $ny=850;
 my $tag=$svg -> text('x'=>$nx, 'y'=>$ny );
 $tag->tspan('dx'=>0,'dy'=>0,'font-family'=>$font_family, 'font-size'=>35, 'fill'=>'black', 'stroke'=>'black') -> cdata($label);
 }
 else{
 my $wd=100;
 my $hg=700*$info{$chr[$i]}{"q2"}/$max;
 my $nx=50+250*($i-12);
 my $ny=850+700-$hg;
 my $hg1=700*($info{$chr[$i]}{"p2"})/$max;
 my $hg2=700*($info{$chr[$i]}{"q2"}-$info{$chr[$i]}{"p2"})/$max;
 #$svg->rect('x'=>$nx,'y'=>$ny,'rx'=>35,'ry'=>35, 'width'=>$wd, 'height'=>$hg1, 'stroke-width'=>5,'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'name'},'fill-opacity'=>0, 'stroke-opacity'=>1);
 #$ny=850+700-$hg+$hg1;
 #$svg->rect('x'=>$nx,'y'=>$ny,'rx'=>35,'ry'=>35, 'width'=>$wd, 'height'=>$hg2, 'stroke-width'=>5,'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'name'},'fill-opacity'=>0, 'stroke-opacity'=>1);
 
 
 for my $k1 (sort {$a <=> $b} keys %{$color{$chr[$i]}})
 {
  for my $k2 (sort {$a <=> $b} keys %{$color{$chr[$i]}{$k1}})
  {
   my $hg3=700*$k1/$max;
   my $hg4=700*$k2/$max-$hg3;
   $ny=850+700-$hg+$hg3;
   $svg->rect('x'=>$nx,'y'=>$ny, 'width'=>$wd, 'height'=>$hg4, 'stroke-width'=>0,'fill'=>$color{$chr[$i]}{$k1}{$k2}, 'stroke'=>$color{$chr[$i]}{$k1}{$k2},'fill-opacity'=>1, 'stroke-opacity'=>0);
  }
 }

##Ô²½ÇÌîÉ«
 my $mnx=50+250*($i-12);
 my $mny=850+700-$hg+35;
 my $anx=$mnx+35;
 my $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*($i-12)+100-35;
 $mny=850+700-$hg;
 $anx=$mnx+35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*($i-12)+35;
 $mny=850+700-$hg+$hg1;
 $anx=$mnx-35;
 $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*($i-12)+100;
 $mny=850+700-$hg+$hg1-35;
 $anx=$mnx-35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*($i-12);
 $mny=850+700-$hg+35+$hg1;
 $anx=$mnx+35;
 $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*($i-12)+100-35;
 $mny=850+700-$hg+$hg1;
 $anx=$mnx+35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*($i-12)+35;
 $mny=850+700-$hg+$hg;
 $anx=$mnx-35;
 $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*($i-12)+100;
 $mny=850+700-$hg+$hg-35;
 $anx=$mnx-35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
##Ô²½ÇÌîÉ«
 
 $nx=50+250*($i-12);
 $ny=850+700-$hg;
 $svg->rect('x'=>$nx,'y'=>$ny,'rx'=>35,'ry'=>35, 'width'=>$wd, 'height'=>$hg1, 'stroke-width'=>2,'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'name'},'fill-opacity'=>0, 'stroke-opacity'=>1);
 $ny=850+700-$hg+$hg1;
 $svg->rect('x'=>$nx,'y'=>$ny,'rx'=>35,'ry'=>35, 'width'=>$wd, 'height'=>$hg2, 'stroke-width'=>2,'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'name'},'fill-opacity'=>0, 'stroke-opacity'=>1);
 
 if(exists $cnv{$label})
 {
 foreach my $k1 (sort {$a <=> $b} keys %{$cnv{$label}})
 {
  foreach my $k2 (sort {$a <=> $b} keys %{$cnv{$label}{$k1}})
   {
      my $wd1=100;
      my $hg11=700*$k1/$max;
      my $hg21=700*($k2-$k1+1)/$max;
      my $nx1=50+250*($i-12)+110;
      my $ny1=850+700-$hg+$hg11;
      $svg->rect('x'=>$nx1,'y'=>$ny1,'width'=>$wd1, 'height'=>$hg21, 'stroke-width'=>0,'fill'=>$cnv{$label}{$k1}{$k2}, 'stroke'=>$cnv{$label}{$k1}{$k2},'fill-opacity'=>1, 'stroke-opacity'=>1);
   }
 }
=pod
 if($label eq "chrY")
 {
 my @Gvar=split /\t/,$gvar;
      my $wd1=100;
      my $hg11=700*$Gvar[1]/$max;
      my $hg21=700*($Gvar[2]-$Gvar[1])/$max;
      my $nx1=50+250*($i-12)+110;
      my $ny1=850+700-$hg+$hg11;
      $svg->rect('x'=>$nx1,'y'=>$ny1,'width'=>$wd1, 'height'=>$hg21, 'stroke-width'=>0,'fill'=>"white", 'stroke'=>"white",'fill-opacity'=>1, 'stroke-opacity'=>0);
 }
=cut
 }

##Ô²½ÇÌîÉ«
 $mnx=50+250*($i-12)+110;
 $mny=850+700-$hg+35;
 $anx=$mnx+35;
 $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*($i-12)+100-35+110;
 $mny=850+700-$hg;
 $anx=$mnx+35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*($i-12)+35+110;
 $mny=850+700-$hg+$hg1;
 $anx=$mnx-35;
 $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*($i-12)+100+110;
 $mny=850+700-$hg+$hg1-35;
 $anx=$mnx-35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*($i-12)+110;
 $mny=850+700-$hg+35+$hg1;
 $anx=$mnx+35;
 $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*($i-12)+100-35+110;
 $mny=850+700-$hg+$hg1;
 $anx=$mnx+35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*($i-12)+35+110;
 $mny=850+700-$hg+$hg;
 $anx=$mnx-35;
 $any=$mny-35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $anx $mny Z", 'fill'=>'white', 'stroke'=>'white');
 
 $mnx=50+250*($i-12)+100+110;
 $mny=850+700-$hg+$hg-35;
 $anx=$mnx-35;
 $any=$mny+35;
 $svg->path(d=>"M $mnx $mny A 35 35 0 0 1 $anx $any L $mnx $any Z", 'fill'=>'white', 'stroke'=>'white');
##Ô²½ÇÌîÉ«
 
 $nx=50+250*($i-12)+110;
 $ny=850+700-$hg;
 $svg->rect('x'=>$nx,'y'=>$ny,'rx'=>35,'ry'=>35, 'width'=>$wd, 'height'=>$hg1, 'stroke-width'=>2,'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'name'},'fill-opacity'=>0, 'stroke-opacity'=>1);
 $ny=850+700-$hg+$hg1;
 $svg->rect('x'=>$nx,'y'=>$ny,'rx'=>35,'ry'=>35, 'width'=>$wd, 'height'=>$hg2, 'stroke-width'=>2,'fill'=>$scolor{'fig_bg'}, 'stroke'=>$scolor{'name'},'fill-opacity'=>0, 'stroke-opacity'=>1);
 
 $nx=50+250*($i-12);
 $ny=1565;
 $svg->line('x1'=>$nx, 'y1'=>$ny, 'x2'=>$nx+210, 'y2'=>$ny, 'fill'=>'black', 'stroke'=>'black', 'stroke-width'=>3);
 
 my $lc=length($label);
 if($lc==1) {$nx=50+250*($i-12)+95;}
 else {$nx=50+250*($i-12)+85;}
 $ny=1600;
 my $tag=$svg -> text('x'=>$nx, 'y'=>$ny );
 $tag->tspan('dx'=>0,'dy'=>0,'font-family'=>$font_family, 'font-size'=>35, 'fill'=>'black', 'stroke'=>'black') -> cdata($label);
 }
}

my $nx=2800;
my $ny=195;
my $demo="Deletion";
my $tag=$svg -> text('x'=>$nx, 'y'=>$ny );
$tag->tspan('dx'=>0,'dy'=>0,'font-family'=>$font_family, 'font-size'=>35, 'fill'=>"black", 'stroke'=>"black") -> cdata($demo);

$nx=2755;
$ny=165;
my $wd=35;
my $hg=35;
$svg->rect('x'=>$nx, 'y'=>$ny, 'width'=>$wd, 'height'=>$hg, 'stroke-width'=>2, 'fill'=>"green", 'stroke'=>"black");

$nx=2800;
$ny=245;
$demo="Duplication";
$tag=$svg -> text('x'=>$nx, 'y'=>$ny );
$tag->tspan('dx'=>0,'dy'=>0,'font-family'=>$font_family, 'font-size'=>35, 'fill'=>"black", 'stroke'=>"black") -> cdata($demo);

$nx=2755;
$ny=215;
$wd=35;
$hg=35;
$svg->rect('x'=>$nx, 'y'=>$ny, 'width'=>$wd, 'height'=>$hg, 'stroke-width'=>2, 'fill'=>"purple", 'stroke'=>"black");

 $nx=1400;
 $ny=100;
 my $stag=$svg -> text('x'=>$nx, 'y'=>$ny );
 #$stag->tspan('dx'=>0,'dy'=>0,'font-family'=>$font_family, 'font-size'=>80, 'fill'=>"black", 'stroke'=>"black") -> cdata($id);
 $stag->tspan('dx'=>0,'dy'=>0,'font-family'=>$font_family, 'font-size'=>50, 'fill'=>"black", 'stroke'=>"black") -> cdata($id);

open(OUT, '>',$ARGV[3]) || die "Can't output graph\n";
print OUT $svg->xmlify();
close(OUT);

my $png=$ARGV[3]; $png=~s/svg$/png/;
system("rsvg-convert -o $png $ARGV[3]");
