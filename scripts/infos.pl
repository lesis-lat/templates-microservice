#!/usr/bin/env perl

use strict;
use warnings;
use YAML::XS qw(LoadFile);
use File::Find;
use utf8;

binmode(STDOUT, ":utf8");

my %categories;
my %types;

sub extract_fields {
    my ($file) = @_;
    return if $file =~ m{/index\.ya?ml$};

    my $data;
    eval {
        $data = LoadFile($file);
    };
    return if $@;
    return unless ref $data eq 'HASH';
    return unless exists $data->{vulnerability} && ref $data->{vulnerability} eq 'HASH';

    my $vuln = $data->{vulnerability};

    if (defined $vuln->{category} && $vuln->{category} ne '') {
        $categories{$vuln->{category}}++;
    }

    if (defined $vuln->{type} && $vuln->{type} ne '') {
        $types{$vuln->{type}}++;
    }
}

sub find_yaml_files {
    my ($dir) = @_;
    my @files;

    find(
        sub {
            return unless -f $_ && $_ =~ /\.ya?ml$/;
            push @files, $File::Find::name;
        },
        $dir
    );

    return @files;
}

sub main {
    my $dir = shift @ARGV or die "Usage: $0 <directory>\n";
    my @yamls = find_yaml_files($dir);

    foreach my $file (@yamls) {
        extract_fields($file);
    }

    print "Unique categories:\n";
    foreach my $cat (sort keys %categories) {
        print "- $cat ($categories{$cat})\n";
    }

    print "\nUnique types:\n";
    foreach my $type (sort keys %types) {
        print "- $type ($types{$type})\n";
    }
}

main();

