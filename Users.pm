package Users;
use 5.010000;
use strict;
use warnings;
our $VERSION = '0.01';
use Object::Tiny qw/dbname/;
use SQLite::DB;

# Preloaded methods go here.

# constructor    
sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    initialize_database($self);
    return $self;
}

1;

sub initialize_database {
    my $self = shift;
    $self->{db} = SQLite::DB->new(resolve_dbname($self->{dbname}));
    $self->{db}->connect;
    create_tables($self);
}

sub resolve_dbname {
    my $datadir = $main::datadir;
    my $dbname = shift;
    die "No writeable data store" if (! (-d $datadir && -w $datadir));
    die "No database name given" if (! (defined $dbname && $dbname ne ''));
    return $datadir.'/'.$dbname;
}

sub create_tables {
    my $self = shift;
    my $db = $self->{db};
    $db->exec('create table if not exists chatnets (
id integer not null primary key autoincrement,
name text,
)');
    $db->exec('create table if not exists channels (
id integer not null primary key autoincrement,
name text,
chatnetchannel integer not null,
foreign key(chatnetchannel) references chatnets(id),
)');
    $db->exec('create table if not exists users (
id integer not null primary key autoincrement,
handle text,
role integer not null default 0,
birthdate date,
pronouns text,
drinker text,
smoker text,
postalcode text,
email text,
latitude text,
longitude text,
chatnetuser integer not null,
foreign key(chatnetuser) references chatnets(id),
)');
    $db->exec('create table if not exists idents (
id integer not null primary key autoincrement,
userhost text,
userident integer not null,
foreign key(userident) references users(id),
)');
    $db->exec('create table if not exists altnicks (
id integer not null primary key autoincrement,
nick text,
useraltnick integer,
foreign key(useraltnick) references users(id),
)');
};



__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Users - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Users;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Users, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Tamara Temple, E<lt>tamara@localE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Tamara Temple

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
