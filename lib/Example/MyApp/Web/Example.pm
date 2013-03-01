package Example::MyApp::Web::Example;
use Mojo::Base 'Mojolicious::Controller';
use Example::MyApp;

# This action will render a template
sub welcome {
  my $self = shift;

  my $version = $Example::MyApp::VERSION;
  # Render template "example/welcome.html.ep" with message
  $self->render(
    message => "Welcome to the Mojolicious real-time web framework! (Example::MyApp $version)");
}

1;
