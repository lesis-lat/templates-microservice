our $VERSION = '0.01';

use strict;
use warnings;
use YAML::XS qw(LoadFile);
use File::Find;
use utf8;
use English qw(-no_match_vars);

binmode(STDOUT, ":encoding(UTF-8)");

sub validate_yaml {
    my ($file_path) = @_;
    if ( $file_path =~ m{/index\.ya?ml$}msx ) {
        return;
    }

    my $yaml_data;
    my $load_successful = eval { $yaml_data = LoadFile($file_path); 1 };
    if ( !$load_successful ) {
        print "[ERROR] Failed to load YAML: $file_path\n$EVAL_ERROR\n";
        return;
    }
    if ( ref $yaml_data ne 'HASH' ) {
        return;
    }
    if ( !( exists $yaml_data -> {vulnerability} && ref $yaml_data -> {vulnerability} eq 'HASH' ) ) {
        return;
    }

    my $vulnerability_data = $yaml_data -> {vulnerability};

    my %required_langs = map { $_ => 1 } qw(pt-br en es);
    my %text_fields    = map { $_ => 1 } qw(name description recommendation);

    for my $field (keys %text_fields) {
        if ( !( exists $vulnerability_data -> {$field} && ref $vulnerability_data -> {$field} eq 'HASH' ) ) {
            print "[ERROR] Missing or malformed field '$field' in $file_path\n";
            next;
        }
        for my $lang (keys %required_langs) {
            if ( !( exists $vulnerability_data -> {$field}{$lang} && defined $vulnerability_data -> {$field}{$lang} && $vulnerability_data -> {$field}{$lang} ne q{} ) ) {
                print "[ERROR] Missing translation: $field -> $lang in $file_path\n";
            }
        }
    }

    my %required_fields = map { $_ => 1 } qw(type category references);
    for my $field (keys %required_fields) {
        if ( !exists $vulnerability_data -> {$field} ) {
            print "[ERROR] Missing required field '$field' in $file_path\n";
        }
    }

    if ( exists $vulnerability_data -> {references} ) {
        if ( ref $vulnerability_data -> {references} ne 'ARRAY' ) {
            print "[ERROR] Field 'references' must be a list in $file_path\n";
        }
    }
    return;
}

sub find_yaml_files {
    my ($directory) = @_;
    my @files;
    find(
        sub {
            if ( -f && /\.ya?ml$/msx ) {
                push @files, $File::Find::name;
            }
        },
        $directory
    );
    return @files;
}

sub main {
    my $directory = shift @ARGV;
    if ( !defined $directory ) {
        die "Usage: $PROGRAM_NAME <directory>\n";
    }
    my @yaml_files = find_yaml_files($directory);
    for my $file (@yaml_files) {
        validate_yaml($file);
    }
    return;
}

main();
