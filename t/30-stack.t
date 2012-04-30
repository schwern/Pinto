#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;

#------------------------------------------------------------------------------

{
  # Create a new stack...
  my ($stk_name, $stk_desc) = ('dev', 'the development stack');
  $t->run_ok('Stack::Create', {stack => $stk_name, description => $stk_desc});
  my $stack = $t->pinto->repos->get_stack(name => $stk_name);
  is $stack->name, $stk_name, 'Got correct stack name';
  is $stack->get_property('pinto:description'), $stk_desc, 'Got correct stack description';
  my $old_mtime = $stack->last_modified_on;

  sleep 2; # So the mtime changes.

  # Add to the stack...
  my $foo_and_bar_1 = make_dist_archive('FooAndBar-1=Foo-1,Bar-1');
  $t->run_ok('Add', {author => 'ME', stack => $stk_name, archives => $foo_and_bar_1});
  $t->registration_ok( 'ME/FooAndBar-1/Foo-1/dev/-' );
  $t->registration_ok( 'ME/FooAndBar-1/Bar-1/dev/-' );

  # Should not be on the default stack...
  $t->registration_not_ok( 'ME/FooAndBar-1/Foo-1/default/-' );
  $t->registration_not_ok( 'ME/FooAndBar-1/Bar-1/default/-' );

  # Check that mtime was updated...
  $stack->discard_changes; # Causes it to reload from DB
  cmp_ok $stack->last_modified_on, '>', $old_mtime, 'Updated stack mtime';
}

#------------------------------------------------------------------------------

{
  # Copy dev -> qa...
  my $dev_stk_name = 'dev';
  my ($qa_stk_name, $qa_stk_desc) = ('qa', 'the qa stack');
  $t->run_ok('Stack::Copy', {from_stack  => $dev_stk_name,
                             to_stack    => $qa_stk_name,});

  my $dev_stack = $t->pinto->repos->get_stack(name => $dev_stk_name);
  my $qa_stack = $t->pinto->repos->get_stack(name => $qa_stk_name);

  is $qa_stack->name, $qa_stk_name,
    'Got correct stack name';
  is $qa_stack->last_modified_on, $dev_stack->last_modified_on,
    'Copied stack has same mtime as original';

  is $qa_stack->get_property('pinto:description'), 'copy of stack dev',
    'Copied stack has default description';
}

#------------------------------------------------------------------------------

{
  # Copy from a stack that doesn't exist
  $t->run_throws_ok('Stack::Copy', {from_stack => 'nowhere',
                                    to_stack   => 'somewhere'},
                                    qr/Stack nowhere does not exist/);


  # Copy to a stack that already exists
  $t->run_throws_ok('Stack::Copy', {from_stack => 'default',
                                    to_stack   => 'dev'},
                                    qr/Stack dev already exists/);

}


#------------------------------------------------------------------------------

done_testing;

