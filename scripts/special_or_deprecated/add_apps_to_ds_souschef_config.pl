#!/usr/bin/env perl
  
use warnings;
use strict;
use feature "say";

my $usage = <<EOS;
  Synopsis: ls *gz | write_main.pl -corr FILE.yml -descr FILE.yml -apps FILE.yml [options]

  This is a (probably throwaway) script to add "applications" keys and values to 
  yml config files for ds_souschef.pl
EOS

while (<>){
  my $line = $_;
  if ($line =~ /"Primary genome assembly"/ || 
      $line =~ /"cds sequences"/ ) {
    print $line;
    say "    applications:";
    say "      - blast";
    say "      - mines";
  }
  elsif ($line =~ /"Transcript sequences"/ ||
         $line =~ /"Gene models, with exon features"/ ){
    print $line;
    say "    applications:";
    say "      - mines";
  }
  elsif ($line =~ /"Protein sequences"/ ){
    print $line;
    say "    applications:";
    say "      - mines";
  }
  elsif ($line =~ /"Gene models - main"/ ){
    print $line;
    say "    applications:";
    say "      - mines";
    say "      - jbrowse-index";
  }
  else {
    print $line;
  }
}

__END__

S. Cannon
2024-12-10 Initial version

