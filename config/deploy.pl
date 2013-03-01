use strict;
use warnings;

use Cinnamon::DSL;
use Config::Pit;

my $application = 'Example-MyApp';
my $hostname    = 'localhost';
my $conf_name   = sprintf( '%s@%s', $hostname, $application );

my $conf = Config::Pit::get(
    $conf_name,
    require => {
        user => sprintf('user@%s', $hostname),
    }
);

set user       => $conf->{user};
set repository => 'https://github.com/hayajo/example-myapp.git';
set script     => 'script/example_myapp';

role development => [$hostname], {
    deploy_to  => "/home/apps/${application}-devel",
    branch     => 'master',
};

task deploy => {
    setup => sub {
        my ( $host, @args ) = @_;
        my $repository = get('repository');
        my $deploy_to  = get('deploy_to');
        my $branch     = 'origin/' . get('branch');
        remote {
            run "git clone $repository $deploy_to && cd $deploy_to && git checkout -q $branch";
        } $host;
    },
    update => sub {
        my ( $host, @args ) = @_;
        my $deploy_to  = get('deploy_to');
        my $branch     = 'origin/' . get('branch');
        remote {
            run "cd $deploy_to && git fetch origin && git checkout -q $branch && git submodule update --init";
        } $host;
    },
};

task carton => {
    install => sub {
        my ( $host, @args ) = @_;
        my $deploy_to  = get('deploy_to');
        remote {
            run "source ~/perl5/perlbrew/etc/bashrc && cd $deploy_to && carton install";
        } $host;
    },
};

task server => {
    start => sub {
        my ( $host, @args ) = @_;
        my $deploy_to = get('deploy_to');
        my $script    = get('script');
        remote {
            run "source ~/perl5/perlbrew/etc/bashrc && cd $deploy_to && carton exec -Ilib -- hypnotoad $script";
        } $host;
    },
    stop => sub {
        my ( $host, @args ) = @_;
        my $deploy_to = get('deploy_to');
        my $script    = get('script');
        remote {
            run "source ~/perl5/perlbrew/etc/bashrc && cd $deploy_to && carton exec -Ilib -- hypnotoad -s $script"
        } $host;
    },
    restart => sub {
        my ( $host, @args ) = @_;
        my $deploy_to = get('deploy_to');
        my $script    = get('script');
        my (undef, $script_dir) = File::Spec->splitpath($script);
        my $pid_file = File::Spec->catfile($script_dir, 'hypnotoad.pid');
        remote {
            run "cd $deploy_to && kill -USR2 `cat $pid_file`";
        } $host;
    },
};
