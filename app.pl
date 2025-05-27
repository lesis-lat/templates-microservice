#!/usr/bin/env perl

use 5.030;
use utf8;
use strict;
use warnings;
use YAML::XS;
use Mojolicious::Lite;
use Mojo::JSON qw(decode_json);

our $VERSION = '0.0.2';

plugin 'I18N' => { namespace => 'VulnTemplates' };

get q{/} => sub {
    my $self   = shift;
    my $lang   = $self -> param('lang') || 'en';
    my $id     = $self -> param('id');
    my $yaml   = YAML::XS::LoadFile('./templates/index.yml');
    my $files  = $yaml -> {"index"};
    my $result = [];

    while (my ($key, $value) = each %{$files}) {
        my $load  = YAML::XS::LoadFile("./templates/$value.yml");

        if ($load) {
            my $template = $load -> {"vulnerability"};

            my $item = {
                "id"             => $key,
                "name"           => $template -> {"name"} -> {$lang},
                "type"           => $template -> {"type"},
                "category"       => $template -> {"category"},
                "description"    => $template -> {"description"} -> {$lang},
                "recommendation" => $template -> {"recommendation"} -> {$lang},
                "references"     => $template -> {"references"}
            };

            push @{$result}, $item;
        }
    }

    @{$result} = sort { $a->{"id"} <=> $b->{"id"} } @{$result};

    if ($id) {
        for my $vuln (@{$result}) {
            if ($vuln -> {"id"} == $id) {
                $result = $vuln;

                return $self -> render(
                    status => 200,
                    json   => { "templates" => $result }
                );
            }
        }

        return $self -> render(
            status => 404,
            json   => { "error" => "Template not found" }
        );
    }

    return $self -> render(
        status => 200,
        json   => { "templates" => $result }
    );
};

app -> hook(
    after_render => sub {
        my ($self, $output, $format) = @_;

        $self -> res -> headers -> header('Content-Security-Policy' => q{default-src 'self'});
        $self -> res -> headers -> header('X-Content-Type-Options' => 'nosniff');
        $self -> res -> headers -> header('X-Frame-Options' => 'DENY');
        $self -> res -> headers -> header('Strict-Transport-Security' => 'max-age=31536000; includeSubDomains');
        $self -> res -> headers -> content_type('application/json');
    }
);

app -> hook(
    before_dispatch => sub {
        my $cors = shift;

        $cors -> res -> headers -> header('Access-Control-Allow-Origin' => q{*});
        $cors -> res -> headers -> header('Access-Control-Allow-Methods' => 'GET, OPTIONS');
        $cors -> res -> headers -> header('Access-Control-Allow-Headers' => 'Origin, Content-Type, Accept');
        $cors -> res -> headers -> header('Access-Control-Max-Age' => '86400');
    }
);

app -> start();