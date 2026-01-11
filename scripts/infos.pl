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

    my $yaml_data;
    my $load_ok = eval { $yaml_data = LoadFile($file); 1 };
    if ( !$load_ok ) {
        return;
    }
    if ( !( ref $yaml_data eq 'HASH' ) ) {
        return;
    }
    if ( !( exists $yaml_data -> {vulnerability} && ref $yaml_data -> {vulnerability} eq 'HASH' ) ) {
        return;
    }

    my $vulnerability = $yaml_data -> {vulnerability};

    if ( defined $vulnerability -> {category} && $vulnerability -> {category} ne q{} ) {
        $categories{ $vulnerability -> {category} }++;
    }

    if ( defined $vulnerability -> {type} && $vulnerability -> {type} ne q{} ) {
        $types{ $vulnerability -> {type} }++;
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
    my $directory = shift @ARGV or die "Usage: $PROGRAM_NAME <directory>\n";
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
