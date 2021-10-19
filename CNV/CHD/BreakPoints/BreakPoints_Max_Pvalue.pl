#!/usr/bin/perl -w
use strict;
use List::Util qw/min max/;
use Statistics::Descriptive;
use Statistics::Distributions;
use Statistics::Sequences::Runs;

open(F1,$ARGV[0]); ##Normalized LogRR file
open(F2,$ARGV[1]); ##CBS results

my %LogRR=();
my $size=20*1000;
my @AZ=();
while(<F1>)
{
 next if $_=~/^Chromosome/;
 chomp($_);
 my @tmp=split /\t/,$_;
 if($tmp[3]!~"NA")
 {
 $LogRR{$tmp[0]}{$tmp[1]}=$tmp[4];    ##参考样本多时选择ZScore ##参考样本少时选择LogRR
 push(@AZ,$tmp[4]);
 }
}
close(F1);

my %record=();
my $lines=0;
while(<F2>)
{
 next if $_=~/^ID/;
 $lines+=1;
 chomp($_);
 my @tmp=split /\t/,$_;
 $record{$tmp[1]}{$lines}=$_;
}
close(F2);

my @AZ1=();
my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@AZ);
my $Q1=$stat->percentile(25);
my $Q3=$stat->percentile(75);
$stat->clear();
my $IQR=$Q3-$Q1;
for(my $i=0;$i<=$#AZ;$i++)
{
 if($AZ[$i]<=($Q3+3*$IQR) && $AZ[$i]>=($Q1-3*$IQR))
 {push(@AZ1,$AZ[$i]);}
}


my %hash_equal=();

print "ID	chrom	loc.start	loc.end	num.mark	seg.mean	Runs.pvalue\n";

HASH_END:while(1)
{
 my $cutoff="";
 #if($ARGV[0]=~/All_Normalized/) {$cutoff=1e-5;}
 #elsif($ARGV[0]=~/All_Merge_Normalized/) {$cutoff=1e-3;}
 $cutoff=1e-5;
 
 my $ret= is_hash_equal(\%hash_equal,\%record);
 if($ret eq "equal") {last HASH_END;}
 else{
 %hash_equal=%record;
 }
 
 foreach my $k1 (sort {$a cmp $b} keys %record)
 {
  my $chr=$k1;
  my @TM=();
  foreach my $k2 (sort {$a <=> $b} keys %{$record{$k1}})
  {
  push(@TM,$k2);
  }
  LA:while(1)
  {
  my %pvalue=();
  for(my $tm=0;$tm<=$#TM;$tm++)
  {
   my $p1=$TM[$tm];
   my $p2=$TM[$tm]+1;
   if(exists $record{$chr}{$p2})
   {
   my @t1=split /\t/,$record{$chr}{$p1};
   my @t2=split /\t/,$record{$chr}{$p2};
   my $s1=$t1[2]; my $e1=$t1[3];
   my $s2=$t2[2]; my $e2=$t2[3];
   my @RR_A=(); my @RR_B=();
   for(my $i=$s1;$i<=$e1;$i+=$size)
   {
    if(exists $LogRR{$chr}{$i} && $LogRR{$chr}{$i} ne "NA")
    {
      my $value=$LogRR{$chr}{$i};
      push(@RR_A,$value);
    }
   }
   for(my $i=$s2;$i<=$e2;$i+=$size)
   {
    if(exists $LogRR{$chr}{$i} && $LogRR{$chr}{$i} ne "NA")
    {
     my $value=$LogRR{$chr}{$i};
     push(@RR_B,$value);
    }
   }
   ##Runs test
   my $probA = RunsTest(\@RR_A,\@RR_B);
   $pvalue{$chr}{$p1}=$probA;
   }
  }
  if(exists $pvalue{$chr}){
   my @keys=();
   @keys=sort { $pvalue{$chr}{$a} <=> $pvalue{$chr}{$b} } keys %{$pvalue{$chr}};
   LB:while(1){
  if(@keys){
  ##max pvalue
  my $max=$keys[$#keys];
  if($pvalue{$chr}{$max}>$cutoff){
   my $p1=$max;
   my $p2=$max+1;
   my @t1=split /\t/,$record{$chr}{$p1};
   my @t2=split /\t/,$record{$chr}{$p2};
   my $s1=$t1[2]; my $e1=$t1[3];
   my $s2=$t2[2]; my $e2=$t2[3];
   my @RR_A=(); my @RR_B=();
   for(my $i=$s1;$i<=$e1;$i+=$size)
   {
    if(exists $LogRR{$chr}{$i} && $LogRR{$chr}{$i} ne "NA")
    {
     my $value=$LogRR{$chr}{$i};
     push(@RR_A,$value);
    }
   }
   for(my $i=$s2;$i<=$e2;$i+=$size)
   {
    if(exists $LogRR{$chr}{$i} && $LogRR{$chr}{$i} ne "NA")
    {
     my $value=$LogRR{$chr}{$i};
     push(@RR_B,$value);
    }
   }

   ##Runs test
   my $probA = RunsTest(\@RR_A,\@RR_B);
   
   ##Mean
   my ($meanA,$sdA) = Mean_SD(\@RR_A);
   my ($meanB,$sdB) = Mean_SD(\@RR_B);

   my $PZS=abs(($meanA-$meanB)/sqrt(($sdA**2/($#RR_A+1))+($sdB**2/($#RR_B+1))));
   
     if($probA>$cutoff){
      my $segment=($meanA*($#RR_A+1)+$meanB*($#RR_B+1))/($#RR_A+1+$#RR_B+1);
      $segment=sprintf("%.4f",$segment);
      my $bins=$#RR_A+1+$#RR_B+1;
	  my @RRZ=();
	  @RRZ=(@RR_A,@RR_B);
	  my $p_value=PValue(\@RRZ,\@AZ1);
      $record{$chr}{$p1}="$t1[0]	$chr	$s1	$e2	$bins	$segment	$p_value";
	  delete $record{$chr}{$p2};
	  for(my $i=$p2;$i<$TM[$#TM];$i++)
	  {
	   $record{$chr}{$i}=$record{$chr}{$i+1};
	   delete $record{$chr}{$i+1};
	  }
	  splice(@TM,-1,1);
	  next LA;
   }
	 else{
	 my @tmp=split /\t/,$record{$chr}{$p1};
	  my @RRZ=();
	  @RRZ=@RR_A;
	 my $p_value=PValue(\@RRZ,\@AZ1);
     if($#tmp==5) {$record{$chr}{$p1}=$record{$chr}{$p1}."\t".$p_value;}
     else {$record{$chr}{$p1}="$tmp[0]	$tmp[1]	$tmp[2]	$tmp[3]	$tmp[4]	$tmp[5]	$p_value";}
	 splice(@keys,-1,1); 
	 next LB;
	 }
  }
  else{last LA;}
  }
  else{last LA;}
   }
  }
  else{last LA;}
  }
 }
}

 foreach my $k1 (sort {$a cmp $b} keys %record)
 {
  foreach my $k2 (sort {$a <=> $b} keys %{$record{$k1}})
  {
   my @tmp=split /\t/,$record{$k1}{$k2};
   my $s1=$tmp[2]; my $e1=$tmp[3];
   my @RR_A=();
   for(my $i=$s1;$i<=$e1;$i+=$size)
   {
    if(exists $LogRR{$k1}{$i} && $LogRR{$k1}{$i} ne "NA")
    {
     my $value=$LogRR{$k1}{$i};
     push(@RR_A,$value);
    }
   }
	  my @RRZ=();
	  @RRZ=@RR_A;
	 my $p_value=PValue(\@RRZ,\@AZ1);
   if($#tmp==5) {print $record{$k1}{$k2}."\t$p_value\n";}
   else {print $record{$k1}{$k2}."\n";}
   #print "$tmp[0]	$tmp[1]	$tmp[2]	$tmp[3]	$tmp[4]	$tmp[5]	$p_value\n";
  }
 }


sub RunsTest{
   my @Data1=@{$_[0]};
   my @Data2=@{$_[1]};
   my %data;
   foreach(0..$#Data1){
   $data{$Data1[$_]}=1;
   }
   foreach(0..$#Data2){
   $data{$Data2[$_]}=0;
   }
   my @runs;
   foreach(sort {$a <=> $b} keys %data){
      push @runs,$data{$_};
   }
   my $Runs = Statistics::Sequences::Runs->new();
   $Runs->load(@runs);
   my $prob = $Runs->p_value();
   return $prob;
}

sub Mean_SD{
   my @Data=@{$_[0]};
   my $stat = Statistics::Descriptive::Full->new();
   $stat->add_data(@Data);
   my $mean = $stat->mean();
   my $sd = $stat->standard_deviation();
   $stat->clear();
   return ($mean,$sd);
}

sub PValue{
	my @data=@{$_[0]};
    my @Data2=@{$_[1]};
	my $PValue=1;
	if(@data>1){
		my ($mean,$sd)=Mean_SD(\@Data2);
        my $sum=0;
		foreach (@data){	$sum += (($_-$mean)/$sd)**2;	}
		$PValue=Statistics::Distributions::chisqrprob(scalar(@data),$sum);
		#print scalar(@data)."\t".$sum."\n";
	}
	$PValue=sprintf("%.2e",$PValue);
	return $PValue;
}

sub is_hash_equal{  
    my $h = shift;  
    my $h2 = shift;  
    my $r = {};  
    map { $r->{$_}->{$h->{$_}}++ } keys %$h;  
    my $ans = grep { ++$r->{$_}->{$h2->{$_}} == 1} keys %$h2;  
    if ($ans) {  
    return "not equal";  
    } else {  
    return "equal";  
    }  
}

