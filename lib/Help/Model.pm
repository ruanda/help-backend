package Help::Model;

use strict;
use utf8;
use Carp;

use DBIx::Simple;
use SQL::Abstract;

use Mojo::Loader;

my $DB;

my $modules = Mojo::Loader->search('Help::Model');
for my $module (@$modules) {
    Mojo::Loader->load($module);
}

sub init {
    my ($class, $config) = @_;

    croak "No dsn was passed!" unless $config && $config->{dsn};

    unless($DB) {
        $DB = DBIx::Simple->connect(@$config{qw/dsn user password/},
            { RaiseError => 1,
              sqlite_unicode => 1,
            }) or die DBIx::Simple->error;
        $DB->abstract = SQL::Abstract->new();
    }
}

sub db {
  return $DB if $DB;
  croak "You should init model first!";
}

1;
