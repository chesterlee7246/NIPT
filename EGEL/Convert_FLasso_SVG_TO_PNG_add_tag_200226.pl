#!/usr/bin/perl -w
use strict;
use SVG;

open(SF,$ARGV[0]); ##DNAcopy file
my @tmp=split /\//,$ARGV[0];
my $id=substr($tmp[$#tmp],0,13);

my %ZUF=(); ##U-test
my %ZSF=(); ##DNAcopy-test
my %nums=();
while(<SF>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 $nums{$tmp[0]}+=1;
 $ZUF{$tmp[0]}{$nums{$tmp[0]}}=$tmp[4];
 $ZSF{$tmp[0]}{$nums{$tmp[0]}}=$tmp[7];
 #$nums{$tmp[0]}=$tmp[1];
}
close(SF);

my @chr=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22");

my @all=();
for(my $i=0;$i<=$#chr;$i++)
{

my %color = 
	(
		'fig_bg'  =>'rgb(255, 255, 255)', 
		'name'   =>'rgb(0, 0, 0  )', 
		'fill'   =>'rgb(20, 95, 235)',
	); # 图中各元素的相关颜色

my ($top_margin, $bottom_margin, $left_margin, $right_margin) = (50, 50, 50, 50); # 图的页边空白
my $width=1000+$left_margin+$right_margin;
my $height=500+$top_margin+$bottom_margin;
my $svg= SVG->new(width=>$width,height=>$height);

my ($font_family, $font_size_chr, $font_size_mark, $font_size_title) = ("ArialNarrow", 40, 18, 18); # 字体和字号

$svg->rect('x'=>0, 'y'=>0, 'width'=>$width, 'height'=>$height, 'fill'=>$color{'fig_bg'}, 'stroke'=>$color{'fig_bg'},'stroke-width'=>5);

my $var=1000/$nums{$chr[$i]};

my $rx=50;
my $ry=50;
$svg -> line('x1'=>$rx, 'y1'=>$ry, 'x2'=>$rx, 'y2'=>$ry+500, 'fill'=>$color{'name'}, 'stroke'=>$color{'name'}, 'stroke-width'=>2); 

$rx=50; 
$ry=550; 
$svg -> line('x1'=>$rx, 'y1'=>$ry, 'x2'=>$rx+1000, 'y2'=>$ry, 'fill'=>$color{'name'}, 'stroke'=>$color{'name'}, 'stroke-width'=>2);

my $len=int($nums{$chr[$i]}/5); ##2Mb

my $tickry = 550; 
my $rxbefore=50;

for(my $j=1;$j<=$len;$j++)
{
 my $axis=$j*10;
 my $ry=570;
 my $rx=50+($axis/2)*$var-5; ##2Mb
 my $tag=$svg -> text('x'=>$rx, 'y'=>$ry );

$svg->line('x1'=>$rx+5, 'x2'=>$rx+5, 'y1'=>$tickry,'y2'=>$tickry-14, 'fill'=>$color{'name'}, 'stroke'=>$color{'name'},'stroke-width'=>1);
$svg->line('x1'=>($rx +5 + $rxbefore)/2, 'x2'=>($rx +5 + $rxbefore)/2, 'y1'=>$tickry, 'y2'=>$tickry-7, 'fill'=>$color{'name'}, 'stroke'=>$color{'name'}, 'stroke-width'=>1);


 $tag->tspan('dx'=>0,'dy'=>0,'font-family'=>$font_family, 'font-size'=>'15', 'fill'=>'black', 'stroke'=>'black') -> cdata($axis);
$rxbefore=$rx + 5 ;
}

my $max=9; my $min=-9;

for(my $j=$min;$j<=$max;$j+=3)
{
 my $axis=$j;
 my $rx=40;
 my $ry=550-500*($axis-$min)/($max-$min);
 my $tag=$svg -> text('x'=>$rx, 'y'=>$ry, transform => "rotate(-90,$rx,$ry)");
 $tag->tspan('dx'=>0,'dy'=>0,'font-family'=>$font_family, 'font-size'=>'15', 'fill'=>'black', 'stroke'=>'black') -> cdata($axis);
}

##Title
$rx=550;
$ry=40;
my $title=$svg -> text('x'=>$rx, 'y'=>$ry );
$title->tspan('dx'=>0,'dy'=>0,'font-family'=>$font_family, 'font-size'=>"35", 'fill'=>$color{'name'}, 'stroke'=>$color{'name'}) -> cdata($chr[$i]);

##-3
$rx=50;
$ry=550-500*(-3-$min)/($max-$min);
$svg -> line('x1'=>$rx, 'y1'=>$ry, 'x2'=>$rx+1000, 'y2'=>$ry, 'fill'=>$color{'name'}, 'stroke'=>$color{'name'}, 'stroke-width'=>1,'stroke-dasharray'=>"20");

##0
$rx=50;
$ry=550-500*(0-$min)/($max-$min);
$svg -> line('x1'=>$rx, 'y1'=>$ry, 'x2'=>$rx+1000, 'y2'=>$ry, 'fill'=>$color{'name'}, 'stroke'=>$color{'name'}, 'stroke-width'=>1,'stroke-dasharray'=>"20");

##3
$rx=50;
$ry=550-500*(3-$min)/($max-$min);
$svg -> line('x1'=>$rx, 'y1'=>$ry, 'x2'=>$rx+1000, 'y2'=>$ry, 'fill'=>$color{'name'}, 'stroke'=>$color{'name'}, 'stroke-width'=>1,'stroke-dasharray'=>"20");


my @Line1=();
my @Line2=();
my @Pos=();

foreach my $pos (sort {$a<=>$b} keys %{$ZUF{$chr[$i]}})
{
 push(@Pos,$pos);
 push(@Line1,$ZUF{$chr[$i]}{$pos});
 push(@Line2,$ZSF{$chr[$i]}{$pos});
}

for(my $j=1;$j<=$#Line1;$j++)
{
 my $start=$Line1[$j-1]; if($start>$max) {$start=$max;} elsif($start<$min) {$start=$min;}
 my $end=$Line1[$j]; if($end>$max) {$end=$max;} elsif($end<$min) {$end=$min;}
 my $ry1=550-500*($start-$min)/($max-$min);
 my $rx1=50+$Pos[$j-1]*$var;
 my $ry2=550-500*($end-$min)/($max-$min);
 my $rx2=50+$Pos[$j]*$var;
 $svg -> line('x1'=>$rx1, 'y1'=>$ry1, 'x2'=>$rx2, 'y2'=>$ry2, 'fill'=>'green', 'stroke'=>'green', 'stroke-width'=>2);
 if(abs($start)>=3){
 $svg->circle('cx'=>$rx1,'cy'=>$ry1,'r'=>"5",'fill'=>'black','stroke'=>'black');
 }
 if(abs($end)>=3){
 $svg->circle('cx'=>$rx2,'cy'=>$ry2,'r'=>"5",'fill'=>'black','stroke'=>'black');
 }
}

for(my $j=1;$j<=$#Line2;$j++)
{
 my $start=$Line2[$j-1]; if($start>$max) {$start=$max;} elsif($start<$min) {$start=$min;}
 my $end=$Line2[$j]; if($end>$max) {$end=$max;} elsif($end<$min) {$end=$min;}
 my $ry1=550-500*($start-$min)/($max-$min);
 my $rx1=50+$Pos[$j-1]*$var;
 my $ry2=550-500*($end-$min)/($max-$min);
 my $rx2=50+$Pos[$j]*$var;
 $svg -> line('x1'=>$rx1, 'y1'=>$ry1, 'x2'=>$rx2, 'y2'=>$ry2, 'fill'=>'violet', 'stroke'=>'violet', 'stroke-width'=>2);
 if(abs($start)>=3){
 $svg->circle('cx'=>$rx1,'cy'=>$ry1,'r'=>"5",'fill'=>'red','stroke'=>'red');
 }
 if(abs($end)>=3){
 $svg->circle('cx'=>$rx2,'cy'=>$ry2,'r'=>"5",'fill'=>'red','stroke'=>'red');
 }
}

my $out=$ARGV[0]; $out=~s/.txt$//; $out.="_StoufferZScore_".$chr[$i].".svg";
open(OUT, '>',$out) || die "Can't output graph\n";
print OUT $svg->xmlify();
close(OUT);
my $png=$out; $png=~s/svg$/png/;
system("rsvg-convert -o $png $out");
system("rm $out");
my $repng=$png; $repng=~s/.png$/_resize.png/;
system("convert -resize 550x300 $png $repng");
system("rm $png");
push(@all,$repng);
}

##creat html
my $upload="";
my @html=();
my $info="\<\!DOCTYPE html PUBLIC \"\-\/\/W3C\/\/DTD XHTML 1.0 Transitional\/\/EN\" \"http\:\/\/www\.w3\.org\/TR\/xhtml1\/DTD\/xhtml1\-transitional\.dtd\"\>\n\<html xmlns\=\"http\:\/\/www\.w3\.org\/1999\/xhtml\"\>\n\<head\>\n\<meta http\-equiv\=\"Content-Type\" content\=\"text\/html\; charset\=utf\-8\" \/\>\n\<title\>".$id."\<\/title\>\n\<\/head\>\n\n\<body style\=\"padding\:0\; margin\:0\;\"\>\n\n";
push(@html,$info);

$info="\<div style\=\"width\:1000px\;margin\: 0 auto\;color:green;font-weight:blod\"\>\<b\>Green Line\: \<\/b\>U Test Z-Score\<\/div\>\n\<div style\=\"width\:1000px\;margin\: 0 auto\;color:black;font-weight:blod\"\>\<b\>Black Point\: \<\/b\>U Test Abnormal Z-Score\(\>\=3 or \<\=\-3\)\<\/div\>\n\<div style\=\"width\:1000px\;margin\: 0 auto\;color:violet;font-weight:blod\"\>\<b\>Violet Line\: \<\/b\>CNV U Test Z-Score\<\/div\>\n\<div style\=\"width\:1000px\;margin\: 0 auto\;color:red;font-weight:blod\"\>\<b\>Red Point\: \<\/b\>CNV U Test Abnormal Z-Score\(\>\=3 or  \<\=\-3\)\<\/div\>\n";
push(@html,$info);
$upload.=$info;

for(my $i=0;$i<$#all;$i+=2)
{
 my $png1=$all[$i]; my $p1=`base64 -w 0 $png1`;
 my $png2=$all[$i+1]; my $p2=`base64 -w 0 $png2`;
 $info="\<div style\=\"width\:1100px\;margin\: 0 auto\;\"\>\n";
 push(@html,$info);
 $upload.=$info;
 $info="\<img style\=\"float\:left\;max\-width\:550px\" src\=\"data\:image\/png\;base64\,".$p1."\" \/\>\n";
 push(@html,$info);
 $upload.=$info;
 $info="\<img style\=\"float\:right\;max\-width\:550px\" src\=\"data\:image\/png\;base64\,".$p2."\" \/\>\n";
 push(@html,$info);
 $upload.=$info;
 $info="\<\/div\>\n\n";
 push(@html,$info);
 $upload.=$info;
 system("rm $png1"); system("rm $png2");
}
 $info="\<\/body\>\n\<\/html\>\n";
 push(@html,$info);
 my $HTML=$ARGV[0]; $HTML=~s/txt$/html/;
 open(HM,">$HTML");
 print HM "@html";
 close(HM);
  
 my $UPHTML=$ARGV[0]; $UPHTML=~s/.txt$/_upload.html/;
 open(UP,">$UPHTML");
 print UP "$upload";
 close(UP);
