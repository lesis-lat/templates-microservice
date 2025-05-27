#!/usr/bin/env perl

use strict;
use warnings;
use YAML::XS qw(LoadFile);
use File::Find;
use Encode qw(decode);
use utf8;

binmode(STDOUT, ":utf8");

sub validate_yaml {
    my ($file) = @_;
    return if $file =~ m{/index\.ya?ml$};

    my $data;

    eval {
        $data = LoadFile($file);
    };
    if ($@) {
        print "[ERROR] Failed to load YAML: $file\n$@\n";
        return;
    }

    unless (ref $data eq 'HASH') {
        print "[ERROR] Invalid YAML (expected a hash): $file\n";
        return;
    }

    unless (exists $data->{vulnerability} && ref $data->{vulnerability} eq 'HASH') {
        print "[ERROR] Invalid structure: 'vulnerability' key missing or malformed in $file\n";
        return;
    }

    my $vuln = $data->{vulnerability};

    my @required_langs = qw(pt-br en es);
    my @text_fields = qw(name description recommendation);

    foreach my $field (@text_fields) {
        unless (exists $vuln->{$field} && ref $vuln->{$field} eq 'HASH') {
            print "[ERROR] Missing or malformed field '$field' in $file\n";
            next;
        }
        foreach my $lang (@required_langs) {
            unless (exists $vuln->{$field}{$lang} && defined $vuln->{$field}{$lang} && $vuln->{$field}{$lang} ne '') {
                print "[ERROR] Missing translation: $field -> $lang in $file\n";
            }
        }
    }

    foreach my $field (qw(type category references)) {
        unless (exists $vuln->{$field}) {
            print "[ERROR] Missing required field '$field' in $file\n";
        }
    }

    if (exists $vuln->{references} && ref $vuln->{references} ne 'ARRAY') {
        print "[ERROR] Field 'references' must be a list in $file\n";
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
        validate_yaml($file);
    }
}

main();

