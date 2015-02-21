package Help;
use Mojo::Base 'Mojolicious';

use strict;

use WMI::Auth;
use WMI::User;
use Help::Model;

# This method will run once at server start
sub startup {
    my $self = shift;

    my $config = $self->plugin('JSONConfig' => { file => 'conf/help.json' });

    $self->secret($config->{app}->{secret});
    $self->mode($config->{app}->{mode});
    $self->sessions->default_expiration(3600*24*7);

    $self->helper(is_logged => sub {
        shift->session('user') ? 1 : 0;
    });

    $self->helper(auth_fail => sub {
        my $self = shift;
        $self->rendered(401);
        return 0;
    });

    # Router
    my $r = $self->routes;
    $r->namespace('Help::Controller');

    my $api = $r->any('/api');
    $api->get('/auth')->to('auth#get');
    $api->post('/auth')->to('auth#create');
    $api->delete('/auth')->to('auth#delete');

    my $apil = $api->under( sub {
        my $self = shift;
        return $self->auth_fail unless $self->is_logged;
        return 1;
    });

    $apil->get('/tickets')->to('ticket#index');
    $apil->post('/tickets')->to('ticket#create');
    $apil->get('/tickets/:id' => [id => qr/\d+/])->to('ticket#show');

    $apil->get('/tickets/:id/changes' => [id => qr/\d+/])->to('ticketchange#index');
    $apil->post('/tickets/:id/changes' => [id => qr/\d+/])->to('ticketchange#create');

    WMI::Auth->init(domain => $config->{ldap}->{domain},
                    basedn => $config->{ldap}->{basedn},
                    ssl => $config->{ldap}->{ssl},
                    cafile => $config->{ldap}->{cafile});
    WMI::User->init(domain => $config->{ldap}->{domain},
                    basedn => $config->{ldap}->{basedn},
                    ssl => $config->{ldap}->{ssl},
                    cafile => $config->{ldap}->{cafile});
    Help::Model->init($config->{db});

}

1;
