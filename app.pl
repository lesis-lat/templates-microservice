use 5.030;
use utf8;
use strict;
use warnings;
use YAML::XS;
use Mojolicious::Lite;

our $VERSION = '0.0.2';

plugin 'I18N' => { namespace => 'VulnTemplates' };

get q{/} => sub {
    my $controller = shift;
    my $language = $controller -> param('lang') || 'en';
    my $requested_template_id = $controller -> param('id');
    my $index_data = YAML::XS::LoadFile('./templates/index.yml');
    my $template_index = $index_data -> {"index"};
    my $templates = [];

    while (my ($template_id, $template_file) = each %{$template_index}) {
        my $template_data = YAML::XS::LoadFile("./templates/$template_file.yml");

        if ($template_data) {
            my $template = $template_data -> {"vulnerability"};

            my $template_entry = {
                "id"             => $template_id,
                "name"           => $template -> {"name"} -> {$language},
                "type"           => $template -> {"type"},
                "category"       => $template -> {"category"},
                "description"    => $template -> {"description"} -> {$language},
                "recommendation" => $template -> {"recommendation"} -> {$language},
                "references"     => $template -> {"references"}
            };

            push @{$templates}, $template_entry;
        }
    }

    @{$templates} = sort { $a -> {"id"} <=> $b -> {"id"} } @{$templates};

    if ($requested_template_id) {
        for my $template_entry (@{$templates}) {
            if ($template_entry -> {"id"} == $requested_template_id) {
                $templates = $template_entry;

                return $controller -> render(
                    status => 200,
                    json   => { "templates" => $templates }
                );
            }
        }

        return $controller -> render(
            status => 404,
            json   => { "error" => "Template not found" }
        );
    }

    return $controller -> render(
        status => 200,
        json   => { "templates" => $templates }
    );
};

app -> hook(
    after_render => sub {
        my ($controller) = @_;

        $controller -> res -> headers -> header('Content-Security-Policy' => q{default-src 'self'});
        $controller -> res -> headers -> header('X-Content-Type-Options' => 'nosniff');
        $controller -> res -> headers -> header('X-Frame-Options' => 'DENY');
        $controller -> res -> headers -> header('Strict-Transport-Security' => 'max-age=31536000; includeSubDomains');
        $controller -> res -> headers -> content_type('application/json');
    }
);

app -> hook(
    before_dispatch => sub {
        my $controller = shift;

        $controller -> res -> headers -> header('Access-Control-Allow-Origin' => q{*});
        $controller -> res -> headers -> header('Access-Control-Allow-Methods' => 'GET, OPTIONS');
        $controller -> res -> headers -> header('Access-Control-Allow-Headers' => 'Origin, Content-Type, Accept');
        $controller -> res -> headers -> header('Access-Control-Max-Age' => '86400');
    }
);

app -> start();
