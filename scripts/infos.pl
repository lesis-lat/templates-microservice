#!/usr/bin/env perl

our $VERSION = '0.01';

use strict;
use warnings;
use YAML::XS qw(LoadFile);
use File::Find;
use utf8;
use English qw(-no_match_vars);

binmode(STDOUT, ":encoding(UTF-8)");

my %categories;
my %types;

sub extract_fields {
    my ($file) = @_;
    if ( $file =~ m{/index\.ya?ml$}msx ) {
        return;
    }

    my $data;
    my $eval_ok = eval { $data = LoadFile($file); 1 };
    if ( !$eval_ok ) {
        return;
    }
    if ( !( ref $data eq 'HASH' ) ) {
        return;
    }
    if ( !( exists $data->{vulnerability} && ref $data->{vulnerability} eq 'HASH' ) ) {
        return;
    }

    my $vuln = $data->{vulnerability};

    if ( defined $vuln->{category} && $vuln->{category} ne q{} ) {
        $categories{ $vuln->{category} }++;
    }

    if ( defined $vuln->{type} && $vuln->{type} ne q{} ) {
        $types{ $vuln->{type} }++;
    }
    return;
}

sub find_yaml_files {
    my ($dir) = @_;
    my @files;

    find(
        sub {
            if ( -f && /\.ya?ml$/msx ) {
                push @files, $File::Find::name;
            }
        },
        $dir
    );

    return @files;
}

sub main {
    my $dir = shift @ARGV or die "Usage: $PROGRAM_NAME <directory>\n";
    my @yamls = find_yaml_files($dir);

    foreach my $file (@yamls) {
        extract_fields($file);
    }

    print "Unique categories:\n";
    foreach my $cat ( sort keys %categories ) {
        print "- $cat ($categories{$cat})\n";
    }

    print "\nUnique types:\n";
    foreach my $type ( sort keys %types ) {
        print "- $type ($types{$type})\n";
    }
    return;
}

main();

