package Help::Controller::Ticket;

use utf8;
use strict;

use base 'Mojolicious::Controller';

use POSIX qw/strftime/;
use WMI::User;

sub index {
    my $self = shift;

    my @email = ( $self->session('user').'@wmi.amu.edu.pl' );

    my %user = WMI::User->instance->info(user => $self->session('user'));
    if (%user) {
        push(@email, $user{'mail'});
    }

    my @tickets = Help::Model::Ticket->list(@email);

    for my $ticket (@tickets) {
        $ticket->{createdAt} = strftime("%F %H:%M:%S", gmtime($ticket->{time}));
        $ticket->{modifiedAt} = strftime("%F %H:%M:%S", gmtime($ticket->{changetime}));
        delete $ticket->{time};
        delete $ticket->{changetime};
    }

    $self->render(json => [@tickets]); 
}

sub show {
    my $self = shift;

    my $id = $self->param('id');

    my @email = ( $self->session('user').'@wmi.amu.edu.pl' );

    my %user = WMI::User->instance->info(user => $self->session('user'));
    if (%user) {
        push(@email, $user{'mail'});
    }

    my $ticket = Help::Model::Ticket->show($id, @email);

    if ($ticket) {
        $ticket->{createdAt} = strftime("%F %H:%M:%S", gmtime($ticket->{time}));
        $ticket->{modifiedAt} = strftime("%F %H:%M:%S", gmtime($ticket->{changetime}));
        delete $ticket->{time};
        delete $ticket->{changetime};
        $self->render(json => $ticket);
    } else {
        $self->rendered(404);
    }
}

sub create {
    my $self = shift;

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

    my $summary = $req->{summary};
    my $description = $req->{description};
    my $keywords = $req->{keywords};

    my $id = Help::Model::Ticket->create($email[0], $summary, $description, $keywords);

    $self->render(json => { id => $id});

}

1;
