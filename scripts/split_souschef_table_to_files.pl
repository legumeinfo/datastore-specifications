#!/usr/bin/env perl 

# Program: split_souschef_table_to_files.pl
# S. Cannon 

use strict;
use warnings;
use Getopt::Long;
use feature "say";

my ($input_table, $out_dir, $help);

GetOptions (
  "input_table=s" => \$input_table,
  "out_dir=s"     => \$out_dir,
  "help"          => \$help
);

my $usage = <<EOS;
Usage: $0  -in input_table -out out_dir  
  Input is a table to be split into yaml-format files, with the latter 
  named by names in the first row of the input table.
  
  Required:
  -input_table  Name of input table to be split
  -out_dir   Name of directory for output

  Optional:
  -help         Displays this info
EOS

die "\n$usage\n" if $help;
die "\n$usage\n" unless ($input_table && $out_dir); 

opendir (DIR, "$out_dir") or mkdir($out_dir); close DIR;

open (my $IN, '<', $input_table) or die "can't open in $input_table:$!";

my %seen;
my @header;

while (my $line = <$IN>) {
  chomp $line;  

  my @elements = split /\t/, $line;

  my $line_number = $.;
  if ( $line_number == 1 ){
    @header = @elements;
    say join (" ", @header);
    shift @elements;
    shift @header;
    next;
  }

  my $i=0;
  my $file_out = $elements[$i];
  $i++;
  
  if ($seen{$file_out}) { next }
  else {
    $seen{$file_out}++;
    open (my $OUT, ">", "$out_dir/$file_out") or die "can't open out $out_dir/$file_out: $!";
    say "Printing $file_out";
    say $OUT "---";
    for my $key (@header){
      my $value = $elements[$i];
      if ($key =~ /directories|prefixes|collection_info|readme_info|from_to_annot/ ||
          $key =~ /from_to_genome|from_to_cds_mrna|from_to_protein|from_to_gff/){
        say $OUT "$key:";
        $i++;
      }
      else { # Not header elements (yml keys), so say values
        if ($key eq "from" || $key eq "identifier" ){
          print $OUT "  - ";
          if ($value){
            say $OUT "$key: $value";
          }
          else {
            say $OUT "$key: ";
          }
        }
        else {
          if ($value){
            say $OUT "    $key: $value";
          }
          else {
            say $OUT "    $key: ";
          }
        }
        $i++;
      }
    }
  }
}

__END__

# S. Cannon
# 2022-12-11 Initial version, based on split_table_to_files.pl and split_gene_fn_table_to_files.pl
# 2023-01-04 Add keys for about_this_collection/description_Genus_species.yml files
