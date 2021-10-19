 perl -ane 'chomp;$i=1;my @tmp=split /\t/ ; print join("\t",$tmp[$#tmp],map {$i++.":".$_} @tmp[0..$#tmp-1]),"\n"' train.txt
