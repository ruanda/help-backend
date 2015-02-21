package WMI::User;

use strict;
use utf8;
use Carp;

use Encode qw{ decode };
use Date::Parse;

use Authen::SASL;
use Net::DNS;
use Net::LDAP;

my $instance;

sub init {
  my $class = shift;
  my %args = @_;

  $instance = WMI::User->new(%args) unless($instance);
}

sub instance {
  return $instance if $instance;
  croak "You should init WMI::Auth first!";
}

sub new {
  my $class = shift;
  my %args = @_;
  my $self = {};
  bless($self, $class);

  $self->{'domain'} = $args{'domain'};
  $self->{'basedn'} = $args{'basedn'};
  $self->{'cafile'} = $args{'cafile'};
  $self->{'filter'} = $args{'filter'};

  return $self;
}

sub info {
  my $self = shift;
  my %args = @_;

  my $user = $args{'user'};
  my $log = $args{'log'};

  my $filter = '(&'.$self->filter."(objectCategory=person)(sAMAccountName=$user))";

  my $ldap = Net::LDAP->new(
      $self->domain, cafile => $self->cafile, port => 636, scheme => 'ldaps',
      verify => 'require', raw => qr/(?i:^jpegPhoto|;binary)/, onerror => undef)
    or return 0;
  $ldap->bind;
  my $search = $ldap->search(
    scope => 'sub',
    base => $self->basedn,
    filter => $filter,
    attrs => [ 'dn', 'sn', 'displayName', 'mail', 'accountExpires', 'pwdLastSet' ]
  );
  $ldap->disconnect;
  return undef unless( $search->count );

  my ($entry) = $search->entries;
  
  my $exp = $self->normalize_time($entry->get_value('accountExpires'));
  my $pwdLastSet = $self->normalize_time($entry->get_value('pwdLastSet'));

  $exp = 0 if ($exp < 0);
  $pwdLastSet = 0 if ($pwdLastSet < 0);

  return (
    dn => $entry->dn,
    displayName =>  $entry->get_value('displayName'),
    mail => $entry->get_value('mail'),
    accountExpires => $exp,
    pwdLastSet => $pwdLastSet
  );
}

sub normalize_time {
  my $self = shift;
  my $time = shift;
  return int($time / 10000000 - 11644473600);
}

sub domain {
  return shift->{'domain'};
}

sub basedn {
  return shift->{'basedn'};
}

sub cafile {
  return shift->{'cafile'};
}

sub filter {
  return shift->{'filter'};
}

1;
