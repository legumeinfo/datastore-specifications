#!/usr/bin/env perl
use strict;
use Getopt::Long;
my @clobber_types;
GetOptions(
    "clobber_type=s" => \@clobber_types,
);
my %clobber_types = map {$_ => 1;} @clobber_types;
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
        print;
        print "\n";
    }
    else {
        my $parent = $attrs{Parent};
        my $count_by_type = $children_count{$parent};
        if (!defined $count_by_type) {
            $count_by_type = {};
            $children_count{$parent} = $count_by_type;
        }
        my $type = $data[2];
        my $count = ++$count_by_type->{$type};
        if ($attrs{ID}) {
            $attrs =~ s/\bID=[^;]*;?//;
        }
        $attrs = "ID=$parent-$type-$count;".$attrs;
        $data[8] = $attrs;
        print join("\t", @data), "\n";
    }

}
