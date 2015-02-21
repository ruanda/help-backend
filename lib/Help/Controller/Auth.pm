package Help::Controller::Auth;

use utf8;
use strict;

use base 'Mojolicious::Controller';

use WMI::Auth;

sub get {
    my $self = shift;
    
    if ($self->check) {
        $self->render(json => { user => $self->session('user') });
    } else {
        $self->session(expires => 1);
        $self->rendered(401);
    }
}

sub create {
    my $self = shift;

    my $content_type = $self->req->headers->content_type;
    if ($content_type !~ q|^application/json(?:;\S+)?$| ) {
        $self->rendered(415);
        return;
    }

    my $req = $self->req->json;
    unless (defined $req) {
        $self->rendered(400);
        return;
    }

    my $user = $req->{user};
    my $pass = $req->{password};

    my $authResult = WMI::Auth->instance->auth(
        user => $user,
        password => $pass);

    if ($authResult) {
        $self->session(user => $user);
        $self->rendered(200);
    } else {
        $self->session(expires => 1);
        $self->rendered(401);
    }
}

sub delete {
    my $self = shift;
    if ($self->check) {
        $self->session(expires => 1);
        $self->rendered(200);
    } else {
        $self->rendered(400);
    }
}

sub check {
    shift->session('user') ? 1 : 0;
}

1;
