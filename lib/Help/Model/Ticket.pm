package Help::Model::Ticket;

use strict;
use utf8;

use base qw/Help::Model::Base/;

sub table_name {'ticket'}

sub list {
    my ($class, @email) = @_;

    my $db = Help::Model->db;
    my $t_ticket = $class->table_name;

    return $db->select(
        $t_ticket,
        ['id', 'time', 'changetime', 'status', 'resolution', 'summary' ],
        { reporter => [@email],
          id => \"IN (select ticket_custom.ticket from ticket_custom where name =
      'administrative' and value = 0)"},
        'id')->hashes;
}

sub show {
    my ($class, $id, @email) = @_;

    my $db = Help::Model->db;
    my $t_ticket = $class->table_name;

    return $db->select(
        $t_ticket,
        ['id', 'type', 'time', 'component', 'severity', 'priority',
            'changetime', 'status', 'resolution', 'summary', 'description',
            'keywords' ],
        { reporter => [@email],
          id => $id })->hash;
}

sub create {
    my ($class, $email, $summary, $description, $keywords) = @_;

    my $db = Help::Model->db;
    my $t_ticket = $class->table_name;

    $db->query("
        insert into ticket
            (type, time, changetime, component, priority, owner, reporter, status,
                summary, description, keywords)
            values
                ('defect', strftime('%s','now'), strftime('%s','now'), 'Special - Helpdesk', 'major', 'somebody', ?, 'new', ?, ?, ?)",
        "$email", "$summary", "$description", "$keywords");

    my $id = ($db->query('select last_insert_rowid()')->flat)[0];

    $db->query("insert into ticket_custom (ticket, name, value) values (?, 'administrative', 0)", $id);
    $db->query("insert into ticket_custom (ticket, name, value) values (?, 'team', 'Any')", $id);

    return $id;

}

1;
