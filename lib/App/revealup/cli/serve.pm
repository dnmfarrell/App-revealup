package App::revealup::cli::serve;
use strict;
use warnings;
use Getopt::Long qw/GetOptionsFromArray/;
use File::ShareDir qw/dist_dir/;
use Path::Tiny qw/path/;
use Text::MicroTemplate qw/render_mt/;
use Plack::Runner;

my $_plack_port = 5000;
my $_dry_run = 0;

sub run {
    my ($self, @args) = @_;
    GetOptionsFromArray( \@args, 'p|port=s' => \$_plack_port, 'dry-run' => \$_dry_run );
    my $filename = shift @args;
    die "Markdown filename is required in args." unless $filename;

    my $html = $self->render($filename);
    my $app = $self->app($html);
    my $runner = Plack::Runner->new();
    $runner->parse_options("--port=$_plack_port");
    $runner->run($app) if !$_dry_run;
}

sub render {
    my ($self, $filename) = @_;
    my $template_dir = $self->share_dir([qw/share templates/]);
    my $revealjs_dir = $self->share_dir([qw/share revealjs/]);
    my $template = $template_dir->child('slide.html.mt');
    my $content = $template->slurp_utf8();
    my $html = render_mt($content, $revealjs_dir->relative(), $filename)->as_string();
    return $html;
}

sub app {
    my ($self, $html) = @_;
    return sub {
        my $env = shift;
        if ($env->{PATH_INFO} eq '/') {
            return [
                200,
                ['Content-Type' => 'text/html', 'Content-Length' => length $html],
                [$html ]
            ];
        }else{
            my $path = path('.', $env->{PATH_INFO});
            if( $path->exists ) {
                my $c = $path->slurp();
                return [200, [ 'Content-Length' => length $c ], [$c]];
            }else{
                return [404, [], ['not found.']];
            }
        }
    };
}

sub share_dir {
    my ($self, $p) = @_;
    die "Parameter must be ARRAY ref" unless ref $p eq 'ARRAY';
    my $path = path(@$p);
    return $path if $path->exists();
    shift @$p;
    my $dist_dir = dist_dir('App-revealup');
    $path = path($dist_dir, $p);
    return path;
}

1;
