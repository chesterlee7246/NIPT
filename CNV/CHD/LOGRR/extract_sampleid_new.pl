#!/usr/bin/perl
use JSON;
use Data::Dumper;

my $json = new JSON;

my $js;
open JFILE, "$ARGV[0]";
open TO,">$ARGV[1]";
while(<JFILE>) {
   $js .= "$_";
}
my $obj = $json->decode($js);
#print TO Dumper($obj);

for(my $i=1;$i<=96;$i++)
{
 my $index="IonXpress_".sprintf("%03d",$i);
 my $info=$obj->{'barcodeInfo'}->{$index}->{'sample'};
 my $info=Dumper($info);
 chomp($info);
 $info=~s/^\$VAR1//;
 $info=~s/[=';]//g;
 $info=~s/\s+//g;
 if($info ne "none"){
 #print "$info	$index\n";
 my $objj=$json->decode($obj->{'experimentAnalysisSettings'}->{'barcodedSamples'});
 #my $objj=Dumper($objj);
 #print "$objj\n";
 my $des=$objj->{$info}->{'barcodeSampleInfo'}->{$index}->{'externalId'};
 my $des=Dumper($des);
 #print "$des\n";
 chomp($des);
 $des=~s/^\$VAR1//;
 $des=~s/[=';]//g;
 $des=~s/\s+//g;
 if($des eq "" || $des eq "undef")
 {$des=$obj->{'sampleInfo'}->{$info}->{'externalId'};
 my $des=Dumper($des);
 chomp($des);
 $des=~s/^\$VAR1//;
 $des=~s/[=';]//g;
 $des=~s/\s+//g;
 }
 #my $YY=$objj->{$info}->{'barcodeSampleInfo'}->{$index}->{'description'};
 #my $YY=Dumper($YY);
 #print "$YY\n";
 #chomp($YY);
 #$YY=~s/^\$VAR1//;
 #$YY=~s/[=';]//g;
 #$YY=~s/\s+//g;
 #if($YY eq "" || $YY eq "undef"){
 $YY=$obj->{'sampleInfo'}->{$info}->{'description'};
 my $YY=Dumper($YY);
 chomp($YY);
 $YY=~s/^\$VAR1//;
 $YY=~s/[=';]//g;
 $YY=~s/\s+//g;
 #}

 if($des eq "") {$des="null";}
 if($YY eq "") {$YY="null";}

 print TO $index."\t".$info."\t".$des."\t".$YY."\n";
 }
}

close(TO);
close(JFILE);
