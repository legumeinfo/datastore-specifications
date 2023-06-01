#!/usr/bin/env perl

use strict;
use warnings;
use feature "say";
use Getopt::Long;

my $usage = <<EOS;
  Synopsis: gzcat GFF_FILE.gff3.gz | rename_gff_IDs.pl [options] 
       OR     hash_into_gff_id.pl [options] < GFF_FILE.gff3
  
  Read a GFF file from STDIN. 
  Swap the feature IDs with the values from the Name or the Parent attribute.

  NOTE: The GFF input file should be structurally correct and sorted.
  
  Required:
    GFF file in stream via STDIN

  Options:
    -ID_regex  (string) Pattern for the base ID, preceeding e.g. .CDS.1 or .three_prime_UTR.1
                        Default: '\\w+:\\d+'
    -help      (boolean) This message.
EOS

my $help;
my $ID_regex = '\w+:\d+';

GetOptions (
  "ID_regex:s" =>  \$ID_regex,
  "help" =>        \$help,
);

die "$usage" if ($help);

# Read the GFF contents. Store for later use, and remember ID :: Name pairs for mRNA features
my (%id_names, %id_parents, @whole_gff);
while (<STDIN>) {
  s/\r?\n\z//; # CRLF to LF
  chomp;
  push(@whole_gff, $_);
  next if ($_ =~ /^#/);
  
  my @fields = split(/\t/, $_);
  my @attrs = split(/;/, $fields[8]);
  if ($fields[2] !~ /mRNA/){ 
    next;  # skip everything but mRNA features
  }
  else {
    my ($ID, $Name, $Parent);
    foreach my $attr (@attrs){
      my ($k, $v) = split(/=/, $attr);
      if ($k =~ /\bID/){ $ID = $v }
      elsif ($k =~ /\bName/){ $Name = $v }
      elsif ($k =~ /\bParent/){ $Parent = $v }
      else {  }
    }
    $id_names{$ID} = $Name;
    $id_parents{$ID} = $Parent;
    # say "AA: $ID\t$Name\t$Parent";
  }
}

# Process the GFF contents
my $comment_string = "";
my ($gene_name, $new_ID);
my ($prev_Name, $prev_ID, $prev_Parent);
my $tcpt_ct = 0;
my $ID_REX = qr/$ID_regex/;
foreach my $line (@whole_gff) {
  if ($line =~ /(^#.+)/) { # print comment line 
    say $1;
  }
  else { # body of the GFF
    my @fields = split(/\t/, $line);
    
    my @attrs = split(/;/, $fields[8]);
    my ($ID, $Name, $Parent);
    foreach my $attr (@attrs){
      my ($k, $v) = split(/=/, $attr);
      if ($k =~ /\bID/){ $ID = $v }
      elsif ($k =~ /\bName/){ $Name = $v }
      elsif ($k =~ /\bParent/){ $Parent = $v }
    }

    if ($fields[2] =~ /gene/){
      $tcpt_ct = 0;
      $prev_Name = $Name;
      say join("\t", @fields[0..7], "ID=$ID;Name=$Name");
    }
    elsif ($fields[2] =~ /mRNA/){
      $tcpt_ct++;
      $new_ID = "$Name";
      $prev_Parent = $new_ID;
      say join("\t", @fields[0..7], "ID=$new_ID;Name=$Name;Parent=$Parent");
    }
    else { # feature is something other than gene or mRNA
      my $ID_base = $ID;
      $ID_base =~ s/($ID_regex)\.(.+)/$1/;
      my $ID_suffix = $2;
      #say "XX: $ID  $ID_base  $ID_suffix  $id_names{$ID_base}  $id_parents{$ID_base}";
      my $new_ID = "$id_names{$ID_base}.$ID_suffix";
      my $new_Parent = $id_names{$ID_base};
      #say "YY: NEWID=$new_ID;Parent=$new_Parent";
      say join("\t", @fields[0..7], "ID=$new_ID;Parent=$new_Parent");
    }
  }
}

__END__

Steven Cannon
Versions
v01 2023-06-01 New script. 


