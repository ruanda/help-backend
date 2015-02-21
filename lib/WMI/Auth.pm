package WMI::Auth;

use feature ':5.10';

use strict;
use Carp;

use Authen::SASL;
use Encode;
use Net::DNS;
use Net::LDAP;

my $instance;

sub init {
    my $class = shift;
    my %args = @_;

    $instance = WMI::Auth->new(%args) unless($instance);
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

sub getLDAP {
    my $self = shift;
    my $ldap = Net::LDAP->new(
        $self->domain, cafile => $self->cafile, port => 636, scheme => 'ldaps',
        verify => 'require', onerror => undef)
    or return 0;
}

sub getFilter {
    my $self = shift;
    my ($user) = @_;

    my $filter = '(&'.$self->filter."(objectCategory=person)(sAMAccountName=$user))";

    return $filter;
}

sub getUserDN {
    my $self = shift;
    my ($user) = @_;
  
    my $filter = $self->getFilter($user);

    my $ldap = $self->getLDAP or return 0;
    $ldap->bind;

    my $search = $ldap->search(scope => 'sub', base => $self->basedn,
        filter => $filter, attrs => [ 'dn' ]);

    $ldap->disconnect;
    return 0 unless( $search->count );

    my ($entry) = $search->entries;
    return $entry->dn;

}

sub userMustChangePassword {
    my $self = shift;
    my ($user) = @_;

    my $filter = $self->getFilter($user);

    my $ldap = $self->getLDAP or return 0;
    $ldap->bind;

    my $search = $ldap->search(scope => 'sub', base => $self->basedn,
        filter => $filter, attrs => [ 'pwdLastSet' ]);

    $ldap->disconnect;
    return 0 unless( $search->count );

    my ($entry) = $search->entries;
    my $pwdLastSet = $entry->get_value('pwdLastSet');

    return ($pwdLastSet) ? 0 : 1;

}

sub auth {
    my $self = shift;
    my %args = @_;

    my $user = $args{'user'};
    my $pass = $args{'password'};

    my $user_dn = $self->getUserDN($user);
    return 0 unless (user => $user_dn);

    my $ldap = $self->getLDAP or return 0;
    my $mesg = $ldap->bind($user_dn, password => $pass);
    $ldap->disconnect;

    return not ($mesg->is_error or $@);
}

sub changePassword {
    my $self = shift;
    my %args = @_;

    my $user = $args{'user'};
    my $oldPass = $args{'oldPassword'};
    my $newPass = $args{'newPassword'};

    #my $charmap = Unicode::Map8->new('latin1') or return 0;

    #my $oldPassU = $charmap->tou('"'.$oldPass.'"')->byteswap()->utf16();
    #my $newPassU = $charmap->tou('"'.$newPass.'"')->byteswap()->utf16();
    my $oldPassU = encode('utf16le', '"'.decode('utf8', $oldPass).'"');
    my $newPassU = encode('utf16le', '"'.decode('utf8', $newPass).'"');

    my $user_dn = $self->getUserDN($user);
    return 0 unless (user => $user_dn);

    my $ldap = $self->getLDAP or return 0;
    my $mesg = $ldap->bind($user_dn, password => $oldPass);

    $mesg = $ldap->modify($user_dn,
        changes => [
            delete => [ unicodePwd => $oldPassU ],
            add    => [ unicodePwd => $newPassU ] ]);

    $ldap->unbind();
    return not ($mesg->is_error or $@);
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
