# [FlowState] in-terminal tool to create Flow Charts and State Diagrams
# Work in Progress

use strict;
use warnings;

use Graph::Easy;
use Term::ReadKey;

open(TTY, "</dev/tty");

my $g = Graph::Easy->new();

my $active;
my $newActive;
my $nodeID = 0;

$| = 1;

sub clear_screen {
    system $^O eq 'MSWin32' ? 'cls' : 'clear';
    print("[ FLOWSTATE ]\n");
}

sub get_char {
    ReadMode("cbreak");
    my $key = ReadKey(0, *TTY);
    ReadMode("normal");
    return $key;
}

sub new_node ($) {
    my ($label) = @_;

    my $n = $g->add_node($nodeID);
    $n->set_attribute('label', $label);
    $nodeID+=1;

    return $n;
}

clear_screen();

my $selected;
my $selectMode = 0;

while (1) {

    #print(">");
    if ($selectMode == 1) {
        printf("\nLink Mode...");
    }

    my $cmd = get_char();


    if (ord($cmd) == 13) { # enter key
        if ($selectMode == 1 && defined $selected) {
            $g->add_edge($selected, $active); 
        }
        $selectMode = 0;

    } elsif ($cmd eq 'n') {
        printf("\nNode Label >");
        my $label = <STDIN>;
        $newActive = new_node($label);
    } elsif( $cmd eq 'c') {
        if (defined $active) {
            printf("\nChild Node Label >");
            my $label = <STDIN>;
            $newActive = new_node($label);
            $g->add_edge($active, $newActive);
        }
    } elsif( $cmd eq 'p') {
        if (defined $active) {
            printf("\nParent Node Label >");
            my $label = <STDIN>;
            $newActive = new_node($label);
            $g->add_edge($newActive, $active);
        }
    } elsif( $cmd eq 'd') {
        if (defined $active) {
            printf("\nDecision Branch Label >");
            my $branch = <STDIN>;
            printf("\nNew Node Label >");
            my $label = <STDIN>;
            $newActive = new_node($label);
            my $edge = $g->add_edge($active, $newActive);
            $edge->set_attribute('label',$branch);
        }

    } elsif ( $cmd eq 's') { 
        $selectMode = 1;
        $selected = $active;

    } elsif ($cmd eq 'r') {
        if (defined $active) {
            printf("\nRename >");
            my $label = <STDIN>;
            $active->set_attribute('label', "*" . $label); # a little jank, but have to put the "*" in since its the active node
        }

    } elsif ($cmd eq 'x') {
        if (defined $active) {
            printf("\nReally Delete? ");
            my $confirm = <STDIN>;
            if ($confirm =~ '^y' || $confirm =~ '^d') {
                $g->del_node($active);
                $newActive = $g->root_node();
            }
        }

    } elsif ($cmd eq 'u') {
        if (defined $active) {
            printf("\nReally Unlink? ");
            my $confirm = <STDIN>;
            if ($confirm =~ '^y' || $confirm =~ '^d') {
                foreach my $e ($active->edges()) {
                    $g->del_edge($e);
                    $newActive = $active; # idk this seems to refresh the tree
                }
            }
        }
    } elsif ($cmd eq 'h') {
        if (not defined $active) { next };
        my @nodes = $g->nodes();

        my ($x, $y) = $active->pos();
        my $minDist;
        foreach my $n (@nodes) {
            if (($n->y() == $y) && ($n->x() < $x)) {
                if ((not defined $minDist) || ($x - $n->x() < $minDist)) {
                    $minDist = $x - $n->x();
                    $newActive = $n;
                }
            }
        }

    } elsif ($cmd eq 'l') {
        if (not defined $active) { next };
        my @nodes = $g->nodes();

        my ($x, $y) = $active->pos();
        my $minDist;
        foreach my $n (@nodes) {
            if (($n->y() == $y) && ($n->x() > $x)) {
                if ((not defined $minDist) || ($n->x() - $x < $minDist)) {
                    $minDist = $n->x() - $x;
                    $newActive = $n;
                }
            }
        }


    } elsif ($cmd eq 'j') {
        if (not defined $active) { next };
        my @nodes = $g->nodes();
        
        my ($x, $y) = $active->pos();
        my $minDist;
        foreach my $n (@nodes) {
            if (($n->x() == $x) && ($n->y() > $y)) {
                if ((not defined $minDist) || ($n->y() - $y < $minDist)) {
                    $minDist = $n->y() - $y;
                    $newActive = $n;
                }
            }
        }

    } elsif ($cmd eq 'k') {
        if (not defined $active) { next };
        my @nodes = $g->nodes();
        my ($x, $y) = $active->pos();
        my $minDist;
        foreach my $n (@nodes) {
            if (($n->x() == $x) && ($n->y() < $y)) {
                if ((not defined $minDist) || ($y - $n->y() < $minDist)) {
                    $minDist = $y - $n->y();
                    $newActive = $n;
                }
            }
        }
        
    } elsif ($cmd eq '?') {
        printf("\nWork in progress...\nVim Directions: Move around\nN: new independent node\nC: new child node\nP: new parent node\nX: delete node\nR: rename node\nS: select this node, next node you press <enter> on will get linked\n");
        next;
    } elsif ($cmd eq 'q') {
        exit(); 
    } else {
        print(ord($cmd));
    }

    if (defined $newActive) {
        if (defined $active) {
            $active->set_attribute('label',substr($active->get_attribute('label'),1));
            $active->set_attribute('color','black');
        }
        $newActive->set_attribute('label',"*" . $newActive->get_attribute('label'));
        $newActive->set_attribute('color','red');
        $active = $newActive;
        undef $newActive;
    }

    clear_screen();
    print($g->as_ascii());
}


