#!/usr/bin/env perl
use strict;
use Getopt::Long;
my @clobber_types;
GetOptions(
  "clobber_type=s" => \@clobber_types,
);
my %clobber_types = map {$_ => 1;} @clobber_types;
#need to remember IDs we've clobbered in case they are used as Parent references
my %clobbered_map;
#we'll use a strategy where IDs are based on parent IDs + counts for uniqueness
my %children_count;
while (<>) {
  if (/^#/) {
    print;
    next;
  }
  chomp;
  my @data=split /\t/;
  my $attrs = $data[8];
  my @attrs = split /;/, $attrs;
  my %attrs = map {my ($key, $value) = /^([^=]+)=(.*)/; $key => $value;} @attrs;
  if ($attrs{ID} && ! $clobber_types{$data[2]}) {
  my $parent = $attrs{Parent};
    if (defined $clobbered_map{$parent}) {
      s/\bParent=$parent/Parent=$clobbered_map{$parent}/;
    }
    print;
    print "\n";
  }
  else {
    my $parent = $attrs{Parent};
    if (defined $clobbered_map{$parent}) {
      s/\bParent=$parent/Parent=$clobbered_map{$parent}/;
    }
    my $count_by_type = $children_count{$parent};
    if (!defined $count_by_type) {
      $count_by_type = {};
      $children_count{$parent} = $count_by_type;
    }
    my $type = $data[2];
    my $count = ++$count_by_type->{$type};
    #FIXME: if parent is not defined we need to get full yuck prefixing by another means; 
    # probably just needs the user to specify it explicitly, unless we want to try finessing it from 
    # somewhere else in the file or name (seems dangerous and/or would preclude piping to STDIN)
    my $new_id = (defined $parent ? "$parent-" : "") . "$type-$count";
    if ($attrs{ID}) {
      $attrs =~ s/\bID=([^;]*);?//;
      print STDERR "$1\t$new_id\n";
      $clobbered_map{$1} = $new_id;
    }
    $attrs = "ID=$new_id;".$attrs;
    $data[8] = $attrs;
    print join("\t", @data), "\n";
  }
}

