package AnyEvent::RabbitMQ::PubSub::Consumer;
use Moose;

use AnyEvent;
use Promises qw(deferred collect);

has channel => (
    is => 'ro', isa => 'AnyEvent::RabbitMQ::Channel', required => 1
);
has exchange => (
    is => 'ro', isa => 'HashRef', required => 1
);
has queue => (
    is => 'ro', isa => 'HashRef', required => 1
);
has routing_key => (
    is => 'ro', isa => 'Str', default => '#'
);

sub init {
    my ($self) = @_;

    my $cv = AnyEvent->condvar;

    $self->declare_exchange_and_queue()
        ->then(sub { $self->bind_queue() })
        ->then(sub { $cv->send() });

    $cv->recv();
    return
}

sub consume {
    my ($self, $cv, $on_consume) = @_;

    my $d = deferred();

    $self->channel->consume(
        queue      => $self->queue->{queue},
        no_ack     => 0,
        on_success => sub { $d->resolve() },
        on_cancel  => sub { $cv->croak("consume cancel: @_") },
        on_failure => sub { $cv->croak("consume failure: @_") },
        on_consume => sub { $on_consume->($self, @_) },
    );

    return $d->promise
}

sub declare_exchange_and_queue {
    my ($self, $cv) = @_;

    return collect(
        $self->declare_exchange(),
        $self->declare_queue(),
    )->then(sub {
        return @{ $_[0] }
    });
}

sub declare_queue {
    my ($self) = @_;

    my $d = deferred;
    $self->channel->declare_queue(
        %{ $self->queue },
        on_success => sub { $d->resolve() },
    );
    return $d->promise()
}

sub declare_exchange {
    my ($self) = @_;

    my $d = deferred;
    $self->channel->declare_exchange(
        %{ $self->exchange },
        on_success => sub { $d->resolve() },
    );
    return $d->promise()
}

sub bind_queue {
    my ($self) = @_;

    my $d = deferred;
    $self->channel->bind_queue(
        queue       => $self->queue->{queue},
        exchange    => $self->exchange->{exchange},
        routing_key => $self->routing_key,
        on_success  => sub { $d->resolve() },
    );
    return $d->promise()
}

1
