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
    my ($file_path) = @_;
    if ( $file_path =~ m{/index\.ya?ml$}msx ) {
        return;
    }

    my $yaml_data;
    my $load_successful = eval { $yaml_data = LoadFile($file_path); 1 };
    if ( !$load_successful ) {
        return;
    }
    if ( !( ref $yaml_data eq 'HASH' ) ) {
        return;
    }
    if ( !( exists $yaml_data -> {vulnerability} && ref $yaml_data -> {vulnerability} eq 'HASH' ) ) {
        return;
    }

    my $vulnerability_data = $yaml_data -> {vulnerability};

    if ( defined $vulnerability_data -> {category} && $vulnerability_data -> {category} ne q{} ) {
        $categories{ $vulnerability_data -> {category} }++;
    }

    if ( defined $vulnerability_data -> {type} && $vulnerability_data -> {type} ne q{} ) {
        $types{ $vulnerability_data -> {type} }++;
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

    foreach my $file (@yaml_files) {
        extract_fields($file);
    }

    print "Unique categories:\n";
    foreach my $category ( sort keys %categories ) {
        print "- $category ($categories{$category})\n";
    }

    print "\nUnique types:\n";
    foreach my $type ( sort keys %types ) {
        print "- $type ($types{$type})\n";
    }
    return;
}

main();
