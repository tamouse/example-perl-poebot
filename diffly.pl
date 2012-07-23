#!/usr/bin/perl

# A Multiple Network Rot13 'encryption' bot

use strict;
use warnings;
use POE qw(Component::IRC);
use Data::Dumper::Names;
use Getopt::Flex;
use Config::Tiny;


# ###################
# COMMANDLINE OPTIONS
# ###################

my $configfile;             # name of alternate configuration file
my $debug;                  # turn on debugging

process_options();

# #############
# CONFIGURATION
# #############


my $nickname;                # nickname used for bot
my $ircname;                 # realname used for bot
my %settings;                # server settings
my $datadir;                 # directory to hold data for bot
configure_bot();




# We create our PoCo-IRC objects
for my $server ( keys %settings ) {
    POE::Component::IRC->spawn(
        alias   => $server,
        nick    => $nickname,
        ircname => $ircname,
    );
}

POE::Session->create(
    package_states => [
        main => [ qw(_default _start irc_registered irc_001 irc_public) ],
    ],
    heap => { config => \%settings },
);

$poe_kernel->run();

sub _start {
    my ($kernel, $session) = @_[KERNEL, SESSION];

    # Send a POCOIRC_REGISTER signal to all poco-ircs
    $kernel->signal( $kernel, 'POCOIRC_REGISTER', $session->ID(), 'all' );

    return;
}

# We'll get one of these from each PoCo-IRC that we spawned above.
sub irc_registered {
    my ($kernel, $heap, $sender, $irc_object) = @_[KERNEL, HEAP, SENDER, ARG0];

    my $alias = $irc_object->session_alias();

    my %conn_hash = (
        server => $alias,
        port   => $heap->{config}->{ $alias }->{port},
    );

    # In any irc_* events SENDER will be the PoCo-IRC session
    $kernel->post( $sender, 'connect', \%conn_hash );

    return;
}

sub irc_001 {
    my ($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];

    # Get the component's object at any time by accessing
    # the heap of the SENDER
    my $poco_object = $sender->get_heap();
    print "Connected to ", $poco_object->server_name(), "\n";

    my $alias = $poco_object->session_alias();
    my @channels = @{ $heap->{config}->{ $alias }->{channels} };

    $kernel->post( $sender => join => $_ ) for @channels;

    return;
}

sub irc_public {
    my ($kernel, $sender, $who, $where, $what) = @_[KERNEL, SENDER, ARG0 .. ARG2];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];

#    print '$kernel: ',Dumper($kernel) if $debug;
#    print '$sender: ',Dumper($sender) if $debug;
    print ref($sender) . "\n" if $debug;

    print '$who: ',Dumper($who) if $debug;
    print '$where: ',Dumper($where) if $debug;
    print '$what: ',Dumper($what) if $debug;


    if ( my ($rot13) = $what =~ /^rot13 (.+)/ ) {
        $rot13 =~ tr[a-zA-Z][n-za-mN-ZA-M];
        $kernel->post( $sender => privmsg => $channel => "$nick: $rot13" );
    }

    if ( $what =~ /^!bot_quit$/ ) {
        # Someone has told us to die =[
        $kernel->signal( $kernel, 'POCOIRC_SHUTDOWN', "See you loosers" );
    }

    return;
}

# We registered for all events, this will produce some debug info.
sub _default {
    my ($event, $args) = @_[ARG0 .. $#_];
    my @output = ( "$event: " );

    for my $arg ( @$args ) {
        if ( ref($arg) eq 'ARRAY' ) {
            push( @output, '[' . join(' ,', @$arg ) . ']' );
        }
        else {
            push ( @output, "'$arg'" );
        }
    }
    print join ' ', @output, "\n";

    return 0;
}

sub process_options {

    my $optcfg = {
	'non_option_mode' => 'STOP',
	'bundling' => 0,
	'long_option_mode' => 'REQUIRE_DOUBLE_DASH',
	'usage' => "$0 [-c|--config <configfile>] [-d|--debug]",
	'desc' => 'Launch diffley bot',
	'auto_help' => 1,
    };

    my $optspec = {
	'config|c' => {
	    'var' => \$configfile,
	    'type' => 'Str',
	    'desc' => 'Configuration file for diffley bot. Default is $HOME/.diffley',
	    'required' => 0,
	    'default' => $ENV{'HOME'}.'/.diffley',
	    'validator' => sub { -e $_[0] },
	},
	'debug|d' => {
	    'var' => \$debug,
	    'type' => 'Bool',
	    'desc' => 'Turn debugging on',
	    'required' => 0,
	    'default' => 0,
	},
    };

    my $op = Getopt::Flex->new({spec => $optspec, config => $optcfg});
    if (!$op->getopts()) {
	print STDERR $op->get_error();
	print STDERR $op->get_help();
	exit 1;
    }

    
}

sub configure_bot {
    my $Config = Config::Tiny->read($configfile);
    my @channels;
    my $port;
    my $server;
    %settings = (); # reset global settings array
    foreach my $section (keys %$Config) {
	if ($section eq '_') {
	    $nickname = $Config->{_}->{nickname};
	    $ircname = $Config->{_}->{realname};
	    $datadir = expand_filename($Config->{_}->{datadir};
	} else {
	    @channels = split(/,\s*/,$Config->{$section}->{channels});
	    $port = $Config->{$section}->{port};
	    $server = $Config->{$section}->{server};
	    $settings{$server} = { port => $port, channels => [@channels] };
	}
    }
    print '%settings: ',Dumper(\%settings) if $debug;
}
