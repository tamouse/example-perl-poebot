#!/sw/bin/perl -w
#
# poebot
#
# Author: Tamara Temple <tamara@tamaratemple.com>
# Created: 2012-03-17
# Copyright (c) 2012 
# License: GPLv3
#


# This is a simple IRC bot that just rot13 encrypts public messages.
# It responds to "rot13 <text to encrypt>".
use warnings;
use strict;
use vars qw($VERSION);
$VERSION = '0.1';

use POE;
use POE::Component::IRC;
sub CHANNEL () { "#roof" }

our $trigger_char = '@';
our $botnick = 'poebot' . $$ % 1000;

# Create the component that will represent an IRC network.
my ($irc) = POE::Component::IRC->spawn();

# Create the bot session.  The new() call specifies the events the bot
# knows about and the functions that will handle those events.
POE::Session->create(
  inline_states => {
    _start     => \&bot_start,
    irc_001    => \&on_connect,
    irc_public => \&on_public,
  },
);

# The bot session has started.  Register this bot with the "magnet"
# IRC component.  Select a nickname.  Connect to a server.
sub bot_start {
  $irc->yield(register => "all");
  $irc->yield(
    connect => {
      Nick     => $botnick,
      Username => 'cookbot',
      Ircname  => 'POE::Component::IRC cookbook bot',
      Server   => 'irc.funkykitty.net',
      Port     => '6667',
    }
  );
}

# The bot has successfully connected to a server.  Join a channel.
sub on_connect {
  $irc->yield(join => CHANNEL);
}

# The bot has received a public message.  Parse it for commands, and
# respond to interesting things.
sub on_public {
  my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  my $channel = $where->[0];
  my $ts      = scalar localtime;
  print " [$ts] <$nick:$channel> $msg\n";
  if (my ($rot13) = $msg =~ /^rot13 (.+)/) {
    $rot13 =~ tr[a-zA-Z][n-za-mN-ZA-M];

    # Send a response back to the server.
    $irc->yield(privmsg => CHANNEL, $rot13);
  }
  if (my ($bot_command) = $msg =~ /^$trigger_char(\S+)\s*(\S*)\s*(.*)/) {
      my $marker = $1;
      my $cmd = $2;
      my $data = $3;
      print "\t\$marker=$marker";
      print "\t\$cmd=$cmd";
      print "\t\$data=$data";
      print "\n";
      return if ($botnick !~ /$marker/i);
      exit 0 if ($cmd =~ /quit/i);
      $irc->yield(notice => $nick, "I heard you want me to do $cmd on $data");
  }
}

# Run the bot until it is done.
$poe_kernel->run();
exit 0;
