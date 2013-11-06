# DoubleDown: A Perl based IRC Bot #

DoubleDown is a Perl based IRC bot that uses a plugin-based system.


## Installation ##

Installation of dbldown is fairly straight forward.  You will need to install carton from either [github](https://github.com/miyagawa/carton) or [cpan](http://search.cpan.org/~miyagawa/Carton-v1.0.12/lib/Carton.pm).

Once carton is installed you can install dependencies by executing the following

    carton install

## Configuration ##

There are 3 types of config files that dbldown will use.

1. Global Config   - doubledown.yml
2. Local Config    - doubledown\_local.yml
3. Runtime Config  - config/filename.yml

These files are loaded in the order listed above, and the runtime config will overwrite the local config, and the Local config will overwrite the global config

### Global Config ###
The global config (doubledown.yml) is part of the repository and will have the minimal amount of config required to run an instance of dbldown

### Local Config ###
The local config (doubledown\_local.yml) can be added to add configuration variables that will be similar across multiple instances of dbldown.  These could include message queue setups as well as database settings

### Runtime Config ###
If you run dbldown with different settings in different channels or IRC servers, it may be helpful to have different configs defined at runtime.  For instance you may have a config for work that you use.  Assuming you have a file config/work.yml thats setup like the other configs, you would use it by executing

    ./dbldown -c work

Or if you have a specific channel/server used for debuging, you might want to create a config/debug.yml and execute

    ./dbldown -c debug

## Execution ##

		./dbldown --help
    ./dbldown
    ./dbldown -c debug
