requires 'perl', '5.010';

requires 'AnyEvent';
requires 'AnyEvent::RabbitMQ';
requires 'Promises';
requires 'Moose';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

