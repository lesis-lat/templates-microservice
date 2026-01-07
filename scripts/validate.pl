#!/usr/bin/env perl

our $VERSION = '0.01';

use strict;
use warnings;
use YAML::XS qw(LoadFile);
use File::Find;
use utf8;
use English qw(-no_match_vars);

binmode(STDOUT, ":encoding(UTF-8)");

sub validate_yaml {
    my ($file) = @_;
    if ( $file =~ m{/index\.ya?ml$}msx ) {
        return;
    }

    my $data;
    my $eval_ok = eval { $data = LoadFile($file); 1 };
    if ( !$eval_ok ) {
        print "[ERROR] Failed to load YAML: $file\n$EVAL_ERROR\n";
        return;
    }
    if ( ref $data ne 'HASH' ) {
        return;
    }
    if ( !( exists $data->{vulnerability} && ref $data->{vulnerability} eq 'HASH' ) ) {
        return;
    }

    my $vuln = $data->{vulnerability};

    my %required_langs = map { $_ => 1 } qw(pt-br en es);
    my %text_fields    = map { $_ => 1 } qw(name description recommendation);

    for my $field (keys %text_fields) {
        if ( !( exists $vuln->{$field} && ref $vuln->{$field} eq 'HASH' ) ) {
            print "[ERROR] Missing or malformed field '$field' in $file\n";
            next;
        }
        for my $lang (keys %required_langs) {
            if ( !( exists $vuln->{$field}{$lang} && defined $vuln->{$field}{$lang} && $vuln->{$field}{$lang} ne q{} ) ) {
                print "[ERROR] Missing translation: $field -> $lang in $file\n";
            }
        }
    }

    my %required_fields = map { $_ => 1 } qw(type category references);
    for my $field (keys %required_fields) {
        if ( !exists $vuln->{$field} ) {
            print "[ERROR] Missing required field '$field' in $file\n";
        }
    }

    if ( exists $vuln->{references} ) {
        if ( ref $vuln->{references} ne 'ARRAY' ) {
            print "[ERROR] Field 'references' must be a list in $file\n";
        }
    }
    return;
}

sub find_yaml_files {
    my ($dir) = @_;
    my @files;
    find(
        sub {
            if (-f && /\.ya?ml$/msx) {
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
    for my $file (@yamls) {
        validate_yaml($file);
    }
    return;
}

main();
