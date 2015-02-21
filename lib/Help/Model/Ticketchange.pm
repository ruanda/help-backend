package Help::Model::Ticketchange;

use strict;
use utf8;

use base qw/Help::Model::Base/;

sub table_name {'ticket_change'}

sub list {
    my ($class, $id, @email) = @_;

    my $db = Help::Model->db;
    my $t_ticket = $class->table_name;

    return unless (Help::Model::Ticket->show($id, @email));
    return $db->query(
        "select distinct
            tc.time, tc.author, tc.field, tc.oldvalue, tc.newvalue
            from
                ticket_change AS tc, ticket_change_custom AS tcc
            where
                tc.ticket = tcc.ticket
                and tc.time = tcc.time
                and ( tc.field = 'comment'
                    or tc.field = 'status'
                    or tc.field = 'resolution')
                and tcc.status = 0
                and tc.ticket = ?
            order by
                tc.time", $id)->hashes;
}

sub create {
    my ($class, $id, $email, $comment) = @_;

    my $db = Help::Model->db;

    my $timestamp = ($db->query("select strftime('%s','now')")->flat)[0];

    return unless (Help::Model::Ticket->show($id, $email));
    
    my $oldvalue = ($db->query("select oldvalue from ticket_change where ticket = ? and field = 'comment' order by time desc limit 1", $id)->flat)[0];
    $db->query("insert into ticket_change (ticket, time, author, field, oldvalue, newvalue) values(?, ?, ?, 'comment', ?, ?)", $id, $timestamp, $email, $oldvalue + 1, $comment);
    $db->query("insert into ticket_change_custom (ticket, time, status, dont_notify) values (?, ?, 0, 0)", $id, $timestamp);
}

1;
