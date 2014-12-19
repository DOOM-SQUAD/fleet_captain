# FleetCaptain
## Also known as Fleet Clapton

## What is Fleet Captain

Fleet Captain is a gem for breaking your app up along service boundaries,
building individual docker containers out of those services, then deploying them
to CoreOS clusters.

## What does that mean?

Most Ruby application _really_ consist of multiple small applications, some of
which are encouraged by Rails, and some of which are not.  If your app does a lot
of asynchronous processing it probably starts resque in a different process, and
shares some data with that process to make it work.

Unfortunately, "classical" Rails and Ruby deployment techniques make this kind
of app very difficult to orchestrate.  Even if you're well along the path of a
service oriented architecture, keeping your multiple service repos all aligned
while you deploy them can be a hassle.  Fleet Captain is not a solution to that
problem, but a tool enabling you to use the solution.

## How does it work

Fleet Captain uses a `Fleetfile` which describes the systemd units that your
app can be broken up into.  If your app has multiple containers, you can manage
the deploy of one more of those containers to your cluster without needing to
think about it.  Fleet Captain has some limited capabilities to set up clusters
for you, and to set scaling rules for different parts of your application.

Systems like Elastic Beanstalk can generally scale your app along external
forces only - CPU, Network, etc and can only be reactive to reported metrics. If
you run the CEO's MegaQuery at 3:30 everyday, it's posible to set up your
application to be set to handle this ahead of time using the tools Fleet Captain
gives you.

## Example Fleetfile

Let's take the example of an application with an App Server, and
two Resque Queues (named "important" and "ongoing")

```ruby
Fleet.command do
  container 'hackuman/behavioral'

  # First object
  service :app_server do
    description "My App Service"
    
    instances 4 
    
    # implicit
    before_start :kill, :rm, :pull
    start        run: { p: '80:80' }

    start        '/usr/bin/docker run -p 80:80 -v /mount/data:/mount/data --name whatever container
    after_start  'cap fleet:available'
    before_stop  :stop
    after_stop   'cap fleet:unavailble'

    restart_time 100

    #optional

    machine_id #run on a specific machines
    machine_of #run on machines WITH listed services
    machine_metadata # run on machines with matching metadata
    conflicts # do not run with listed units
    global # run on all machines
  end

  #second
  service :important_queue do
    desc "Queue Processing Important Jobs"
    name "important_queue"

    start [:run, 'bundle exec resque QUEUE=important']
  end

  # etc.
  service :ongoing_queue do
    desc "Queue processing ongoing jobs"
    name "ongoing_queue"

    start [:run, 'bundle exec resque QUEUE=ongoing']
  end

  service :redis do
    container 'redis/server'
  end

end
```

## Deploying with Fleet

Once you have defined all of your services, you can deploy to your CoreOS
cluster using the Capistrano extensions that FleetCaptain provides.  If your
cluster is not already provisioned, you will need to do a `cap deploy:setup` to
create the stack through Cloud Formation before you can deploy to it. (NB: There
is no notification that this is complete, so you'll need to watch your AWS
console for notification that it is done.)

Afterward, you just do `cap deploy` like you always have, and FleetCaptain takes
over.

1) FleetCaptain will search your project root for a Dockerfile and compile it
into a container.

2) It will push that container to DockerHub.

3) It will parse your Fleetfile and compare services defined in that file to the
currently installed units on your cluster.  Any unit not found on the cluster
will be installed. A unit with a matching name, but a different unit file will
be updated.  If a unit is currently running on the cluster, but is not found in
your Fleetfile an error will be raised. (This behavior should be configurable.)

4) It will begin a rolling restart of your units - this works by stopping each
individual instance of a service and waiting for it to finish restarting before
restarting the next unit.  A service with a single instance cannot be "rolling
restarted."

5) As all of the services start up, they will register themselves with the etcd
cluster as available under the release's tag.  When the etcd cluster available
services list includes all of the services specified in your fleet file, the
deploy is done.

Caveats and cautions:

If your services communicate with each other over external or internal API's
that might change, it is important to retrieve the service connection
information from the etcd cluster.  FleetCaptain provides a simple interface to
the etcd cluster to retrieve this information.  Your service should register
itself with the etcd cluster as soon as it is available to service requests, and
should unregister itself before it exits.  The deploy script will do some basic
registering / deregistering of processes as the containers start, but there is
no guarantee that this will coincide with your services ability to do work.

The mechanism for this is to call:

```ruby
FleetCaptain.register('service_name', connection_hash) 
```

When your service is ready. Note that this will only allow services WITHIN the
same version to discover your deploy. You can register as compatible within
different release tags by passing them as an additional parameter.

```ruby
FleetCaptain.register('service_name', connection_hash, versions: ['v1.01',
'v1.1'])
```

This should allow you to deploy individual services to the cluster without
having to redeploy all of them.  Services which are dependent on other services
being available should use either systemd After hooks or be resilient to those
services not being available.  Some basic scripting capabilities are provided
for this.

```sh
cap fleet:ensure_available['service_name']
```

or

```ruby
FleetCaptain.ensure_available('service_name')
```

Will return a non-zero exit status if the service is NOT available.

## Running Migrations, Tasks and Consoles

# TODO

## Installation

Add this line to your application's Gemfile:

    gem 'fleet_captain'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fleet_captain

## Contributing

1. Fork it ( https://github.com/acumenbrands/fleet_captain/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
