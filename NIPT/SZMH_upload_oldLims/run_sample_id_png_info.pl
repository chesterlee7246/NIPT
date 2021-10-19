#!/usr/bin/perl -w
use strict;

my $dir=$ARGV[0];  ##ARGV[0]:运行run产生的结果目录

my $f1=$ARGV[0]."/expMeta.dat";  ##ARGV[1]：运行run产生根目录
my $index2id=$dir."/index2id.txt";

my $path=$ARGV[1]; ##脚本目录

open(F1,$f1);
my $run_name="";
while(<F1>)
{
  if($_=~/^Run Name/){
   $_=~s/\s+//g;
   my @tmp=split /[\_\-\.]/,$_;
   for(my $i=0;$i<=$#tmp;$i++)
   {
    if($tmp[$i]=~/^SQR/) {
    $run_name=$tmp[$i];
    next;}
   }
  }
}
close(F1);

open(F2,$index2id);
my %hash=();
while(<F2>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 $hash{$tmp[0]}=$tmp[1];
}
close(F2);

opendir(PH,$dir);

while(my $file=readdir(PH))
{
 if($file=~/MAPQ60_Fbin_GC_All_Merge_ZScore_FLasso_Value_FLasso.html$/)
 {
  my $out=$dir."/".$file;
  my $index=substr($file,0,13);
  my $id=$hash{$index};
  my $ind=substr($file,11,2);
  if(-e $dir."/".$index."_rawlib_rmdup_MAPQ60_Fbin_GC_All_Merge_ZScore_FLasso_Value_FLasso.html.bak"){
  		my $bf=$dir."/".$index."_rawlib_rmdup_MAPQ60_Fbin_GC_All_Merge_ZScore_FLasso_Value_FLasso.html.bak";
  		system("mv $bf $file")
		}
  my $out_temp=$dir."/".$file."_temp";
  &CHD_OUT($out,$out_temp,$index);
  system("mv $out $out.bak");
  system("mv $out_temp $out");
  if($ind=~/^0/) {$ind=substr($ind,1,1);}
  my $s1=$path."/run_sample_id_png_info.py";
  print("python $s1 $run_name $id $ind $out");
  system("python $s1 $run_name $id $ind $out");
#  system("rm $out");
 }
}
closedir(PH);

sub CHD_OUT{
	my($inf,$outf,$indx)=@_;
	open IN,$inf || die $!;
	open OUT,">$outf" || die $!;
	while(<IN>){
		$_=~s/[\r\n]//g;
		if($_=~/<body style="padding:0.*>/){
		print OUT $_."\n";
		print OUT "<div style=\"width:1000px;margin: 0 auto;color:blue;font-weight:blod\">CNV Result:<\/div>\n";
#		print OUT "<p align=\"center\"><strong>Table 1 <\/strong>CNV result<\/p>\n";
#		print OUT "<table frame=\"box\" rules=\"all\" align=\"center\">\n";
		my $cyb_file=$dir."/".$indx."_100Kb_DNAcopy_Info_CNV_RealCNV_LogRR_Effective_Extract_Abnormal_CNV_Merge_100Kb_Cytoband.txt";
		open INT,$cyb_file || die $!;
		my $i=0;
		my $cyb_out;
		$cyb_out.="<p align=\"center\"><strong>Table 1 </strong>CNV result</p>\n";
		$cyb_out.="<table frame=\"box\" rules=\"all\" align=\"center\">\n";
		while(<INT>){
			$i+=1;
			$_=~s/[\r\n]//g;
			my @arr=split/\t/,$_;
			if($i==1){
				$cyb_out.="<tr>\n<th>$arr[1]</th><th>$arr[2]</th><th>$arr[3]</th><th>log2RR</th><th>$arr[8]</th><th>$arr[9]</th><th>$arr[13]</th>\n</tr>\n"
				}else{
					if ($arr[1] eq "chrX"){$i=$i-1;next;}
					if ($arr[1] eq "chrY"){$i=$i-1;next;}
					if (int($arr[8]) < int(500000)){$i=$i-1;next;}
					my $size;
					if (int($arr[8]) < int(1000000)){
					$size=sprintf "%.2f",$arr[8]/1000;
					$size=$size."Kb"}else{
					$size=sprintf "%.2f",$arr[8]/1000000;
					$size=$size."Mb"}
					$cyb_out.="<tr>\n<td>$arr[1]</td><td>$arr[2]</td><td>$arr[3]</td><td>$arr[5]</td><td>$size</td><td>$arr[9]</td><td>$arr[13]</td>\n</tr>\n"}
					}
		close INT;
		$cyb_out.="</tr>\n</table>\n<p></p>\n<p></p>\n";
		if($i<=1){$cyb_out="<p align=\"center\"><strong>None:  </strong> NO CNVs </p>\n"}
		print OUT $cyb_out ;
		print OUT "<div style=\"width:1100px;margin: 0 auto;\">\n";
		my $fig=$dir."/".$indx."_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge_Normalized_LogRR_Extract_CNV_ConvertValue_Autosomal.png";
		my $fig_64=`base64 $fig`;
		my $fig_info="<img style=\"float:center;max-width:1100px\" src=\"data:image/png;base64,".$fig_64."\">\n";
		print OUT $fig_info;
		print OUT "</div>\n";
		}else{
			print OUT $_."\n";
			}
		}
		close IN;
		close OUT;
} 




