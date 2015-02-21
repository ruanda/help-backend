package Help::Controller::Ticketchange;

use utf8;
use strict;

use base 'Mojolicious::Controller';

use POSIX qw/strftime/;
use WMI::User;

sub index {
    my $self = shift;

    my $id = $self->param('id');

    my @email = ( $self->session('user').'@wmi.amu.edu.pl' );

    my %user = WMI::User->instance->info(user => $self->session('user'));
    if (%user) {
        push(@email, $user{'mail'});
    }

    my @dbchanges = Help::Model::Ticketchange->list($id, @email);
    unless (@dbchanges) {
        $self->rendered(404);
        return;
    }

    my @changes;

    my $time;
    for my $change (@dbchanges) {
        if ($change->{time} ne $time) {
            $time = $change->{time};
            push(@changes,
                { createdAt => strftime("%F %H:%M:%S", gmtime($time)),
                  author => $change->{author} });
        }
        $changes[$#changes]{$change->{field}} = {
            oldvalue => $change->{oldvalue},
            newvalue => $change->{newvalue}
        };
    }

    $self->render(json => [@changes]);
}

sub create {
    my $self = shift;

    my $id = $self->param('id');

    my $content_type = $self->req->headers->content_type;
    if ($content_type !~ q|^application/json(?:;\S+)?$| ) {
        $self->rendered(415);
        return;
    }

    my @email = ( $self->session('user').'@wmi.amu.edu.pl' );

    my %user = WMI::User->instance->info(user => $self->session('user'));
    if (%user) {
        unshift(@email, $user{'mail'});
    }

    my $req = $self->req->json;
    unless (defined $req) {
        $self->rendered(400);
        return;
    }

    my $comment = $req->{comment};

    Help::Model::Ticketchange->create($id, $email[0], $comment);

    $self->rendered;

}

1;
