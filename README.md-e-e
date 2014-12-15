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
