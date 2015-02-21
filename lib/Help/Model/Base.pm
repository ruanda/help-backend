package Help::Model::Base;

use strict;
use utf8;

use base qw/Mojo::Base/;

sub select {
  my $class = shift;
  my $db = Help::Model->db;
  $db->select($class->table_name, '*', @_);
}

sub insert {
  my $class = shift;
  my $db = Help::Model->db;
  $db->insert($class->table_name, @_) or die $db->error();
  $db->last_insert_id('','',$class->table_name,'id')    or die $db->error();
}

sub update {
  my $class = shift;
  my $db = Help::Model->db;
  $db->update($class->table_name, @_) or die $db->error();
}

sub delete {
  my $class = shift;
  my $db = Help::Model->db;
  $db->delete($class->table_name, @_) or die $db->error();
}

1;
